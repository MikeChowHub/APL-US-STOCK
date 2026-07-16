[CmdletBinding()]
param(
  [string]$ExpectedRemoteUrl = 'https://github.com/MikeChowHub/APL-US-STOCK.git',
  [switch]$FullRegression
)

$ErrorActionPreference = 'Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$failures=New-Object System.Collections.Generic.List[string]
function Fail([string]$Message){$failures.Add($Message);Write-Host "FAIL $Message" -ForegroundColor Red}
function Pass([string]$Message){Write-Host "PASS $Message"}
function Invoke-Test([string]$Name,[string]$Path){$output=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Path 2>&1);if($LASTEXITCODE-ne 0){Fail "$Name :: $($output -join ' ')"}else{Pass $Name}}

$required=@(
  '.gitattributes','.gitignore','AGENTS.md','README.md','APL_US_Stock_Production_Workflow_Specification_v1.0.md',
  'Assets/Brand/APL_Deep_Scan_Brand_Logo_Renderer_Clean.png','Assets/Brand/brand-manifest.json',
  'Assets/Fonts/AlibabaSansHK/AlibabaSansHK-45.ttf','Assets/Fonts/AlibabaSansHK/AlibabaSansHK-55.ttf','Assets/Fonts/AlibabaSansHK/AlibabaSansHK-75.ttf','Assets/Fonts/AlibabaSansHK/AlibabaSansHK-95.ttf',
  'Assets/Fonts/Montserrat/Montserrat-Regular.ttf','Assets/Fonts/Montserrat/Montserrat-Medium.ttf','Assets/Fonts/Montserrat/Montserrat-SemiBold.ttf','Assets/Fonts/Montserrat/Montserrat-Bold.ttf',
  'KnowledgeBase/Rules/APL_US_Stock_Production_Artifact_Contract.json','KnowledgeBase/Rules/APL_US_Stock_Archive_Rules.md','KnowledgeBase/Rules/APL_US_Stock_Production_Package_Rules.md','KnowledgeBase/Templates/Table_Card_Input_Contract.md',
  'docs/ARCHIVE_INDEX_POLICY.md','docs/FINAL_PRODUCTION_AUDIT_CHECKLIST.md','docs/PRODUCTION_RUNBOOK.md',
  'tools/process_apl_momentum_leaders.ps1','tools/run_daily_production.ps1','tools/validate_managed_inputs.ps1','tools/test_production_artifact_contract.ps1','tools/archive_daily_production.ps1','tools/complete_daily_production.ps1','tools/production_archive_common.ps1',
  'tools/render_blog_table_cards.ps1','tools/validate_renderer_inputs.ps1','tools/render_deep_scan_dashboard_svg.ps1','tools/render_deep_scan_social_card_svg.ps1','tools/render_blog_cover_overlay.ps1','tools/convert_svg_to_png.ps1',
  'tools/repository_font_loader.ps1','tools/font-manifest.json','tools/table_card_input.schema.json','tools/table_card_manifest.schema.json','tools/production_package_manifest.schema.json','tools/archive_manifest.schema.json','tools/archive-v2-policy.json','tools/archive-v2-policy.schema.json',
  'tools/renderers/resvg/resvg.exe','tools/renderers/resvg/renderer-manifest.json','tools/renderers/resvg/README.md','tools/renderers/resvg/THIRD_PARTY_NOTICES.md',
  'tools/validate_cross_pc_environment.ps1','tools/tests/test_table_card_semantic_contract.ps1','tools/tests/test_archive_workflow_v2.ps1','tools/tests/test_cross_pc_renderer_smoke.ps1'
)
try{$gitRoot=(& git -C $ProjectRoot rev-parse --show-toplevel 2>$null);if($LASTEXITCODE-ne 0-or[IO.Path]::GetFullPath([string]$gitRoot)-ne$ProjectRoot){throw 'Git root mismatch.'};Pass 'Git root'}catch{Fail $_.Exception.Message}
$branch=(& git -C $ProjectRoot branch --show-current);if($branch-cne'main'){Fail "Branch must be main; actual=$branch"}else{Pass 'Branch main'}
$remote=(& git -C $ProjectRoot remote get-url origin 2>$null);if($LASTEXITCODE-ne 0-or[string]$remote-cne$ExpectedRemoteUrl){Fail "origin URL mismatch; actual=$remote"}else{Pass 'origin URL'}
$version=$PSVersionTable.PSVersion;if($version.Major-ne 5-or$version.Minor-ne 1){Fail "Windows PowerShell 5.1 required; actual=$version"}else{Pass 'Windows PowerShell 5.1'}

