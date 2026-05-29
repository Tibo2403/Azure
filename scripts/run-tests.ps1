[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name Pester)) {
  throw "Pester is required. Install with: Install-Module Pester -Scope CurrentUser"
}

$pester = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
if ($pester.Version.Major -ge 5) {
  Invoke-Pester -Path .\tests -CI
} else {
  Invoke-Pester -Script .\tests
}
