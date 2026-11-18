# Mechanical reading checks. These checks do not verify facts, sources or meaning.
function Get-AplReaderQualityPolicy {
  param([Parameter(Mandatory=$true)][string]$ScanDate)
  $date=[datetime]::ParseExact($ScanDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
  [pscustomobject][ordered]@{
    Enabled=($date-ge[datetime]'2026-11-12')
    ExecutiveMinChars=180
    MarketMinChars=240
    InvestmentMinChars=180
    MarketMinParagraphs=2
    InvestmentMinParagraphs=2
  }
}

function ConvertTo-AplReaderPlainText {
  param([AllowEmptyString()][string]$Text)
  $value=$Text -replace '!\[[^\]]*\]\([^\r\n]*\)',' '
  $value=$value -replace '\[([^\]]+)\]\([^\r\n]*\)','$1'
  $value=$value -replace '<[^>]+>',' '
  $value=$value -replace '[`*_]',''
  return (($value-replace'\s+',' ').Trim())
}

function ConvertTo-AplReaderComparisonKey {
  param([AllowEmptyString()][string]$Text)
  $plain=ConvertTo-AplReaderPlainText $Text
  return (($plain-replace'[\p{P}\p{S}\s]','').ToUpperInvariant())
}

function Get-AplReaderParagraphs {
  param([Parameter(Mandatory=$true)][string]$Markdown)
  $records=New-Object System.Collections.Generic.List[object]
  $lines=New-Object System.Collections.Generic.List[string]
  $section='Article';$skipSeo=$false;$paragraphNumber=0
  foreach($line in @($Markdown-split'\r?\n')+@('')){
    $isHeading=$line-match'^\s*#{1,6}\s+(.+?)\s*$'
    $newHeading=if($isHeading){$Matches[1]}else{''}
    if($isHeading-or[string]::IsNullOrWhiteSpace($line)){
      if($lines.Count-gt0){
        $paragraphNumber++
        $plain=ConvertTo-AplReaderPlainText ($lines.ToArray()-join' ')
        if($plain){[void]$records.Add([pscustomobject]@{Section=$section;Paragraph=$paragraphNumber;Location="$section / paragraph $paragraphNumber";Text=$plain})}
        $lines.Clear()
      }
      if($isHeading){
        $skipSeo=$newHeading.Trim()-ieq'SEO and Sharing'
        $section=$newHeading.Trim();$paragraphNumber=0
      }
    }elseif(-not$skipSeo){[void]$lines.Add($line)}
  }
  return $records.ToArray()
}

function Get-AplReaderSentences {
  param([Parameter(Mandatory=$true)][string]$Text)
  # Preserve commas, colons and semicolons within a sentence. Decimal points
  # remain intact; a full stop followed by whitespace or the end ends a sentence.
  return @($Text-split'(?<=[。！？!?])|(?<=\.)(?=\s|$)'|ForEach-Object{$_.Trim()}|Where-Object{$_})
}

function Assert-AplArticleReaderQuality {
  param(
    [Parameter(Mandatory=$true)][string]$Markdown,
    [Parameter(Mandatory=$true)][string]$Company,
    [Parameter(Mandatory=$true)][string[]]$Top30Symbols
  )
  $symbols=@($Top30Symbols|ForEach-Object{([string]$_).Trim().ToUpperInvariant()})
  if($symbols.Count-ne30-or@($symbols|Select-Object -Unique).Count-ne30-or@($symbols|Where-Object{[string]::IsNullOrWhiteSpace($_)}).Count-gt0){throw 'Reader quality requires exactly 30 distinct non-empty Top 30 symbols.'}
  $paragraphs=@(Get-AplReaderParagraphs $Markdown)
  if($paragraphs.Count-eq0){throw 'Reader quality found no article paragraphs outside SEO and Sharing.'}
  $paragraphKeys=@{};$sentenceKeys=@{};$warnings=New-Object System.Collections.Generic.List[object]
  $longSentenceCount=0
  foreach($paragraph in $paragraphs){
    $text=[string]$paragraph.Text;$key=ConvertTo-AplReaderComparisonKey $text
    if($key.Length-ge80){
      if($paragraphKeys.ContainsKey($key)){throw "Reader quality found a repeated long paragraph at $($paragraphKeys[$key]) and $($paragraph.Location)."}
      $paragraphKeys[$key]=[string]$paragraph.Location
    }
    if($key.Length-gt240){[void]$warnings.Add([pscustomobject]@{Code='LONG_PARAGRAPH';Location=$paragraph.Location;Characters=$key.Length;Message='Consider splitting this paragraph if it develops more than one idea.'})}
    $leak='(?:現有|本專案|本項目|內部)(?:的)?(?:標準)?(?:板塊)?分類[^。！？\r\n]{0,35}(?:沒有|未有|缺少|不包含|未涵蓋|不適合)[^。！？\r\n]{0,65}(?i:Others)|(?i:Others)[^。！？\r\n]{0,65}(?:現有|本專案|內部)(?:的)?(?:標準)?分類[^。！？\r\n]{0,35}(?:沒有|未有|缺少|不包含|未涵蓋|不適合)'
    if($text-match$leak){throw "Reader quality found an internal classification limitation in client prose at $($paragraph.Location)."}
    $sentenceNumber=0
    foreach($sentence in @(Get-AplReaderSentences $text)){
      $sentenceNumber++
      $sentenceKey=ConvertTo-AplReaderComparisonKey $sentence
      if($sentenceKey.Length-lt45){continue}
      $longSentenceCount++
      if(-not$sentenceKeys.ContainsKey($sentenceKey)){$sentenceKeys[$sentenceKey]=New-Object System.Collections.Generic.List[string]}
      [void]$sentenceKeys[$sentenceKey].Add("$($paragraph.Location) / sentence $sentenceNumber")
      if($sentenceKeys[$sentenceKey].Count-ge3){throw "Reader quality found the same long sentence three times at $($sentenceKeys[$sentenceKey]-join'; ')."}
    }
  }

  $headings=@([regex]::Matches($Company,'(?m)^#{2,3}\s+(.+?)\s*$'))
  $companyBlocks=@{}
  for($i=0;$i-lt$headings.Count;$i++){
    $heading=[string]$headings[$i].Groups[1].Value
    $identity=[regex]::Match($heading,'^(?:\d+[.)、]\s*)?(?:\*\*)?([A-Z][A-Z0-9.-]*)(?:\*\*)?(?=\s|[｜|：:]|$)')
    if(-not$identity.Success){continue}
    $symbol=$identity.Groups[1].Value
    if($symbols-cnotcontains$symbol){continue}
    if($companyBlocks.ContainsKey($symbol)){throw "Reader quality found duplicate company sections for $symbol."}
    $start=$headings[$i].Index+$headings[$i].Length
    $end=if($i+1-lt$headings.Count){$headings[$i+1].Index}else{$Company.Length}
    $body=ConvertTo-AplReaderPlainText $Company.Substring($start,$end-$start)
    $companyBlocks[$symbol]=[pscustomobject]@{Symbol=$symbol;Location="Company: $heading";Text=$body}
  }
  $companySentenceKeys=@{};$companyDetails=New-Object System.Collections.Generic.List[object]
  foreach($symbol in $symbols){
    if(-not$companyBlocks.ContainsKey($symbol)){throw "Reader quality requires an independent company section for $symbol."}
    $block=$companyBlocks[$symbol];$plain=[string]$block.Text
    $characters=($plain-replace'\s','').Length
    $chinese=[regex]::Matches($plain,'[\u3400-\u9FFF]').Count
    if($characters-lt60-or$chinese-lt25){throw "Reader quality found an empty or thin company section at $($block.Location): $characters non-whitespace characters and $chinese Chinese characters; requires 60 and 25."}
    [void]$companyDetails.Add([pscustomobject]@{Symbol=$symbol;Characters=$characters;ChineseCharacters=$chinese})
    foreach($sentence in @(Get-AplReaderSentences $plain)){
      if([regex]::Matches($sentence,'[\u3400-\u9FFF]').Count-lt18){continue}
      # A company identifier must not make copied prose look company-specific.
      # Keep product codes containing the ticker, numeric facts and business terms.
      $symbolPattern='(?<![A-Z0-9.-])'+[regex]::Escape($symbol)+'(?![A-Z0-9.-])'
      $comparisonSentence=[regex]::Replace($sentence,$symbolPattern,'',[Text.RegularExpressions.RegexOptions]::IgnoreCase)
      $key=ConvertTo-AplReaderComparisonKey $comparisonSentence
      if(-not$companySentenceKeys.ContainsKey($key)){$companySentenceKeys[$key]=@{}}
      $companySentenceKeys[$key][$symbol]=[string]$block.Location
      if($companySentenceKeys[$key].Count-ge3){throw "Reader quality found a copied company-analysis sentence in three or more companies: $($companySentenceKeys[$key].Values-join'; ')."}
    }
  }
  return [pscustomobject][ordered]@{
    SchemaVersion='APL Article Reader Quality v1.0'
    Status='PASS'
    Scope='Mechanical text checks only; financial facts, sources and editorial meaning require separate review.'
    ArticleParagraphs=$paragraphs.Count
    LongSentencesChecked=$longSentenceCount
    CompanySections=$companyDetails.Count
    MechanicalChecks=[pscustomobject][ordered]@{NoRepeatedLongParagraphs=$true;NoTriplicatedLongSentences=$true;IndependentCompanySections=$true;CompanyMinimumContent=$true;NoCopiedCompanyFiller=$true;NoInternalClassificationExcuses=$true}
    Warnings=@($warnings.ToArray())
    Companies=@($companyDetails.ToArray())
  }
}
