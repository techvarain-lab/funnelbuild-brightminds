param([string]$HtmlDir = ".")

$map = @{
  'index.html'     = 'page-1-landing.html'
  'book.html'      = 'page-2-booking.html'
  'thank-you.html' = 'page-3-confirmation.html'
}

$imgTokens = @{
  'assets/images/optimized/Student_smiling_with_tutor.jpg'         = '{{IMG_HERO}}'
  'assets/images/optimized/Student_solving_math_worksheet.jpg'     = '{{IMG_WORKSHEET}}'
  'assets/images/optimized/Students_studying_with_teacher.jpg'     = '{{IMG_CLASSROOM}}'
  'assets/images/optimized/Mother_and_daughter_entering_school.jpg'= '{{IMG_ARRIVAL}}'
}

$seo = New-Object System.Collections.Generic.List[string]

foreach ($src in $map.Keys) {
  $path = Join-Path (Get-Location) $HtmlDir | Join-Path -ChildPath $src
  $c = [System.IO.File]::ReadAllText($path)

  # ---- capture SEO values before stripping the head -------------------
  $title = if ($c -match '<title>([^<]*)</title>') { $Matches[1] } else { '' }
  $desc  = if ($c -match '<meta name="description" content="([^"]*)"') { $Matches[1] } else { '' }
  $robots= if ($c -match '<meta name="robots" content="([^"]*)"') { $Matches[1] } else { '' }
  $ogAlt = ''
  $seo.Add("### $src")
  $seo.Add("  title       : $title")
  $seo.Add("  description : $desc")
  $seo.Add("  robots      : $(if($robots){$robots}else{'(default: index, follow)'})")
  $seo.Add('')

  # ---- strip the document shell ---------------------------------------
  $c = $c -replace '(?s)<!DOCTYPE[^>]*>', ''
  $c = $c -replace '(?s)<head[^>]*>.*?</head>', ''
  $c = $c -replace '(?s)<body[^>]*>', ''
  $c = $c -replace '(?s)</body>', ''
  $c = $c -replace '(?s)<html[^>]*>', ''
  $c = $c -replace '(?s)</html>', ''

  # ---- drop the font + stylesheet links; the CSS panel supplies them --
  $c = [regex]::Replace($c, '(?s)<link[^>]*fonts\.(googleapis|gstatic)\.com[^>]*>', '')
  $c = [regex]::Replace($c, '(?s)<link[^>]*href="styles\.css"[^>]*>', '')

  # ---- rewrite paths to tokens ----------------------------------------
  # Deep links like index.html#report must be caught too, so the pattern
  # stops at the filename rather than requiring the closing quote.
  $c = $c -replace 'href="index\.html',     'href="{{INDEX_URL}}'
  $c = $c -replace 'href="book\.html',      'href="{{BOOKING_URL}}'
  $c = $c -replace 'href="thank-you\.html', 'href="{{THANKS_URL}}'
  $c = $c -replace 'href="#',                'href="{{INDEX_URL}}#'
  foreach ($k in $imgTokens.Keys) {
    $c = $c.Replace($k, $imgTokens[$k])
  }

  # ---- wrap in the scoping wrapper ------------------------------------
  # List only the tokens this file actually contains, so nobody chases
  # replacements that are not there.
  $present = @([regex]::Matches($c, '\{\{[A-Z_]+\}\}') | ForEach-Object { $_.Value } | Select-Object -Unique | Sort-Object)
  if ($present.Count -gt 0) {
    $tokenList = ($present | ForEach-Object { "     $_" }) -join "`r`n"
  } else {
    $tokenList = "     (none)"
  }

  $banner = @"
<!-- ============================================================
   BRIGHT MINDS -> PASTE INTO A GHL CUSTOM CODE ELEMENT
   ------------------------------------------------------------
   REPLACE THESE TOKENS BEFORE PASTING:
$tokenList

   The stylesheet goes in the page's CSS panel, not in here.
   Everything is wrapped in .bm-page so it cannot disturb GHL's own
   header, footer, section or row layout.
   ============================================================ -->

"@
  $c = $banner + '<div class="bm-page">' + "`r`n" + $c.Trim() + "`r`n</div>" + "`r`n"

  $out = Join-Path (Join-Path (Get-Location) 'ghl') $map[$src]
  [System.IO.File]::WriteAllText($out, $c)
  Write-Output "wrote ghl\$($map[$src])  ($([math]::Round((Get-Item $out).Length/1KB,1)) KB)"
}

[System.IO.File]::WriteAllLines((Join-Path (Join-Path (Get-Location) 'ghl') '_seo.txt'), $seo)