foreach($relative in $required){$full=Join-Path $ProjectRoot $relative.Replace('/','\');if(!(Test-Path -LiteralPath $full -PathType Leaf)){Fail "required file missing: $relative";continue};$tracked=@(& git -C $ProjectRoot ls-files --error-unmatch -- $relative 2>$null);if($LASTEXITCODE-ne 0-or$tracked.Count-ne 1){Fail "required file not tracked: $relative";continue};& git -C $ProjectRoot cat-file -e ("HEAD:$relative") 2>$null;if($LASTEXITCODE-ne 0){Fail "required file absent from HEAD: $relative"}}
if(@($failures|Where-Object{$_ -like 'required file*'}).Count-eq 0){Pass "required HEAD files ($($required.Count))"}

foreach($relative in @(& git -C $ProjectRoot ls-files 'tools/*.json' 'tools/**/*.json' 'KnowledgeBase/**/*.json' 'Assets/**/*.json')){try{[void]([IO.File]::ReadAllText((Join-Path $ProjectRoot $relative),[Text.Encoding]::UTF8)|ConvertFrom-Json)}catch{Fail "JSON parse: $relative :: $($_.Exception.Message)"}}
if(@($failures|Where-Object{$_ -like 'JSON parse*'}).Count-eq 0){Pass 'JSON parse'}
foreach($relative in @(& git -C $ProjectRoot ls-files 'tools/*.ps1' 'tools/**/*.ps1')){$tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile((Join-Path $ProjectRoot $relative),[ref]$tokens,[ref]$errors);if($errors.Count){Fail "PowerShell AST: $relative :: $($errors.Message -join '; ')"}}
if(@($failures|Where-Object{$_ -like 'PowerShell AST*'}).Count-eq 0){Pass 'PowerShell 5.1 AST'}

try{
  $fontManifest=Get-Content -Raw -Encoding UTF8 (Join-Path $ProjectRoot 'tools\font-manifest.json')|ConvertFrom-Json
  $fontFiles=@(Get-ChildItem (Join-Path $ProjectRoot 'Assets\Fonts') -Recurse -File|ForEach-Object{$_.FullName.Substring($ProjectRoot.Length+1).Replace('\','/')})
  $declared=@($fontManifest.Fonts|ForEach-Object{[string]$_.file})
  if(Compare-Object ($fontFiles|Sort-Object) ($declared|Sort-Object)){throw 'Font manifest does not cover every repository font exactly once.'}
  foreach($font in @($fontManifest.Fonts)){$path=Join-Path $ProjectRoot ([string]$font.file).Replace('/','\');if((Get-FileHash $path -Algorithm SHA256).Hash-cne[string]$font.sha256){throw "Font SHA mismatch: $($font.file)"}}
  . (Join-Path $ProjectRoot 'tools\repository_font_loader.ps1')
  $alibabaChineseName=(-join @([char]0x963F,[char]0x91CC,[char]0x5DF4,[char]0x5DF4,[char]0x666E,[char]0x60E0,[char]0x9AD4))
  $aliasPolicy=@{
    Regular=@('Alibaba Sans HK 55 Regular',($alibabaChineseName+' HK 55 Regular'))
    Bold=@('Alibaba Sans HK 75 SemiBold',($alibabaChineseName+' HK 75 SemiBold'))
  }
  foreach($style in @('Regular','Bold')){
    $entry=@($fontManifest.Fonts|Where-Object{[string]$_.logicalName-ceq'Alibaba Sans HK'-and[string]$_.style-ceq$style})
    if($entry.Count-ne 1){throw "Alibaba Sans HK $style manifest entry must be unique."}
    $accepted=@(Get-AplAcceptedInternalFontFamilies $entry[0])
    $expected=@($aliasPolicy[$style])
    if($accepted.Count-ne$expected.Count){throw "Alibaba Sans HK $style accepted internal family policy count mismatch."}
    $missingAliases=@($expected|Where-Object{$accepted-cnotcontains$_})
    if($missingAliases.Count-ne 0){throw "Alibaba Sans HK $style accepted internal family policy mismatch: $($missingAliases-join ', ')"}
    foreach($name in @($aliasPolicy[$style])){[void](Resolve-AplInternalFontFamily @([pscustomobject]@{Name=$name}) $entry[0] 'Alibaba Sans HK')}
    foreach($forbidden in @('Arial','Microsoft JhengHei','Microsoft JhengHei UI','Noto Sans TC','Unknown Font')){
      $rejected=$false;try{[void](Resolve-AplInternalFontFamily @([pscustomobject]@{Name=$forbidden}) $entry[0] 'Alibaba Sans HK')}catch{$rejected=$true}
      if(-not$rejected){throw "Forbidden font fallback was accepted: $forbidden"}
    }
  }
  Initialize-AplRepositoryFontRuntime;[void](Assert-AplRepositoryFontRuntime);Pass 'repository fonts, SHA, bilingual internal-family aliases and runtime'
}catch{Fail $_.Exception.Message}
try{
  $manifest=Get-Content -Raw -Encoding UTF8 (Join-Path $ProjectRoot 'tools\renderers\resvg\renderer-manifest.json')|ConvertFrom-Json;$exe=Join-Path $ProjectRoot 'tools\renderers\resvg\resvg.exe'
  if((Get-FileHash $exe -Algorithm SHA256).Hash-cne[string]$manifest.executableSha256-or(Get-Item $exe).Length-ne[long]$manifest.executableBytes){throw 'resvg hash/size mismatch.'};$actual=((& $exe --version 2>$null)-join ' ');if($actual-notmatch[regex]::Escape([string]$manifest.version)){throw "resvg version mismatch: $actual"};if([string]$manifest.policy.chromiumFallback-cne'disabled-explicit-fail'-or$manifest.policy.skipSystemFonts-ne$true){throw 'resvg browser/system-font policy mismatch.'};Pass "resvg $actual"
}catch{Fail $_.Exception.Message}
try{$brand=Get-Content -Raw -Encoding UTF8 (Join-Path $ProjectRoot 'Assets\Brand\brand-manifest.json')|ConvertFrom-Json;foreach($asset in @($brand.Assets)){$path=Join-Path $ProjectRoot ([string]$asset.File).Replace('/','\');if((Get-FileHash $path -Algorithm SHA256).Hash-cne[string]$asset.SHA256){throw "Brand asset SHA mismatch: $($asset.File)"}};Pass 'brand assets'}catch{Fail $_.Exception.Message}

$runtimeFiles=@('tools/run_daily_production.ps1','tools/renderer_production_common.ps1','tools/render_blog_table_cards.ps1','tools/render_deep_scan_dashboard_svg.ps1','tools/render_deep_scan_social_card_svg.ps1','tools/render_blog_cover_overlay.ps1','tools/convert_svg_to_png.ps1','tools/archive_daily_production.ps1','tools/test_production_artifact_contract.ps1')
foreach($relative in $runtimeFiles){$lineNo=0;foreach($line in [IO.File]::ReadAllLines((Join-Path $ProjectRoot $relative),[Text.Encoding]::UTF8)){$lineNo++;if($line-match'(?i)[A-Z]:\\' -and -not ($relative-eq'tools/renderer_production_common.ps1'-and$line-match'legacyPrefix')){Fail "local absolute path dependency: ${relative}:$lineNo"}}}
if(@($failures|Where-Object{$_ -like 'local absolute path*'}).Count-eq 0){Pass 'no local absolute runtime paths'}
if((Get-Content -Raw -Encoding UTF8 (Join-Path $ProjectRoot 'tools\run_daily_production.ps1'))-match"outputs\\APL_Deep_Scan_Brand"){Fail 'runner still depends on outputs logo'}else{Pass 'no work/outputs/Archive historical dependency'}

Invoke-Test 'renderer smoke' (Join-Path $ProjectRoot 'tools\tests\test_cross_pc_renderer_smoke.ps1')
Invoke-Test 'Table Card semantic fixture' (Join-Path $ProjectRoot 'tools\tests\test_table_card_semantic_contract.ps1')
if($FullRegression){Invoke-Test 'Final Audit and Archive V2 fixture' (Join-Path $ProjectRoot 'tools\tests\test_archive_workflow_v2.ps1')}

if($failures.Count-gt 0){Write-Host 'NOT READY' -ForegroundColor Red;[pscustomobject]@{Status='NOT READY';EnvironmentReady=$false;ProductionStarted=$false;Failures=@($failures|ForEach-Object{$_})};exit 1}
Write-Host 'CROSS-PC ENVIRONMENT READY' -ForegroundColor Green
[pscustomobject]@{Status='CROSS-PC ENVIRONMENT READY';EnvironmentReady=$true;ProductionStarted=$false;RequiredHeadFiles=$required.Count;PowerShell=$version.ToString();FullRegression=[bool]$FullRegression}
