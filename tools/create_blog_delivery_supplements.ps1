[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$HtmlSourcePath,
  [Parameter(Mandatory=$true)][string]$ScanDate,
  [Parameter(Mandatory=$true)][string]$PublicPreviewPath,
  [Parameter(Mandatory=$true)][string]$MemberSqlPath
)

$ErrorActionPreference = 'Stop'

function Write-AplUtf8Atomic([string]$Path,[string]$Content) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  if (Test-Path -LiteralPath $Path) { throw "Delivery supplement already exists: $Path" }
  # Keep the atomic sibling name short so Windows PowerShell 5.1 remains below
  # the legacy MAX_PATH boundary in deeply nested isolated Production fixtures.
  $temp = Join-Path $parent ('.apl-' + [guid]::NewGuid().ToString('N').Substring(0,8) + '.tmp')
  try {
    [IO.File]::WriteAllText($temp,$Content,(New-Object Text.UTF8Encoding($true)))
    Move-Item -LiteralPath $temp -Destination $Path
  } finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
  }
}

function Get-AplFirstClause([string]$Html) {
  if ([string]::IsNullOrWhiteSpace($Html)) { throw 'Market Context second paragraph is empty.' }
  $inTag = $false
  $inEntity = $false
  for ($i=0; $i -lt $Html.Length; $i++) {
    $char = $Html[$i]
    if ($char -eq '<') { $inTag = $true; continue }
    if ($char -eq '>') { $inTag = $false; continue }
    if ($inTag) { continue }
    if ($char -eq '&') { $inEntity = $true; continue }
    if ($inEntity) { if ($char -eq ';') { $inEntity = $false }; continue }
    $isBoundary = $char -in @([char]0x3002,[char]0xFF01,[char]0xFF1F,[char]0xFF1B,'!','?',';')
    if ($char -eq '.') {
      $previous = if ($i -gt 0) { $Html[$i-1] } else { [char]0 }
      $next = if ($i + 1 -lt $Html.Length) { $Html[$i+1] } else { [char]0 }
      $isBoundary = -not ([char]::IsDigit($previous) -and [char]::IsDigit($next))
    }
    if ($isBoundary) {
      $prefix = $Html.Substring(0,$i).TrimEnd()
      if ([string]::IsNullOrWhiteSpace($prefix)) { throw 'Market Context second paragraph has no text before its first punctuation mark.' }
      return $prefix + '...'
    }
  }
  throw 'Market Context second paragraph has no valid clause or sentence punctuation for public preview truncation.'
}

$dateValue = [datetime]::MinValue
if (-not [datetime]::TryParseExact($ScanDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$dateValue)) {
  throw 'ScanDate must use yyyy-MM-dd.'
}
if (-not (Test-Path -LiteralPath $HtmlSourcePath -PathType Leaf)) { throw "HTML source is missing: $HtmlSourcePath" }
$html = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $HtmlSourcePath),[Text.Encoding]::UTF8)
$h1 = [regex]::Match($html,'(?is)<h1>.*?</h1>')
$executive = [regex]::Match($html,'(?is)<h3>\s*Executive Summary｜執行摘要\s*</h3>(.*?)(?=<h3>)')
$market = [regex]::Match($html,'(?is)<h3>\s*Market Context｜市場背景\s*</h3>(.*?)(?=<h3>)')
if (-not $h1.Success) { throw 'HTML source is missing one h1 title.' }
if (-not $executive.Success) { throw 'HTML source is missing the Executive Summary section.' }
if (-not $market.Success) { throw 'HTML source is missing the Market Context section.' }
$marketParagraphs = @([regex]::Matches($market.Groups[1].Value,'(?is)<p>(.*?)</p>'))
if ($marketParagraphs.Count -lt 2) { throw 'Market Context must contain at least two paragraphs for public preview creation.' }
$firstMarketParagraph = $marketParagraphs[0].Value.Trim()
$secondMarketClause = Get-AplFirstClause $marketParagraphs[1].Groups[1].Value
$preview = @(
  $h1.Value.Trim(),
  '',
  '<h3>Executive Summary｜執行摘要</h3>',
  $executive.Groups[1].Value.Trim(),
  '',
  '<h3>Market Context｜市場背景</h3>',
  $firstMarketParagraph,
  "<p>$secondMarketClause</p>",
  '',
  '<div id="apl-member-content"></div>'
) -join [Environment]::NewLine

$slug = "apl-deep-scan-$ScanDate"
$sql = @(
  'INSERT INTO articles (slug, required_product, content)',
  "SELECT '$slug', 'deepscan', '<p>PASTE'",
  'WHERE NOT EXISTS (',
  "  SELECT 1 FROM articles WHERE slug = '$slug'",
  ');'
) -join [Environment]::NewLine

Write-AplUtf8Atomic $PublicPreviewPath $preview
Write-AplUtf8Atomic $MemberSqlPath $sql

[pscustomobject]@{
  Status = 'PASS'
  ScanDate = $ScanDate
  PublicPreview = $PublicPreviewPath
  MemberSql = $MemberSqlPath
  Slug = $slug
}
