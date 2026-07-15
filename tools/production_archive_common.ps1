$script:AplArchiveManifestSchemaVersion = 'APL Daily Archive Manifest v2.0'
$script:AplFinalAuditSchemaVersion = 'APL Final Production Audit v2.0'

function ConvertTo-AplArchiveObjectArray([object]$Value) {
  $items = New-Object System.Collections.Generic.List[object]
  if ($null -ne $Value) {
    if ($Value -is [string] -or $Value -is [System.Collections.IDictionary] -or $Value.GetType() -eq [System.Management.Automation.PSCustomObject]) {
      [void]$items.Add($Value)
    } elseif ($Value -is [System.Collections.IEnumerable]) {
      foreach ($item in $Value) { [void]$items.Add($item) }
    } else {
      [void]$items.Add($Value)
    }
  }
  foreach ($item in $items.ToArray()) { Write-Output -NoEnumerate $item }
}

function Get-AplCanonicalPath([string]$Path, [string]$BasePath = '') {
  if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Path is required.' }
  if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path).TrimEnd('\') }
  if ([string]::IsNullOrWhiteSpace($BasePath)) { $BasePath = (Get-Location).Path }
  return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path)).TrimEnd('\')
}

function Test-AplPathInside([string]$Path, [string]$Parent) {
  $fullPath = Get-AplCanonicalPath $Path
  $fullParent = Get-AplCanonicalPath $Parent
  return ($fullPath.Equals($fullParent, [System.StringComparison]::OrdinalIgnoreCase) -or $fullPath.StartsWith($fullParent + '\', [System.StringComparison]::OrdinalIgnoreCase))
}

function Assert-AplNoReparsePath {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$AllowedRoot,
    [switch]$RequireExists,
    [switch]$RequireFile,
    [switch]$RequireDirectory
  )
  $full = Get-AplCanonicalPath $Path
  $root = Get-AplCanonicalPath $AllowedRoot
  if (-not (Test-AplPathInside $full $root)) { throw "Resolved path escapes allowed root '$root': $full" }
  $cursor = $full
  while (-not [string]::IsNullOrWhiteSpace($cursor)) {
    if (Test-Path -LiteralPath $cursor) {
      $item = Get-Item -LiteralPath $cursor -Force
      if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
        throw "Reparse point, SymbolicLink, Junction, or MountPoint is forbidden: $cursor"
      }
    }
    $parent = Split-Path -Parent $cursor
    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) { break }
    $cursor = $parent
  }
  if ($RequireExists -and !(Test-Path -LiteralPath $full)) { throw "Required path does not exist: $full" }
  if ($RequireFile -and !(Test-Path -LiteralPath $full -PathType Leaf)) { throw "Required file does not exist: $full" }
  if ($RequireDirectory -and !(Test-Path -LiteralPath $full -PathType Container)) { throw "Required directory does not exist: $full" }
  return $full
}

function Get-AplSafeFileList([string]$Root) {
  $rootFull = Assert-AplNoReparsePath -Path $Root -AllowedRoot $Root -RequireDirectory
  $queue = New-Object System.Collections.Generic.Queue[string]
  $queue.Enqueue($rootFull)
  $files = New-Object System.Collections.Generic.List[object]
  while ($queue.Count -gt 0) {
    $directory = $queue.Dequeue()
    foreach ($item in @(Get-ChildItem -LiteralPath $directory -Force)) {
      if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or -not [string]::IsNullOrWhiteSpace([string]$item.LinkType)) {
        throw "Reparse point, SymbolicLink, Junction, or MountPoint is forbidden: $($item.FullName)"
      }
      if ($item.PSIsContainer) { $queue.Enqueue($item.FullName) }
      else { $files.Add($item) }
    }
  }
  return $files.ToArray()
}

function Assert-AplScanDate([string]$ScanDate) {
  $parsed = [datetime]::MinValue
  $ok = [datetime]::TryParseExact($ScanDate, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)
  if (-not $ok -or $parsed.ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture) -cne $ScanDate) {
    throw "ScanDate must be a real calendar date in strict yyyy-MM-dd format: $ScanDate"
  }
  return $parsed
}

