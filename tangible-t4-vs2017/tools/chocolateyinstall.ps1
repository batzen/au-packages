﻿$ErrorActionPreference = 'Stop';

$packageName  = 'tangible-t4-vs2017'
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

# Import private function from chocolatey-visualstudio.extension
Import-Module $Env:ChocolateyInstall\extensions\chocolatey-visualstudio\*.psm1

$cmd = Get-Command -Name "Install-VisualStudio"
$extensionPath = $cmd.Module.ModuleBase

# From https://stackoverflow.com/a/5652674/25702
Function Test-RegistryValue {
  param(
      [Alias("PSPath")]
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [String]$Path
      ,
      [Parameter(Position = 1, Mandatory = $true)]
      [String]$Name
      ,
      [Switch]$PassThru
  ) 

  process {
      if (Test-Path $Path) {
          $Key = Get-Item -LiteralPath $Path
          if ($Key.GetValue($Name, $null) -ne $null) {
              if ($PassThru) {
                  Get-ItemProperty $Path $Name
              } else {
                  $true
              }
          } else {
              $false
          }
      } else {
          $false
      }
  }
}

. ("$extensionPath\Get-WillowInstalledProducts.ps1")

# Package cache may have been moved, so check registry - https://blogs.msdn.microsoft.com/heaths/2017/04/17/moving-or-disabling-the-package-cache-for-visual-studio-2017/
$cachePath = (Test-RegistryValue HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Setup -Name CachePath -PassThru),
  (Test-RegistryValue HKLM:\SOFTWARE\Microsoft\VisualStudio\Setup -Name CachePath -PassThru),
  (Test-RegistryValue HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\Setup -Name CachePath -PassThru) | Select-Object -First 1

$basePath = if ($cachePath) { [IO.Path]::Combine($cachePath.CachePath, "_Instances") } else { "$Env:ProgramData\Microsoft\VisualStudio\Packages\_Instances" }

if (-not (Get-WillowInstalledProducts -VisualStudioYear 2017 -BasePath $basePath)) {
    Write-Error "Visual Studio 2017 installations not found on this computer"
}

#Based on MSI
$packageArgs = @{
  packageName   = $packageName
  softwareName  = 'tangible T4 editor plus modeling tools V2 (VS2017)'
  fileType      = 'msi'
  # Note. the MSI is calling the CheckVSInstalledAction custom action during the InstallUISequence, so we can't use /qn
  # /qr shows a 'reduced' UI which is enough to allow the custom action to run, but doesn't require any user input
  # Reported via http://t4-editor.tangible-engineering.com/forum/forum.aspx?g=posts&t=1524
  silentArgs    = "/qr /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  validExitCodes= @(0, 3010, 1641)
  url           = "https://tangibleengineeringgmbh.gallerycdn.vsassets.io/extensions/tangibleengineeringgmbh/tangiblet4editor240plusmodelingtoolsforvs2017/2.4.0/1492684211000/259042/1/tangibleT4EditorPlusModellingToolsVS2017.msi"
  checksum      = '2D1C0B3FA7C35AC99A76B72585450D604C8A774CC53FB4EEF77B34373EEF4E1B'
  checksumType  = 'sha256'
  destination   = $toolsDir
}

Install-ChocolateyPackage @packageArgs