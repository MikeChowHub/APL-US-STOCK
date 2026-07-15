[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $ProjectRoot 'tools\production_archive_common.ps1')

$results = New-Object System.Collections.Generic.List[object]
function Assert-Case([string]$Name, [bool]$Passed, [string]$Detail = '') {
  $results.Add([pscustomobject]@{ Name=$Name; Passed=$Passed; Detail=$Detail })
  if (-not $Passed) { throw "$Name failed: $Detail" }
}

$objectList = New-Object System.Collections.Generic.List[object]
[object[]]$zero = @(ConvertTo-AplArchiveObjectArray $objectList)
Assert-Case 'zero-findings' ($zero -is [object[]] -and $zero.Count -eq 0) ("type={0};count={1};isObjectArray={2}" -f $zero.GetType().FullName,$zero.Count,($zero -is [object[]]))

$objectList.Add([pscustomobject]@{ Id='one'; Status='PASS'; Files=[object[]]@() })
[object[]]$one = @(ConvertTo-AplArchiveObjectArray $objectList)
Assert-Case 'one-finding' ($one -is [object[]] -and $one.Count -eq 1 -and $one[0].Id -eq 'one') $one.GetType().FullName

$objectList.Add([pscustomobject]@{ Id='two'; Status='FAIL'; Files=[object[]]@() })
[object[]]$many = @(ConvertTo-AplArchiveObjectArray $objectList)
Assert-Case 'multiple-findings' ($many -is [object[]] -and $many.Count -eq 2) $many.GetType().FullName

$stringList = New-Object System.Collections.Generic.List[string]
$stringList.Add('a'); $stringList.Add('b')
[object[]]$strings = @(ConvertTo-AplArchiveObjectArray $stringList)
Assert-Case 'generic-list-string' ($strings -is [object[]] -and $strings.Count -eq 2 -and $strings[1] -eq 'b') $strings.GetType().FullName

$sourceArray = [object[]]@([pscustomobject]@{ Value=1 }, [pscustomobject]@{ Value=2 })
[object[]]$objectArray = @(ConvertTo-AplArchiveObjectArray $sourceArray)
Assert-Case 'object-array' ($objectArray -is [object[]] -and $objectArray.Count -eq 2) $objectArray.GetType().FullName

$scalar = [pscustomobject]@{ Value=7 }
[object[]]$scalarArray = @(ConvertTo-AplArchiveObjectArray $scalar)
Assert-Case 'pscustomobject-scalar' ($scalarArray -is [object[]] -and $scalarArray.Count -eq 1 -and $scalarArray[0].Value -eq 7) $scalarArray.GetType().FullName

$auditFixture = [ordered]@{
  SchemaVersion = $script:AplFinalAuditSchemaVersion
  Status = 'FAIL'
  Required = [object[]]$many
  Optional = [object[]]@()
  UnclassifiedArtifacts = [string[]]@('one.txt')
  Errors = [object[]]@([pscustomobject]@{ Code='TEST'; Message='fixture' })
}
$roundTrip = $auditFixture | ConvertTo-Json -Depth 8 | ConvertFrom-Json
Assert-Case 'json-round-trip-required' (@($roundTrip.Required).Count -eq 2) ([string]$roundTrip.Required.GetType().FullName)
Assert-Case 'json-round-trip-errors' (@($roundTrip.Errors).Count -eq 1 -and $roundTrip.Errors[0].Code -eq 'TEST') ([string]$roundTrip.Errors.GetType().FullName)

$summary = [pscustomobject]@{ Passed=$true; Total=$results.Count; Results=[object[]]$results.ToArray() }
$summary | ConvertTo-Json -Depth 8