function Write-AplUtf8Atomic([string]$Path, [string]$Text, [string]$AllowedRoot) {
  $full = Assert-AplNoReparsePath -Path $Path -AllowedRoot $AllowedRoot
  $parent = Split-Path -Parent $full
  $parent = Assert-AplNoReparsePath -Path $parent -AllowedRoot $AllowedRoot -RequireDirectory
  $temporary = Join-Path $parent ('.{0}.{1}.tmp' -f (Split-Path $full -Leaf), [guid]::NewGuid().ToString('N'))
  [System.IO.File]::WriteAllText($temporary, $Text, [System.Text.Encoding]::UTF8)
  try {
    Assert-AplNoReparsePath -Path $temporary -AllowedRoot $AllowedRoot -RequireFile | Out-Null
    Move-Item -LiteralPath $temporary -Destination $full -Force
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
  }
  return $full
}

function Read-AplStrictJson([string]$Path, [string]$AllowedRoot) {
  $full = Assert-AplNoReparsePath -Path $Path -AllowedRoot $AllowedRoot -RequireFile
  try { return ([System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8) | ConvertFrom-Json) }
  catch { throw "Invalid JSON '$full': $($_.Exception.Message)" }
}

function Test-AplArchiveEligible([string]$RelativePath) {
  $normalized = $RelativePath.Replace('\','/')
  $segments = @($normalized.Split('/'))
  $excludedDirectories = @('.staging','staging','tmp','temp','temporary','cache','.cache','node_modules','typography-comparison','diagnostics','diagnostic-only')
  foreach ($segment in $segments | Select-Object -SkipLast 1) {
    if ($excludedDirectories -contains $segment.ToLowerInvariant()) { return $false }
  }
  $name = $segments[-1]
  foreach ($pattern in @('*.tmp','*.temp','*.bak','*.cache','*.partial','*.inprogress','*.lock','*.lck','*.diagnostic','~*','*FontAudit*','*Typography_Comparison*','diagnostic.*','diagnostic-*','env-test.*')) {
    if ($name -like $pattern) { return $false }
  }
  return $true
}

function Get-AplArchiveInventory([string]$Root, [switch]$ExcludeManifest) {
  $rootFull = Assert-AplNoReparsePath -Path $Root -AllowedRoot $Root -RequireDirectory
  $items = @(Get-AplSafeFileList $rootFull | ForEach-Object {
    $relative = $_.FullName.Substring($rootFull.Length + 1).Replace('\','/')
    if ((Test-AplArchiveEligible $relative) -and (-not $ExcludeManifest -or $relative -cne 'archive-manifest.json')) {
      [pscustomobject]@{
        RelativePath = $relative
        Size = [long]$_.Length
        SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        FullName = $_.FullName
      }
    }
  } | Sort-Object RelativePath)
  return $items
}

function Assert-AplInventoryMatch([object[]]$Expected, [object[]]$Actual, [string]$Context) {
  $Expected = @($Expected | Sort-Object RelativePath)
  $Actual = @($Actual | Sort-Object RelativePath)
  if ($Expected.Count -ne $Actual.Count) { throw "$Context file count mismatch. Expected=$($Expected.Count); Actual=$($Actual.Count)." }
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ([string]$Expected[$i].RelativePath -cne [string]$Actual[$i].RelativePath -or [long]$Expected[$i].Size -ne [long]$Actual[$i].Size -or [string]$Expected[$i].SHA256 -cne [string]$Actual[$i].SHA256) {
      throw "$Context path/size/SHA-256 mismatch at '$($Expected[$i].RelativePath)'."
    }
  }
}

function ConvertTo-AplManifestRecords([object[]]$Inventory) {
  $records = New-Object System.Collections.Generic.List[object]
  foreach ($item in @($Inventory | Sort-Object RelativePath)) {
    $records.Add([pscustomobject]@{ RelativePath=[string]$item.RelativePath; Size=[long]$item.Size; SHA256=[string]$item.SHA256 })
  }
  return $records.ToArray()
}

function Get-AplManifestInventory([object]$Manifest) {
  $records = @($Manifest.Files)
  if ($records.Count -eq 0) { throw 'Archive manifest Files must not be empty.' }
  $seen = @{}
  $result = New-Object System.Collections.Generic.List[object]
  foreach ($record in $records) {
    foreach ($name in @('RelativePath','Size','SHA256')) {
      if ($null -eq $record.PSObject.Properties[$name]) { throw "Archive manifest file record missing '$name'." }
    }
    $relative = [string]$record.RelativePath
    if ([string]::IsNullOrWhiteSpace($relative) -or [System.IO.Path]::IsPathRooted($relative) -or $relative.Contains('..') -or $relative.Contains('\')) { throw "Invalid archive manifest RelativePath: $relative" }
    $key = $relative.ToLowerInvariant()
    if ($seen.ContainsKey($key)) { throw "Duplicate archive manifest RelativePath: $relative" }
    $seen[$key] = $true
    if ([long]$record.Size -lt 0) { throw "Invalid archive manifest Size: $relative" }
    $sha = [string]$record.SHA256
    if ($sha -cnotmatch '^[0-9A-F]{64}$') { throw "Invalid archive manifest SHA256: $relative" }
    $result.Add([pscustomobject]@{ RelativePath=$relative; Size=[long]$record.Size; SHA256=$sha })
  }
  return [object[]]@($result.ToArray() | Sort-Object RelativePath)
}

function Assert-AplArchiveManifest {
  param(
    [object]$Manifest,
    [string]$ExpectedScanDate,
    [ValidateSet('PENDING_INDEX','PASS')][string]$ExpectedStatus,
    [object[]]$ActualInventory
  )
  Assert-AplScanDate $ExpectedScanDate | Out-Null
  foreach ($name in @('SchemaVersion','ScanDate','Status','SourceFileCount','ArchiveFileCount','TotalBytes','Files')) {
    if ($null -eq $Manifest.PSObject.Properties[$name]) { throw "Archive manifest missing '$name'." }
  }
  if ([string]$Manifest.SchemaVersion -cne $script:AplArchiveManifestSchemaVersion) { throw "Unsupported Archive manifest SchemaVersion: $($Manifest.SchemaVersion)" }
  if ([string]$Manifest.ScanDate -cne $ExpectedScanDate) { throw 'Archive manifest ScanDate mismatch.' }
  if ([string]$Manifest.Status -cne $ExpectedStatus) { throw "Archive manifest Status must be $ExpectedStatus." }
  $records = @(Get-AplManifestInventory $Manifest)
  $actual = @($ActualInventory | Sort-Object RelativePath)
  if ([int]$Manifest.SourceFileCount -ne $records.Count -or [int]$Manifest.ArchiveFileCount -ne $records.Count) { throw 'Archive manifest file counts do not match Files records.' }
  $total = [long](($records | Measure-Object Size -Sum).Sum)
  if ([long]$Manifest.TotalBytes -ne $total) { throw 'Archive manifest TotalBytes mismatch.' }
  Assert-AplInventoryMatch $records $actual 'Archive manifest versus actual archive'
  return $Manifest
}

function Get-AplArchiveIndexRow([string]$IndexPath, [string]$ScanDate, [string]$AllowedRoot) {
  $full = Assert-AplNoReparsePath -Path $IndexPath -AllowedRoot $AllowedRoot -RequireFile
  $escaped = [regex]::Escape($ScanDate)
  $rows = @([System.IO.File]::ReadAllLines($full, [System.Text.Encoding]::UTF8) | Where-Object { $_ -match "^\|\s*$escaped\s*\|" })
  if ($rows.Count -ne 1) { throw "Archive index must contain exactly one row for $ScanDate; found $($rows.Count)." }
  $cells = @($rows[0].Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
  if ($cells.Count -ne 5) { throw "Archive index row has invalid column count for $ScanDate." }
  return [pscustomobject]@{ ScanDate=$cells[0]; Status=$cells[1]; FileCount=[int]$cells[2]; TotalBytes=[long]$cells[3]; ManifestPath=$cells[4] }
}

function Assert-AplArchiveIndexRow([string]$IndexPath, [object]$Manifest, [string]$ArchiveRoot) {
  $row = Get-AplArchiveIndexRow $IndexPath ([string]$Manifest.ScanDate) $ArchiveRoot
  $expectedManifestPath = '{0}/{1}/archive-manifest.json' -f ([string]$Manifest.ScanDate).Substring(0,4), [string]$Manifest.ScanDate
  if ($row.Status -cne 'PASS' -or $row.FileCount -ne [int]$Manifest.ArchiveFileCount -or $row.TotalBytes -ne [long]$Manifest.TotalBytes -or $row.ManifestPath -cne $expectedManifestPath) {
    throw "Archive index values mismatch for $($Manifest.ScanDate)."
  }
  return $row
}
