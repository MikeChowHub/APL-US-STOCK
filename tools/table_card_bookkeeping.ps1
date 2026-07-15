function New-AplTableCardResult {
  param(
    [Parameter(Mandatory=$true)][object]$Source,
    [ValidateSet('PENDING','PASS','FAIL')][string]$Status='PENDING'
  )
  [pscustomobject][ordered]@{
    CardType = [string]$Source.CardType
    InputPath = [string]$Source.InputPath
    InputSha256 = if ($null -eq $Source.InputSha256) { $null } else { [string]$Source.InputSha256 }
    OutputName = [string]$Source.OutputName
    Required = [bool]$Source.Required
    Status = $Status
    OutputPath = if ($null -eq $Source.OutputPath) { $null } else { [string]$Source.OutputPath }
    LogPath = if ($null -eq $Source.LogPath) { $null } else { [string]$Source.LogPath }
    Bytes = if ($null -eq $Source.Bytes) { $null } else { [long]$Source.Bytes }
    Sha256 = if ($null -eq $Source.Sha256) { $null } else { [string]$Source.Sha256 }
    LogBytes = if ($null -eq $Source.LogBytes) { $null } else { [long]$Source.LogBytes }
    LogSha256 = if ($null -eq $Source.LogSha256) { $null } else { [string]$Source.LogSha256 }
    Error = if ($null -eq $Source.Error) { $null } else { [string]$Source.Error }
  }
}

function ConvertTo-AplObjectArray {
  param([AllowNull()][object]$InputObject)
  if ($null -eq $InputObject) { return ,([object[]]@()) }
  if ($InputObject -is [System.Collections.Generic.List[object]]) { return ,([object[]]$InputObject.ToArray()) }
  if ($InputObject -is [object[]]) { return ,([object[]]$InputObject) }
  if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($item in $InputObject) { [void]$items.Add($item) }
    return ,([object[]]$items.ToArray())
  }
  return ,([object[]]@($InputObject))
}

function Add-AplTableCardResult {
  param(
    [Parameter(Mandatory=$true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Collection,
    [Parameter(Mandatory=$true)][object]$Result
  )
  $normalized = New-AplTableCardResult -Source $Result -Status ([string]$Result.Status)
  [void]$Collection.Add($normalized)
}
