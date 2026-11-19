#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Shared helpers for MediaElch's Windows test scripts.

.DESCRIPTION
    Dot-source this file from a test script after its param() block:

        . "$PSScriptRoot/test_utils.ps1"
        Initialize-MediaElchTestEnvironment -BuildDir $BuildDir
#>

function Initialize-MediaElchTestEnvironment {
    <#
    .SYNOPSIS
        Prepare the environment required to run MediaElch test binaries.
    #>
    [CmdletBinding()]
    param(
        [string]$BuildDir = "build"
    )

    # QuaZip and vcpkg's zlib are shared libraries, so their directories must be
    # on PATH. The paths are harmless if QuaZip is linked statically.
    $vcpkgRoot = $env:VCPKG_INSTALLATION_ROOT
    if (-not $vcpkgRoot) { $vcpkgRoot = "C:/vcpkg" }
    $quazipDir = Join-Path $BuildDir "third_party/quazip/quazip"
    $env:PATH = "$quazipDir;$vcpkgRoot/installed/x64-windows/bin;$env:PATH"

    # The tests create a QApplication. On CI runners without an interactive
    # desktop the offscreen plugin is the most reliable choice.
    if (-not $env:QT_QPA_PLATFORM) {
        $env:QT_QPA_PLATFORM = "offscreen"
    }
}

function Get-MediaElchTestExecutable {
    <#
    .SYNOPSIS
        Resolve a test executable and fail with a helpful message if missing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Test executable not found: $Path. Build the test target first."
    }
    return (Resolve-Path $Path).Path
}
