param(
  [string]$Path = "lib/l10n/app_fr.arb",
  [string]$Lang = "fr"
)
$ErrorActionPreference = "Stop"
function Ensure-Metadata([object]$obj, [string]$lang) {
  $props = $obj.PSObject.Properties
  foreach ($p in $props) {
    $name = $p.Name
    if ($name.StartsWith("@")) { continue }
    $metaName = "@$name"
    $hasMeta = $props.Name -contains $metaName
    if (-not $hasMeta) {
      $desc = if ($lang -eq "fr") { "Description pour la clé '$name'" } else { "Description for key '$name'" }
      $meta = [PSCustomObject]@{ description = $desc }
      $obj | Add-Member -NotePropertyName $metaName -NotePropertyValue $meta -Force
    }
  }
  return $obj
}
$raw = Get-Content $Path -Raw
$json = $raw | ConvertFrom-Json
$fixed = Ensure-Metadata -obj $json -lang $Lang
$out = $fixed | ConvertTo-Json -Depth 20
Set-Content -Path $Path -Value $out
Write-Host "Metadata ensured for $Path ($Lang)"
