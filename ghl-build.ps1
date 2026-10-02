param(
  [string]$SrcPath   = "styles.css",
  [string]$DestPath  = "ghl\bm-SHARED-CSS.css"
)

$srcFull  = Join-Path (Get-Location) $SrcPath
$destFull = Join-Path (Get-Location) $DestPath

$WRAP = ':where(.bm-page, .bm-page *, .bm-page *::before, .bm-page *::after)'

function Is-Star([string]$s) {
  $t = $s.Trim()
  return ($t -eq '*') -or ($t -eq '*::before') -or ($t -eq '*::after')
}

function Scope-Selector([string]$sel) {
  $s = $sel.Trim()
  $s = $s -replace '^\.bm-page\s+', ''          # idempotent

  switch ($s) {
    ':root'          { return '.bm-page' }
    'body'           { return '.bm-page' }
    'html'           { return 'html' }
    'img'            { return '.bm-page img' }
    'a'              { return '.bm-page a' }
    'a:hover'        { return '.bm-page a:hover' }
    ':focus-visible' { return '.bm-page :focus-visible' }
    default          { return '.bm-page ' + $s }
  }
}

# --- read + scope single-line media queries -------------------------
$text = [System.IO.File]::ReadAllText($srcFull)
$text = [regex]::Replace($text, '@media \(([^)]+)\) \{ (\.[\w-]+) \{', '@media ($1) { .bm-page $2 {')

$rawLines = $text -split "`r?`n"

# ------------------------------------------------------------------
# Pass 1: collapse multi-line selector lists.
# A line ending in ',' continues a selector list ONLY if the previous
# emitted line was a selector (ended in '{'). A ',' inside a
# declaration block continues a property value, not a selector.
# ------------------------------------------------------------------
$collapsed = New-Object System.Collections.Generic.List[string]
$inCmt = $false
$pending = ''

foreach ($line in $rawLines) {
  $t = $line.Trim()

  if ($t.StartsWith('/*')) { $inCmt = $true }
  if ($inCmt) {
    if ($pending) { $pending += ' ' + $t } else { $collapsed.Add($line) }
    if ($t.EndsWith('*/')) { $inCmt = $false }
    continue
  }

  if ($pending) {
    if ($t.EndsWith('{')) { $collapsed.Add($pending + ' ' + $t); $pending = '' }
    else { $pending += ' ' + $t }
    continue
  }

  if ($t -eq '') { $collapsed.Add($line); continue }

  # decide whether this ',' is a selector continuation or a property one
  $prev = ''
  for ($k = $collapsed.Count - 1; $k -ge 0; $k--) {
    $pt = $collapsed[$k].Trim()
    if ($pt -eq '') { continue }
    $prev = $pt; break
  }
  if ($t.EndsWith(',') -and $prev.EndsWith('{')) { $pending = $t; continue }

  $collapsed.Add($line)
}
if ($pending) { $collapsed.Add($pending) }

# ------------------------------------------------------------------
# Pass 2: scope every rule.
# Two shapes to handle:
#   A) multi-line  ".foo {"        selector ends the line
#   B) single-line ".foo { bar; }" selector sits before the first '{'
# A line whose text before '{' ends in ';' or looks like "prop: value"
# is a declaration, not a selector.
# ------------------------------------------------------------------
$result = New-Object System.Collections.Generic.List[string]
$inCmt = $false

