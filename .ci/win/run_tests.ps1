#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run MediaElch's test binaries on Windows.

.DESCRIPTION
    Prepares the runtime environment (QuaZip and vcpkg zlib on PATH, Qt's
    offscreen platform plugin) and runs the requested test executable.
    The script exits with the test process' exit code, so it can be used as a
    drop-in CI step.

    Call it from the repository root after building, e.g.:

        ./.ci/win/run_tests.ps1
        ./.ci/win/run_tests.ps1 -BuildDir build -Filter "[scrapers][tmdb]"

.PARAMETER BuildDir
    CMake build directory. Defaults to "build".

.PARAMETER Executable
    Test binary to run. Defaults to
    "<BuildDir>/test/unit/mediaelch_unit_test.exe".

.PARAMETER Filter
    Optional Catch2 test filter, e.g. "[scrapers][tmdb]".

.PARAMETER TestArguments
    Any remaining arguments are passed to the test binary unchanged
    (e.g. --use-colour no).
#>
[CmdletBinding()]
param(
    [string]$BuildDir = "build",
    [string]$Executable = "",
    [string]$Filter = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TestArguments
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Executable)) {
    $Executable = Join-Path $BuildDir "test/unit/mediaelch_unit_test.exe"
}
if (-not (Test-Path $Executable)) {
    throw "Test executable not found: $Executable. Build the test target first."
}

# QuaZip and vcpkg's zlib are shared libraries, so their directories must be on
# PATH. The paths are harmless if QuaZip is linked statically or built elsewhere.
$vcpkgRoot = $env:VCPKG_INSTALLATION_ROOT
if (-not $vcpkgRoot) { $vcpkgRoot = "C:/vcpkg" }
$quazipDir = Join-Path $BuildDir "third_party/quazip/quazip"
$env:PATH = "$quazipDir;$vcpkgRoot/installed/x64-windows/bin;$env:PATH"

# The tests create a QApplication. On CI runners without an interactive
# desktop the offscreen plugin is the most reliable choice.
if (-not $env:QT_QPA_PLATFORM) {
    $env:QT_QPA_PLATFORM = "offscreen"
}

$arguments = @()
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $arguments += $Filter
}
if ($TestArguments) {
    $arguments += $TestArguments
}

$logFile = Join-Path $BuildDir "test-output.txt"
$testPath = (Resolve-Path $Executable).Path
Write-Host "Running $testPath $($arguments -join ' ')"

& $testPath @arguments *> $logFile
$exitCode = $LASTEXITCODE
if ($null -eq $exitCode) { $exitCode = 1 }

if (Test-Path $logFile) {
    Get-Content $logFile
}
Write-Host "Test exit code: $exitCode"
exit $exitCode
