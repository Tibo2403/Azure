[CmdletBinding()]
param(
  [string] $BicepPath = "bicep"
)

$ErrorActionPreference = "Stop"

$templates = Get-ChildItem -Path . -Recurse -Filter *.bicep
foreach ($template in $templates) {
  Write-Host "Building $($template.FullName)"
  & $BicepPath build $template.FullName
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
