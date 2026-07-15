$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $projectRoot 'tools\table_card_bookkeeping.ps1')

function Assert-True([bool]$Condition,[string]$Name) { if (-not $Condition) { throw $Name }; [pscustomobject]@{ Test=$Name; Status='PASS' } }
function New-Fixture([string]$Type,[int]$Index) {
  [pscustomobject]@{ CardType=$Type; InputPath="input-$Index.json"; InputSha256=('A' * 64); OutputName="card-$Index.png"; Required=$true; Status='PASS'; OutputPath="output-$Index.png"; LogPath="output-$Index.log"; Bytes=[long](100+$Index); Sha256=('B' * 64); LogBytes=[long](10+$Index); LogSha256=('C' * 64); Error=$null }
}

$results = New-Object System.Collections.Generic.List[object]
$zero = ConvertTo-AplObjectArray $results
Assert-True ($zero -is [object[]] -and $zero.Count -eq 0) 'zero results remains object[]'
$zeroJson = [pscustomobject]@{ Cards=$zero } | ConvertTo-Json -Depth 8
Assert-True (@(($zeroJson | ConvertFrom-Json).Cards).Count -eq 0) 'zero-card manifest serialization'

$one = New-Fixture 'ExecutiveSummary' 1
Add-AplTableCardResult $results $one
$oneArray = ConvertTo-AplObjectArray $results
Assert-True ($oneArray -is [object[]] -and $oneArray.Count -eq 1) 'one result remains object[]'
Assert-True ($oneArray[0].GetType().FullName -eq 'System.Management.Automation.PSCustomObject') 'single result is PSCustomObject'
$oneJson = [pscustomobject]@{ Cards=$oneArray } | ConvertTo-Json -Depth 8
Assert-True (@(($oneJson | ConvertFrom-Json).Cards).Count -eq 1) 'one-card manifest serialization'

foreach ($pair in @(@('TopLeaders',2),@('TopGainers',3),@('SectorStructure',4))) { Add-AplTableCardResult $results (New-Fixture $pair[0] $pair[1]) }
$four = ConvertTo-AplObjectArray $results
Assert-True ($four.Count -eq 4) 'four results remain object[]'
Assert-True ((ConvertTo-AplObjectArray $one).Count -eq 1) 'scalar PSCustomObject normalization'
Assert-True ((ConvertTo-AplObjectArray ([object[]]$four)).Count -eq 4) 'object[] normalization'
Assert-True ((ConvertTo-AplObjectArray $results).Count -eq 4) 'Generic List normalization'

$json = [pscustomobject]@{ Cards=$four } | ConvertTo-Json -Depth 8
$roundTrip = $json | ConvertFrom-Json
Assert-True (@($roundTrip.Cards).Count -eq 4) 'four-card manifest JSON round-trip'

$manifestPath = Join-Path $projectRoot 'work\production-inputs\2026-07-14\table-card-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$stagingResults = New-Object System.Collections.Generic.List[object]
$index = 0
foreach ($card in @($manifest.Cards)) {
  $index++
  $inputPath = Join-Path (Split-Path $manifestPath -Parent) ([string]$card.InputPath)
  $fixture = [pscustomobject]@{ CardType=$card.CardType; InputPath=$inputPath; InputSha256=(Get-FileHash $inputPath -Algorithm SHA256).Hash; OutputName=$card.OutputName; Required=$card.Required; Status='PASS'; OutputPath=$card.OutputName; LogPath=([IO.Path]::ChangeExtension([string]$card.OutputName,'.table-card-log.txt')); Bytes=[long]1; Sha256=('D'*64); LogBytes=[long]1; LogSha256=('E'*64); Error=$null }
  Add-AplTableCardResult $stagingResults $fixture
  if ($index -eq 1 -or $index -eq 2 -or $index -eq 4) { Assert-True ((ConvertTo-AplObjectArray $stagingResults).Count -eq $index) "staging fixture registers $index card(s)" }
}
