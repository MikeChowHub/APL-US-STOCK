[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$InputCsv,
  [Parameter(Mandatory=$true)][string]$ScanDate,
  [Parameter(Mandatory=$true)][string]$TableCardManifestPath,
  [Parameter(Mandatory=$true)][string]$CoverBriefPath,
  [Parameter(Mandatory=$true)][string]$CoverBackgroundPath,
  [Parameter(Mandatory=$true)][string]$PublishingArtifactsRoot,
  [switch]$RegressionTest
)
$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')

function Read-AplTradingViewCsv([string]$Path) {
  Add-Type -AssemblyName Microsoft.VisualBasic
  $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser -ArgumentList @($Path, [System.Text.Encoding]::UTF8, $true)
  $rows = New-Object System.Collections.Generic.List[object]
  try {
    $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(',')
    $parser.HasFieldsEnclosedInQuotes = $true
    $parser.TrimWhiteSpace = $false
    if ($parser.EndOfData) { throw 'InputCsv is empty.' }

    try { $headers = @($parser.ReadFields()) }
    catch [Microsoft.VisualBasic.FileIO.MalformedLineException] {
      throw "InputCsv header is malformed CSV: $($_.Exception.Message)"
    }
    $symbolIndexes = @(
      for ($i = 0; $i -lt $headers.Count; $i++) {
        $header = ([string]$headers[$i]).TrimStart([char]0xFEFF)
        if ($header -ceq 'Symbol') { $i }
      }
    )
    if ($symbolIndexes.Count -ne 1) { throw 'InputCsv must contain exactly one Symbol column.' }

    $rowNumber = 1
    while (-not $parser.EndOfData) {
      $rowNumber++
      try { $fields = @($parser.ReadFields()) }
      catch [Microsoft.VisualBasic.FileIO.MalformedLineException] {
        throw "InputCsv row $rowNumber is malformed CSV: $($_.Exception.Message)"
      }
      if ($fields.Count -ne $headers.Count) {
        throw "InputCsv row $rowNumber has $($fields.Count) fields; expected $($headers.Count)."
      }
      [void]$rows.Add([string[]]$fields)
    }
  } finally {
    $parser.Close()
    $parser.Dispose()
  }
  if ($rows.Count -eq 0) { throw 'InputCsv contains no data rows.' }
  return [pscustomobject]@{
    Headers = [string[]]$headers
    Rows = [object[]]$rows.ToArray()
    SymbolIndex = [int]$symbolIndexes[0]
  }
}

Assert-AplScanDate $ScanDate|Out-Null
$allowedRoot=if($RegressionTest){Join-Path $ProjectRoot 'tmp'}else{Join-Path $ProjectRoot 'work\managed-inputs'}
$InputCsv=Assert-AplNoReparsePath -Path $InputCsv -AllowedRoot $allowedRoot -RequireFile
$TableCardManifestPath=Assert-AplNoReparsePath -Path $TableCardManifestPath -AllowedRoot $allowedRoot -RequireFile
$CoverBriefPath=Assert-AplNoReparsePath -Path $CoverBriefPath -AllowedRoot $allowedRoot -RequireFile
$CoverBackgroundPath=Assert-AplNoReparsePath -Path $CoverBackgroundPath -AllowedRoot $allowedRoot -RequireFile
$PublishingArtifactsRoot=Assert-AplNoReparsePath -Path $PublishingArtifactsRoot -AllowedRoot $allowedRoot -RequireDirectory
foreach($path in @($InputCsv,$TableCardManifestPath,$CoverBriefPath,$CoverBackgroundPath,$PublishingArtifactsRoot)){if(-not(Test-AplPathInside $path (Join-Path $allowedRoot $ScanDate))){throw "Managed input must be inside the ScanDate directory: $path"}}
$csv=Read-AplTradingViewCsv $InputCsv
$manifest=Read-AplStrictJson $TableCardManifestPath $allowedRoot
if([string]$manifest.SchemaVersion-cne'APL Table Card Manifest v1.1'-or[string]$manifest.ScanDate-cne$ScanDate){throw 'Table Card manifest schema/date mismatch.'}
$requiredTypes=@('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure')
foreach($type in $requiredTypes){$records=@($manifest.Cards|Where-Object{[string]$_.CardType-eq$type-and$_.Required-eq$true});if($records.Count-ne 1){throw "Managed inputs require exactly one $type card."};$input=[string]$records[0].InputPath;$base=Split-Path $TableCardManifestPath -Parent;$path=if([IO.Path]::IsPathRooted($input)){$input}else{Join-Path $base $input};$path=Assert-AplNoReparsePath -Path $path -AllowedRoot $allowedRoot -RequireFile;$json=Read-AplStrictJson $path $allowedRoot;[void](Assert-AplTableCardContract $json $type)}
$brief=Read-AplStrictJson $CoverBriefPath $allowedRoot
foreach($name in @('version','scanDate','composition','imageGenerationBrief','overlay')){if($null-eq$brief.PSObject.Properties[$name]){throw "Cover brief missing $name."}}
if([string]$brief.version-cne'APL Cover Brief v1.0'-or[string]$brief.scanDate-cne$ScanDate){throw 'Cover brief schema/date mismatch.'}
Add-Type -AssemblyName System.Drawing;$image=$null;try{$image=[Drawing.Image]::FromFile($CoverBackgroundPath);if($image.Width-lt 600-or$image.Height-lt 720){throw 'Cover background is too small.'}}finally{if($image){$image.Dispose()}}
$requiredPublishing=@(
  "production-package\WhatsApp_${ScanDate}.md",
  "production-package\APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.md",
  "production-package\APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.html",
  "production-package\table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_${ScanDate}.md"
)
foreach($relative in $requiredPublishing){$path=Assert-AplNoReparsePath -Path (Join-Path $PublishingArtifactsRoot $relative) -AllowedRoot $PublishingArtifactsRoot -RequireFile;if((Get-Item $path).Length-le 0){throw "Managed publishing artifact is empty: $relative"}}
[pscustomobject]@{Status='MANAGED INPUT PREFLIGHT PASS';ScanDate=$ScanDate;InputRows=$csv.Rows.Count;RequiredTableCards=4;PublishingArtifacts=$requiredPublishing.Count;ProductionStarted=$false}
