param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('Dashboard','Social','TableCard')]
  [string]$RendererType,

  [string]$InputPath = '',
  [string]$RankingCsv = '',
  [string]$SectorMapPath = '',
  [string]$ScanDate = '',
  [string]$OutputPath = '',
  [string]$Root = '',
  [switch]$RegressionTest,
  [string]$TableCardInputPath = '',
  [string]$CardType = ''
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')

function Read-Utf8Json($path) {
  if (!(Test-Path -LiteralPath $path)) { throw "JSON file not found: $path" }
  return ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)
}

function Assert-File($path, [string]$label) {
  if ([string]::IsNullOrWhiteSpace($path)) { throw "$label is required." }
  if (!(Test-Path -LiteralPath $path)) { throw "$label not found: $path" }
}

function Validate-RankingCsv($path) {
  return @(Import-AplRankingCsv $path).Count
}

function Validate-SectorMap($path) {
  Assert-File $path 'SectorMapPath'
  $json = Read-Utf8Json $path
  if ($null -eq $json.Symbols) { throw "Sector map missing Symbols: $path" }
  $count = @($json.Symbols.PSObject.Properties).Count
  if ($count -eq 0) { throw "Sector map Symbols is empty: $path" }
  return [pscustomobject]@{
    SchemaVersion = if ($null -ne $json.SchemaVersion) { [string]$json.SchemaVersion } else { 'not provided' }
    SymbolCount = $count
  }
}

function Validate-TableCardInput($path, [string]$expectedCardType) {
  Assert-File $path 'TableCardInputPath'
  $json = Read-Utf8Json $path
  return Assert-AplTableCardContract $json $expectedCardType
}

$result = [ordered]@{
  RendererType = $RendererType
  Status = 'PASS'
}

try {
  if ($RendererType -eq 'Dashboard' -or $RendererType -eq 'Social') {
    $resolved = Resolve-AplRendererInput -ExpectedRendererType $RendererType -BoundParameters $PSBoundParameters -InputPath $InputPath -RankingCsv $RankingCsv -ScanDate $ScanDate -SectorMapPath $SectorMapPath -OutputPath $OutputPath -Root $Root -LeaderCapacity 30 -RegressionTest:$RegressionTest
    $RankingCsv = $resolved.RankingCsv; $SectorMapPath = $resolved.SectorMapPath
    $result.RankingRows = Validate-RankingCsv $RankingCsv
    $sector = Validate-SectorMap $SectorMapPath
    $result.SectorMapSchema = $sector.SchemaVersion
    $result.SectorMapSymbols = $sector.SymbolCount
  } elseif ($RendererType -eq 'TableCard') {
    $TableCardInputPath = Assert-AplProductionPath (Get-AplFullPath $TableCardInputPath) 'TableCardInputPath' -RegressionTest:$RegressionTest
    $card = Validate-TableCardInput $TableCardInputPath $CardType
    $result.SchemaVersion = $card.SchemaVersion
    $result.CardType = $card.CardType
    $result.Rows = $card.Rows
  }
} catch {
  $result.Status = 'FAIL'
  $result.Error = $_.Exception.Message
  [pscustomobject]$result
  exit 1
}

[pscustomobject]$result
