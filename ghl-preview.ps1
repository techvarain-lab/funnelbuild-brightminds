param([string]$HtmlDir = ".")

# Previews substitute real local paths for the tokens so the page renders
# as it will in GHL, and wrap the fragment in a fake GHL container that
# reproduces the two things GHL adds: a padded row and a capped .inner.
# They are throwaway diagnostics, regenerated from the fragments.
#
# Kept free of here-strings and non-ASCII on purpose: PowerShell 5.1 reads
# .ps1 as ANSI unless the file carries a BOM, which mangles em-dashes and
# quietly truncates interpolated content.

$map = [ordered]@{
  'page-1-landing.html'      = 'preview-page-1.html'
  'page-2-booking.html'      = 'preview-page-2.html'
  'page-3-confirmation.html' = 'preview-page-3.html'
}

$subs = [ordered]@{
  '{{IMG_HERO}}'      = '../assets/images/optimized/Student_smiling_with_tutor.jpg'
  '{{IMG_WORKSHEET}}' = '../assets/images/optimized/Student_solving_math_worksheet.jpg'
  '{{IMG_CLASSROOM}}' = '../assets/images/optimized/Students_studying_with_teacher.jpg'
  '{{IMG_ARRIVAL}}'   = '../assets/images/optimized/Mother_and_daughter_entering_school.jpg'
  '{{INDEX_URL}}'     = '#'
  '{{BOOKING_URL}}'   = 'preview-page-2.html'
  '{{THANKS_URL}}'    = 'preview-page-3.html'
}

$head = @(
  '<!DOCTYPE html>',
  '<html lang="en">',
  '<head>',
  '<meta charset="UTF-8">',
  '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
  '<title>PREVIEW - not for publishing - Bright Minds</title>',
  '<link rel="stylesheet" href="bm-SHARED-CSS.css">',
  '<style>',
  '  /* Simulated GHL chrome, so you can see what the scoped CSS is',
  '     fighting before you paste anything into the builder. */',
  '  .ghl-bar { background:#1a1d21; color:#9ea0a9; padding:10px 16px;',
  '             font:12px/1.4 -apple-system,"Segoe UI",sans-serif;',
  '             border-bottom:1px solid #272c33; text-align:center; }',
  '  .ghl-row { padding:40px 24px; background:#2a2f36; }',
  '  .ghl-inner { max-width:1170px; margin:0 auto; background:#3a4048;',
  '               padding:24px; min-height:200px; }',
  '</style>',
  '</head>',
  '<body>',
  '<div class="ghl-bar">SIMULATED GHL ROW. The grey frame is what your page sits',
  '  inside. Set this row padding to 0 in GHL (guide step 2) and it disappears.</div>',
  '<div class="ghl-row">',
  '  <div class="ghl-inner">'
)

$tail = @(
  '  </div>',
  '</div>',
  '</body>',
  '</html>'
)

foreach ($k in $map.Keys) {
  $fragPath = Join-Path (Join-Path (Get-Location) 'ghl') $k
  if (-not (Test-Path $fragPath)) { throw "missing fragment: $k" }

  $frag = [System.IO.File]::ReadAllText($fragPath)
  if ($frag.Length -lt 500) { throw "fragment $k looks empty ($($frag.Length) chars)" }

  foreach ($s in $subs.Keys) { $frag = $frag.Replace($s, $subs[$s]) }

  $lines = @($head) + @($frag) + @($tail)
  $outPath = Join-Path (Join-Path (Get-Location) 'ghl') $map[$k]

  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($outPath, ($lines -join "`r`n"), $enc)

  $check = [System.IO.File]::ReadAllText($outPath)
  $ok = ($check.Length -gt 1000) -and ($check -match 'bm-page')
  Write-Output ("wrote ghl\{0}  ({1} KB, fragment embedded: {2})" -f $map[$k], [math]::Round((Get-Item $outPath).Length/1KB,1), $ok)
}
