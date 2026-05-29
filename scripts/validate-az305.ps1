[CmdletBinding()]
param(
  [string] $BicepPath = "az"
)

$ErrorActionPreference = "Stop"

function Invoke-BicepBuild {
  param(
    [Parameter(Mandatory = $true)]
    [string] $FilePath,

    [switch] $ParametersFile
  )

  if ($BicepPath -eq "az" -or (Split-Path -Leaf $BicepPath) -in @("az", "az.cmd", "az.exe")) {
    if ($ParametersFile) {
      & $BicepPath bicep build-params --file $FilePath
    } else {
      & $BicepPath bicep build --file $FilePath
    }
  } else {
    if ($ParametersFile) {
      & $BicepPath build-params $FilePath
    } else {
      & $BicepPath build $FilePath
    }
  }
}

$templates = Get-ChildItem -Path . -Recurse -Filter *.bicep
foreach ($template in $templates) {
  Write-Host "Building $($template.FullName)"
  Invoke-BicepBuild -FilePath $template.FullName
}

$parameterFiles = Get-ChildItem -Path .\params -Recurse -Filter *.bicepparam -ErrorAction SilentlyContinue
foreach ($parameterFile in $parameterFiles) {
  Write-Host "Building parameters $($parameterFile.FullName)"
  Invoke-BicepBuild -FilePath $parameterFile.FullName -ParametersFile
}

$errors = @()
Get-ChildItem -Path .\scripts -Filter *.ps1 | ForEach-Object {
  $tokens = $null
  $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref] $tokens, [ref] $parseErrors) > $null
  if ($parseErrors) {
    $errors += $parseErrors
    Write-Error "PowerShell parse error in $($_.Name)"
    $parseErrors | Format-List
  }
}

if ($errors.Count -gt 0) {
  exit 1
}

Write-Host "AZ-305 local validation passed."
