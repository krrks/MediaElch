#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run MediaElch's unit tests.

.DESCRIPTION
    Runs the Catch2 unit test binary. Without a filter, all test cases run.

.PARAMETER BuildDir
    CMake build directory. Defaults to "build".

.PARAMETER Filter
    Optional Catch2 test filter, e.g. "[scrapers][tmdb]".

.PARAMETER TestArguments
    Remaining arguments are passed to the test binary unchanged.
#>
[CmdletBinding()]
param(
    [string]$BuildDir = "build",
    [string]$Filter = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TestArguments
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/test_utils.ps1"
Initialize-MediaElchTestEnvironment -BuildDir $BuildDir

$exe = Get-MediaElchTestExecutable -Path (Join-Path $BuildDir "test/unit/mediaelch_unit_test.exe")

$arguments = @()
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $arguments += $Filter
}
if ($TestArguments) {
    $arguments += $TestArguments
}

& $exe @arguments
exit $LASTEXITCODE
