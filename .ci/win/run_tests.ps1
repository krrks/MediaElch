#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run MediaElch's Windows test scripts.

.DESCRIPTION
    Without -Config, every "*.test.ps1" script in .ci/win/tests is executed in
    lexicographic order (use numeric prefixes such as "10-unit.test.ps1" to
    control the order).

    With -Config, only the tests listed in the JSON configuration file are
    executed, in the order given. Example:

        {
          "tests": [
            { "name": "unit", "script": "10-unit.test.ps1", "enabled": true },
            { "name": "unit-tmdb", "script": "10-unit.test.ps1",
              "args": ["-Filter", "[scrapers][tmdb]"] }
          ]
        }

    Each test script is started in its own process and receives -BuildDir
    followed by the optional arguments from the configuration. Its exit code
    decides whether the test passed.

.PARAMETER BuildDir
    CMake build directory that is passed on to every test script.

.PARAMETER Config
    Optional JSON file listing the tests to run. Paths inside the file are
    relative to the .ci/win/tests directory.

.PARAMETER Only
    Run only tests whose name (or script file name) matches one of these
    values, e.g. -Only unit.

.PARAMETER KeepGoing
    Continue with the remaining tests after a failure. By default the runner
    stops at the first failing test.

.OUTPUTS
    Exit code 0 if all executed tests passed, 1 otherwise.
#>
[CmdletBinding()]
param(
    [string]$BuildDir = "build",
    [string]$Config = "",
    [string[]]$Only = @(),
    [switch]$KeepGoing
)

$ErrorActionPreference = "Stop"

$testsDir = Join-Path $PSScriptRoot "tests"
$hostExe = (Get-Process -Id $PID).Path

function Get-TestNameFromPath {
    param([string]$FileName)
    return ($FileName -replace '\.test\.ps1$', '')
}

function Get-PlannedTests {
    param([string]$ConfigFile)

    if ([string]::IsNullOrWhiteSpace($ConfigFile)) {
        return Get-ChildItem -LiteralPath $testsDir -Filter "*.test.ps1" -File |
            Sort-Object Name |
            ForEach-Object {
                [pscustomobject]@{
                    Name = Get-TestNameFromPath $_.Name
                    Script = $_.FullName
                    Args = @()
                }
            }
    }

    if (-not (Test-Path $ConfigFile)) {
        throw "Test configuration not found: $ConfigFile"
    }

    $json = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
    $tests = @()
    foreach ($entry in @($json.tests)) {
        if ($null -eq $entry) { continue }
        if ($entry.PSObject.Properties.Name -contains "enabled" -and -not $entry.enabled) {
            continue
        }
        $scriptName = [string]$entry.script
        if ([string]::IsNullOrWhiteSpace($scriptName)) {
            throw "Test entry without 'script' in ${ConfigFile}: $($entry | ConvertTo-Json -Compress)"
        }
        $scriptPath = Join-Path $testsDir $scriptName
        if (-not (Test-Path $scriptPath)) {
            throw "Test script not found: $scriptPath"
        }
        $name = [string]$entry.name
        if ([string]::IsNullOrWhiteSpace($name)) {
            $name = Get-TestNameFromPath ([System.IO.Path]::GetFileName($scriptName))
        }
        $tests += [pscustomobject]@{
            Name = $name
            Script = (Resolve-Path $scriptPath).Path
            Args = @($entry.args | ForEach-Object { [string]$_ })
        }
    }
    return $tests
}

function Test-Selected {
    param($Test)

    if (-not $Only -or $Only.Count -eq 0) {
        return $true
    }
    $fileName = [System.IO.Path]::GetFileName($Test.Script)
    foreach ($selector in $Only) {
        if ($Test.Name -ieq $selector -or $fileName -ieq $selector) {
            return $true
        }
    }
    return $false
}

$planned = @(Get-PlannedTests -ConfigFile $Config | Where-Object { Test-Selected $_ })
if ($planned.Count -eq 0) {
    throw "No tests selected. Check $testsDir and the -Only/-Config arguments."
}

$results = @()
foreach ($test in $planned) {
    Write-Host ""
    Write-Host "===== Running test: $($test.Name) ====="

    $childArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $test.Script, "-BuildDir", $BuildDir)
    if ($test.Args) {
        $childArgs += $test.Args
    }

    $started = Get-Date
    # Windows PowerShell turns redirected stderr of native commands into error
    # records; with $ErrorActionPreference = "Stop" that would abort the
    # runner. The child's exit code is the only failure signal we care about.
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $hostExe @childArgs 2>&1
        $exitCode = $LASTEXITCODE
    } catch {
        $output = @("$_")
        $exitCode = 1
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    $duration = (Get-Date) - $started

    if ($output) {
        $output | ForEach-Object { Write-Host "  $_" }
    }

    $passed = ($exitCode -eq 0)
    $results += [pscustomobject]@{
        Name = $test.Name
        Passed = $passed
        ExitCode = $exitCode
        Duration = $duration
    }

    if (-not $passed) {
        Write-Host "Test '$($test.Name)' FAILED with exit code $exitCode."
        if (-not $KeepGoing) {
            break
        }
    }
}

Write-Host ""
Write-Host "===== Test summary ====="
foreach ($result in $results) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    Write-Host ("  {0}  {1,-40} {2,8:N1}s" -f $status, $result.Name, $result.Duration.TotalSeconds)
}

$failed = @($results | Where-Object { -not $_.Passed }).Count
$skipped = $planned.Count - $results.Count
Write-Host ""
Write-Host ("{0} passed, {1} failed, {2} not run" -f ($results.Count - $failed), $failed, $skipped)

if ($failed -gt 0) {
    exit 1
}
exit 0
