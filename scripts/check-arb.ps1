param(
  [string]$EnPath = "lib/l10n/app_en.arb",
  [string]$FrPath = "lib/l10n/app_fr.arb"
)
$ErrorActionPreference = "Stop"
function Get-Duplicates([string]$path) {
  $lines = Get-Content $path
  $keys = @()
  $depth = 0
  foreach ($l in $lines) {
    $depthBefore = $depth
    if ($depthBefore -eq 1 -and ($l -match '^\s*"(?!@)([^"]+)"\s*:\s*"')) {
      $keys += $matches[1]
    }
    $depth += ([regex]::Matches($l,'\{').Count - [regex]::Matches($l,'\}').Count)
  }
  $keys | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object Name, Count
}
function Get-PlaceholderIssues([string]$path) {
  $raw = Get-Content $path -Raw
  $json = $raw | ConvertFrom-Json
  $props = $json.PSObject.Properties
  $issues = @()
  foreach ($p in $props) {
    $name = $p.Name
    if ($name.StartsWith("@")) { continue }
    $val = $p.Value
    if ($val -is [string]) {
      $vars = [regex]::Matches($val, '\{(\w+)\}') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
      if ($vars.Count -gt 0) {
        $metaProp = $props | Where-Object { $_.Name -eq "@$name" }
        $hasMeta = $metaProp -ne $null
        $missing = @()
        if ($hasMeta) {
          $placeholders = $metaProp.Value.placeholders
          foreach ($v in $vars) {
            if (-not ($placeholders.PSObject.Properties.Name -contains $v)) { $missing += $v }
          }
        }
        if (-not $hasMeta -or $missing.Count -gt 0) {
          $issues += [pscustomobject]@{
            key     = $name
            meta    = $hasMeta
            missing = ($missing -join ",")
          }
        }
      }
    }
  }
  $issues
}
function Get-MissingMetadata([string]$path) {
  $raw = Get-Content $path -Raw
  $json = $raw | ConvertFrom-Json
  $props = $json.PSObject.Properties
  $missing = @()
  foreach ($p in $props) {
    $name = $p.Name
    if ($name.StartsWith('@')) { continue }
    if (-not ($props.Name -contains "@$name")) { $missing += $name }
  }
  $missing
}
Write-Host "== Duplicates (EN) =="
$dupEn = Get-Duplicates $EnPath
if ($dupEn) { $dupEn | Format-Table -AutoSize } else { Write-Host "None" }
Write-Host "== Duplicates (FR) =="
$dupFr = Get-Duplicates $FrPath
if ($dupFr) { $dupFr | Format-Table -AutoSize } else { Write-Host "None" }
Write-Host "== Placeholder Issues (EN) =="
$phEn = Get-PlaceholderIssues $EnPath
if ($phEn) { $phEn | Format-Table -AutoSize } else { Write-Host "None" }
Write-Host "== Placeholder Issues (FR) =="
$phFr = Get-PlaceholderIssues $FrPath
if ($phFr) { $phFr | Format-Table -AutoSize } else { Write-Host "None" }
Write-Host "== Missing Metadata (EN) =="
$mmEn = Get-MissingMetadata $EnPath
if ($mmEn -and $mmEn.Count -gt 0) { $mmEn | ForEach-Object { Write-Host $_ } } else { Write-Host "None" }
Write-Host "== Missing Metadata (FR) =="
$mmFr = Get-MissingMetadata $FrPath
if ($mmFr -and $mmFr.Count -gt 0) { $mmFr | ForEach-Object { Write-Host $_ } } else { Write-Host "None" }
if ($dupEn -or $dupFr -or $phEn -or $phFr -or ($mmEn -and $mmEn.Count -gt 0) -or ($mmFr -and $mmFr.Count -gt 0)) { exit 1 } else { exit 0 }
