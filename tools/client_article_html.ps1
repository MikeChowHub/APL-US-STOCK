# Repository-owned shared HTML presentation. No external runtime dependencies.
function Test-AplStyledArticleDate([string]$ScanDate) { return $ScanDate -cge '2026-10-20' }

function Get-AplArticleSymbols([string]$RankingPath,[string]$GainersPath) {
  $symbols=@(Import-Csv -LiteralPath $RankingPath -Encoding UTF8 | Select-Object -First 30 | ForEach-Object { [string]$_.Symbol })
  Add-Type -AssemblyName Microsoft.VisualBasic
  $reader=New-Object Microsoft.VisualBasic.FileIO.TextFieldParser -ArgumentList @($GainersPath,[Text.Encoding]::UTF8,$true)
  try {
    $reader.SetDelimiters(',');$reader.HasFieldsEnclosedInQuotes=$true
    $headers=@($reader.ReadFields());$index=[Array]::IndexOf($headers,'Symbol')
    if($index-lt0){throw 'Top Gainers Symbol is missing.'}
    for($i=0;$i-lt5-and-not$reader.EndOfData;$i++){$fields=@($reader.ReadFields());$symbols+=[string]$fields[$index]}
  } finally {$reader.Close()}
  return @($symbols|Sort-Object -Unique)
}

function ConvertTo-AplArticleBody([string]$Html) {
  $body=$Html.Trim();$boundary=''
  if($body-match'(?s)\s*<div id="apl-member-content"></div>\s*$'){
    $body=[regex]::Replace($body,'(?s)\s*<div id="apl-member-content"></div>\s*$','').Trim()
    $boundary="`n<div id=`"apl-member-content`"></div>"
  }
  if($body-match'^<div style="'){
    $body=[regex]::Replace($body,'(?s)^<div style="[^"]*">\s*','')
    if($body-notmatch'(?s)</div>\s*$'){throw 'Article wrapper is unclosed.'}
    $body=[regex]::Replace($body,'(?s)\s*</div>\s*$','')
  }
  $body=[regex]::Replace($body,'(?is)<(h3|p)\b[^>]*>','<$1>')
  $body=[regex]::Replace($body,'(?is)</?(?:strong|span)\b[^>]*>','')
  return $body.Trim()+$boundary
}

function ConvertTo-AplStyledArticle([string]$Html,[string[]]$Symbols=@()) {
  $body=ConvertTo-AplArticleBody $Html;$boundary=''
  if($body.EndsWith('<div id="apl-member-content"></div>')){
    $body=$body.Substring(0,$body.LastIndexOf('<div id="apl-member-content"></div>')).Trim()
    $boundary="`n<div id=`"apl-member-content`"></div>"
  }
  $wrapper='box-sizing:border-box;width:100%;max-width:800px;margin:0 auto;padding:0;background-color:transparent;color:#e4e7df;font-family:Arial,Microsoft JhengHei,sans-serif;'
  $heading='margin:34px 0 23px;padding:0 0 14px;border-bottom:1px solid #41473c;color:#f0eee5;font-family:Arial,Microsoft JhengHei,sans-serif;font-size:25px;font-weight:700;line-height:1.5;'
  $paragraph='margin:0 0 23px;color:#e4e7df;font-family:Arial,Microsoft JhengHei,sans-serif;font-size:18px;line-height:1.95;letter-spacing:0.15px;'
  $callout='margin:0 0 23px;padding:19px 20px;border-left:3px solid #d7b76d;background-color:#17212b;color:#e4e7df;font-family:Arial,Microsoft JhengHei,sans-serif;font-size:18px;line-height:1.95;'
  $body=$body.Replace('<h3>',('<h3 style="'+$heading+'">')).Replace('<p>',('<p style="'+$paragraph+'">'))
  $first=[regex]::Match($body,'(?is)<p style="[^"]*">(.*?)</p>')
  if(-not$first.Success){throw 'Article opening paragraph missing.'}
  $intro=$first.Groups[1].Value
  $judgement=[regex]::Match($intro,'[^。！？]*(?:主要關注|重點關注|首選|看好)[^。！？]*(?:[。！？]|$)')
  if(-not$judgement.Success){$judgement=[regex]::Match($intro,'[^。！？]+(?:[。！？]|$)')}
  $intro=$intro.Substring(0,$judgement.Index)+'<span style="color:#e3c37b;">'+$judgement.Value+'</span>'+$intro.Substring($judgement.Index+$judgement.Length)
  $replacement='<p style="'+$callout+'">'+$intro+'</p>'
  $body=$body.Substring(0,$first.Index)+$replacement+$body.Substring($first.Index+$first.Length)
  $seen=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
  $pattern=if($Symbols.Count){'(?<![A-Za-z0-9])('+(($Symbols|Sort-Object Length -Descending|ForEach-Object{[regex]::Escape($_)})-join'|')+')(?![A-Za-z0-9])'}else{''}
  $parts=[regex]::Split($body,'(<[^>]*>)')
  for($i=0;$i-lt$parts.Length;$i+=2){
    $parts[$i]=[regex]::Replace($parts[$i],'&(?!#\d+;|#x[0-9a-fA-F]+;|[A-Za-z]+;)','&amp;')
    if($pattern){$parts[$i]=[regex]::Replace($parts[$i],$pattern,{
      param($m)
      if($seen.Add($m.Value)){return '<strong style="font-weight:700;color:#f3f1e8;">'+$m.Value+'</strong>'}
      return $m.Value
    })}
  }
  return '<div style="'+$wrapper+'">'+"`n"+($parts-join'').Trim()+"`n</div>"+$boundary
}

function Assert-AplStyledArticle([string]$Html,[string[]]$Symbols=@()) {
  if(-not$Symbols.Count){$Symbols=@([regex]::Matches($Html,'<strong style="font-weight:700;color:#f3f1e8;">([A-Z][A-Z0-9.]*)</strong>')|ForEach-Object{$_.Groups[1].Value}|Sort-Object -Unique)}
  $expected=ConvertTo-AplStyledArticle -Html $Html -Symbols $Symbols
  if($Html.Replace("`r`n","`n").Trim()-cne$expected.Replace("`r`n","`n").Trim()){throw 'Article HTML presentation violates the shared inline style contract.'}
  if(@([regex]::Matches($Html,'color:#e3c37b;')).Count-ne1){throw 'Article must contain one gold core judgement.'}
  return $true
}
