$fails = 0
function Chk($label, $cond, $detail) {
  if ($cond) { Write-Output "  PASS  $label" }
  else { Write-Output "  FAIL  $label  $detail"; $script:fails++ }
}

$css  = Get-Content "ghl\bm-SHARED-CSS.css" -Raw
$p1   = Get-Content "ghl\page-1-landing.html" -Raw
$p2   = Get-Content "ghl\page-2-booking.html" -Raw
$p3   = Get-Content "ghl\page-3-confirmation.html" -Raw
$all  = $p1 + $p2 + $p3

Write-Output "=== CSS: scoping integrity ==="
Chk "token block scoped to .bm-page" ($css -match '(?m)^\.bm-page \{\r?\n  /\* Surfaces') ""
Chk "reset uses :where() not bare *" ($css -match ':where\(\.bm-page' -and $css -notmatch '(?m)^\s*\*(\s*,|\s*\{)') ""
Chk "no double prefix"      ($css -notmatch '\.bm-page \.bm-page') ""
Chk "no double dot"         ($css -notmatch '\.\.bm-page') ""
Chk "@import is first rule" ([regex]::Replace($css,'/\*[\s\S]*?\*/','').Trim().StartsWith('@import')) ""
Chk "html,body override present" ($css -match 'html, body \{') ""
Chk ".inner 1170px override"      ($css -match '\.inner \{') ""

# every rule that opens must be scoped (except html/.inner by design)
$undeclared = @()
$inCmt = $false
foreach ($cl in ($css -split "`r?`n")) {
  $ct = $cl.Trim()
  if ($ct.StartsWith('/*')) { $inCmt = $true }
  if ($inCmt) { if ($ct.EndsWith('*/')) { $inCmt = $false }; continue }
  if ($ct -eq '' -or $ct.StartsWith('@') -or -not $ct.Contains('{')) { continue }
  $pre = $ct.Substring(0, $ct.IndexOf('{'))
  if ($pre.TrimEnd() -match ';\s*$') { continue }
  if ($pre -match '^[a-zA-Z-]+\s*:\s*[^:]*$') { continue }
  if ($pre -notmatch '^\.bm-page\b|^:where\(\.bm-page|^html\b|^:root\b|^\.inner\b') { $undeclared += $ct }
}
Chk "every rule scoped (.bm-page / html / .inner)" ($undeclared.Count -eq 0) "-> $($undeclared -join ' ; ')"

Write-Output ""
Write-Output "=== CSS: nothing broken in the transform ==="
$used = [regex]::Matches($css,'var\((--[\w-]+)\)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
$decl = [regex]::Matches($css,'(--[\w-]+)\s*:') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
$undef = $used | Where-Object { $_ -notin $decl }
Chk "all custom properties declared" ($undef.Count -eq 0) "-> $($undef -join ', ')"

$leak = 0
foreach ($prop in @('transition','color','background','padding','margin','border','font','height','text-align')) {
  $leak += [regex]::Matches($css, '(?m)^\s*' + $prop + ':\s*[^;\r\n]*\.bm-page').Count
}
Chk "no prefix leaked into property values" ($leak -eq 0) "-> $leak hits"

Write-Output ""
Write-Output "=== HTML fragments: GHL shape ==="
foreach ($pair in @(@('page 1',$p1), @('page 2',$p2), @('page 3',$p3))) {
  $nm = $pair[0]; $c = $pair[1]
  $clean = ($c -notmatch '<!DOCTYPE') -and ($c -notmatch '<html[\s>]') -and ($c -notmatch '<head[\s>]') -and ($c -notmatch '<body[\s>]')
  Chk "$nm : no document shell" $clean ""
  Chk "$nm : wrapped in .bm-page" ($c -match '<div class="bm-page">') ""
  Chk "$nm : no styles.css link" ($c -notmatch 'styles\.css') ""
  Chk "$nm : no font link tags" ($c -notmatch 'fonts\.googleapis') ""
  Chk "$nm : no local asset paths" ($c -notmatch 'assets/') ""
  $unres = [regex]::Matches($c,'(?:href|src)="(?!https?://|\{\{|mailto:|tel:)([^"]*)"')
  Chk "$nm : every ref is absolute or a token" ($unres.Count -eq 0) "-> $(($unres | ForEach-Object { $_.Groups[1].Value }) -join ',')"
}

Write-Output ""
Write-Output "=== content preserved through the transform ==="
Chk "circled-word signature survived"    ($p1 -match 'class="circled">stuck<') ""
Chk "ember testimonial card survived"   ($p1 -match 'class="ember-card"') ""
Chk "GHL calendar iframe survived"      ($p2 -match 'widget/booking/PtUhcLCSm96dyQaVPAoo') ""
Chk "form_embed.js survived"            ($p2 -match 'link\.msgsndr\.com/js/form_embed\.js') ""
Chk ".gcal min-height floor survived"   ($p2 -match 'class="gcal"') ""
Chk "iframe title (a11y) survived"      ($p2 -match 'title="Book your child') ""
Chk "full CTA label survived"           ($p1 -match 'Reserve My Child’s Free Saturday Slot') ""
Chk "six Saturday slots survived"       (([regex]::Matches($p1,'>\d{1,2}:\d{2} [AP]M<')).Count -eq 6) "-> $([regex]::Matches($p1,'>\d{1,2}:\d{2} [AP]M<').Count) found"
Chk "photo width/height kept (no CLS)" ($p1 -match 'width="1376" height="768"') ""
Chk "no em-dashes anywhere"             ($all -notmatch ([char]0x2014)) ""

Write-Output ""
Write-Output "=== tag balance in fragments ==="
foreach ($pair in @(@('page 1',$p1), @('page 2',$p2), @('page 3',$p3))) {
  $nm = $pair[0]; $c = $pair[1]
  $bad = @()
  foreach ($tag in @('div','section','details','header','footer','main','figure','ol','ul','span','p','dl','a','iframe','script')) {
    $o = ([regex]::Matches($c,"<$tag\b")).Count
    $cl= ([regex]::Matches($c,"</$tag>")).Count
    if ($o -ne $cl) { $bad += "$tag $o/$cl" }
  }
  Chk "$nm : tags balanced" ($bad.Count -eq 0) "-> $($bad -join ', ')"
}

Write-Output ""
if ($fails -eq 0) { Write-Output "ALL CHECKS PASSED" } else { Write-Output "$fails CHECK(S) FAILED" }