foreach ($line in $collapsed) {
  $t = $line.Trim()
  if ($t.StartsWith('/*')) { $inCmt = $true }
  if ($inCmt) {
    $result.Add($line)
    if ($t.EndsWith('*/')) { $inCmt = $false }
    continue
  }
  if ($t -eq '' -or $t.StartsWith('@') -or -not $t.Contains('{')) { $result.Add($line); continue }

  $bracePos = $t.IndexOf('{')
  $preBrace = $t.Substring(0, $bracePos)

  # declaration, not a selector: "prop: value;" or "prop: value"
  if ($preBrace.TrimEnd() -match ';\s*$') { $result.Add($line); continue }
  if ($preBrace -match '^[a-zA-Z-]+\s*:\s*[^:]*$') { $result.Add($line); continue }

  $indent  = $line.Substring(0, $line.Length - $line.TrimStart().Length)
  $postBrace = $t.Substring($bracePos + 1)          # " ..." or " ... }"
  $suffix  = if ($t.EndsWith('{')) { ' {' } else { ' {' + $postBrace }

  $items   = @($preBrace -split ',' | Where-Object { $_.Trim() -ne '' })
  $hasStar = $false
  foreach ($i in $items) { if (Is-Star $i) { $hasStar = $true } }

  if ($hasStar) { $scoped = $WRAP }
  else { $scoped = ($items | ForEach-Object { Scope-Selector $_ }) -join ', ' }

  $result.Add($indent + $scoped + $suffix)
}

$joined = ($result -join "`r`n")

# ------------------------------------------------------------------
# Guard: refuse to write anything malformed
# ------------------------------------------------------------------
if ($joined -match '\.bm-page \.bm-page') { throw "ABORT: double prefix." }
if ($joined -match '\.\.bm-page')           { throw "ABORT: double dot." }

# Every rule must end up scoped. Scan every line that opens a rule and
# is not an at-rule, and require an approved opening.
# $pre is the text BEFORE the '{', so it never contains the brace.
# html is deliberately left global for scroll behaviour, and .inner is
# one of our own GHL container overrides. Nothing else may be unscoped.
$ALLOWED = '^\.bm-page\b|^:where\(\.bm-page|^html\b|^:root\b|^\.inner\b'
$chk = ($joined -split "`r?`n")
$inCmt = $false
$undeclared = @()
foreach ($cl in $chk) {
  $ct = $cl.Trim()
  if ($ct.StartsWith('/*')) { $inCmt = $true }
  if ($inCmt) { if ($ct.EndsWith('*/')) { $inCmt = $false }; continue }
  if ($ct -eq '' -or $ct.StartsWith('@') -or -not $ct.Contains('{')) { continue }
  $pre = $ct.Substring(0, $ct.IndexOf('{'))
  if ($pre.TrimEnd() -match ';\s*$') { continue }
  if ($pre -match '^[a-zA-Z-]+\s*:\s*[^:]*$') { continue }
  if ($pre -notmatch $ALLOWED) { $undeclared += $ct }
}
if ($undeclared.Count -gt 0) {
  Write-Output "ABORT: $($undeclared.Count) unscoped rule(s) found:"
  $undeclared | ForEach-Object { Write-Output "   $_" }
  throw "Not writing. Transform is incomplete."
}

$preamble = @'
/* ============================================================
   BRIGHT MINDS LEARNING CENTER
   GoHighLevel paste stylesheet
   ------------------------------------------------------------
   WHERE THIS GOES
     Page editor -> CSS icon (top toolbar) -> select all -> paste.
     Paste into every page that uses the Bright Minds code, or into
     Funnel Settings -> Custom CSS if your plan exposes one.

   WHY A SEPARATE STYLESHEET
     GHL custom code blocks inject HTML into an already-rendered
     page body, so this file cannot be linked.

   EVERY RULE IS SCOPED TO .bm-page
     GHL owns the header, footer, section and row surrounding our
     markup. An unscoped `*` reset or `body` rule would destroy that
     layout. The .bm-page wrapper div sits at the top of each HTML file.
   ============================================================ */

@import url('https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..600&family=Public+Sans:wght@300;400;500;600;700&display=swap');

/* ---------- GHL overrides ---------- */

/* GHL defaults the page background to white. This design is parchment. */
html, body {
  background: #fdf9f4 !important;
}

/* GHL silently caps its container at 1170px and pads it. Our layout
   manages its own width through .wrap. */
.inner {
  max-width: 100% !important;
  padding-left: 0 !important;
  padding-right: 0 !important;
}

/* ---------- Scoped stylesheet ---------- */

'@

[System.IO.File]::WriteAllText($destFull, $preamble + $joined)
Write-Output "written: $DestPath"
Write-Output "size:   $([math]::Round((Get-Item $destFull).Length/1KB,1)) KB"
