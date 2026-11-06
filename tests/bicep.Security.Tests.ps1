Describe "Bicep security and structure hygiene" {
  BeforeAll {
    $script:bicepFiles = Get-ChildItem -Path . -Recurse -Filter *.bicep -File |
      Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules)[\\/]' }
    $script:paramFiles = Get-ChildItem -Path ./params -Filter *.bicepparam -File
  }

  It "marks every password, secret or key string parameter as @secure()" {
    $offenders = @()
    foreach ($file in $script:bicepFiles) {
      $lines = Get-Content -LiteralPath $file.FullName
      for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*param\s+(\w*(password|secret|apikey|accesskey|connectionstring)\w*)\s+string' ) {
          $start = [Math]::Max(0, $i - 4)
          $decorators = ($lines[$start..($i - 1)] -join "`n")
          if ($decorators -notmatch '@secure\(\)') {
            $offenders += "$($file.Name): $($Matches[1])"
          }
        }
      }
    }
    if ($offenders.Count -gt 0) { throw "Parameters missing @secure(): $($offenders -join ', ')" }
  }

  It "never hardcodes secret values in .bicepparam files" {
    $offenders = @()
    foreach ($file in $script:paramFiles) {
      foreach ($line in Get-Content -LiteralPath $file.FullName) {
        if ($line -match "^\s*param\s+(\w*(password|secret|apikey|accesskey)\w*)\s*=\s*'([^']+)'") {
          $offenders += "$($file.Name): $($Matches[1])"
        }
      }
    }
    if ($offenders.Count -gt 0) { throw "Hardcoded secrets in parameter files: $($offenders -join ', '). Use readEnvironmentVariable() or Key Vault references." }
  }

  It "only references local modules that exist" {
    $missing = @()
    foreach ($file in $script:bicepFiles) {
      $content = Get-Content -LiteralPath $file.FullName -Raw
      foreach ($match in [regex]::Matches($content, "module\s+\w+\s+'(\.{1,2}/[^']+\.bicep)'")) {
        $target = Join-Path $file.DirectoryName $match.Groups[1].Value
        if (-not (Test-Path -LiteralPath $target)) { $missing += "$($file.Name) -> $($match.Groups[1].Value)" }
      }
    }
    if ($missing.Count -gt 0) { throw "Missing module files: $($missing -join ', ')" }
  }

  It "points every .bicepparam file at an existing template" {
    $missing = @()
    foreach ($file in $script:paramFiles) {
      $content = Get-Content -LiteralPath $file.FullName -Raw
      if ($content -match "using\s+'([^']+\.bicep)'") {
        $target = Join-Path $file.DirectoryName $Matches[1]
        if (-not (Test-Path -LiteralPath $target)) { $missing += "$($file.Name) -> $($Matches[1])" }
      } else {
        $missing += "$($file.Name) has no using statement"
      }
    }
    if ($missing.Count -gt 0) { throw "Invalid parameter files: $($missing -join ', ')" }
  }
}
