$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\dashboard_svg_geometry.ps1')

function Assert-Throws([scriptblock]$Action, [string]$Name) {
  try { & $Action } catch { return [pscustomobject]@{ Test=$Name; Status='PASS'; Detail=$_.Exception.Message } }
  throw "$Name expected a validation failure."
}
function Assert-Equal([object]$Actual, [object]$Expected, [string]$Name) {
  if ($Actual -ne $Expected) { throw "$Name expected $Expected but got $Actual." }
  return [pscustomobject]@{ Test=$Name; Status='PASS'; Detail=$Actual }
}

$results = @()
$results += Assert-Equal (Get-AplValidatedDistributionWidth 0 30 186 'Buyability distribution') 0 'valid zero-width buyability item'
$results += Assert-Equal (Get-AplValidatedDistributionWidth 30 30 186 'Buyability distribution') 186 'maximum buyability width'
$results += Assert-Equal (Get-AplValidatedDistributionWidth 5 5 126 'Sector distribution') 126 'maximum sector width'
$results += Assert-Throws { Get-AplValidatedDistributionWidth 'NaN' 30 186 'Buyability distribution' } 'pct NaN'
$results += Assert-Throws { Get-AplValidatedDistributionWidth -1 30 186 'Buyability distribution' } 'pct negative'
$results += Assert-Throws { Get-AplValidatedDistributionWidth 31 30 186 'Buyability distribution' } 'pct above 100'
$results += Assert-Throws { Get-AplValidatedDistributionWidth 1 0 126 'Sector distribution' } 'maxSectorCount zero'
$results += Assert-Throws { Get-AplValidatedDistributionWidth -1 5 126 'Sector distribution' } 'sector count negative'
$results += Assert-Throws { Get-AplValidatedDistributionWidth 6 5 126 'Sector distribution' } 'width above sector maximum'
$results
