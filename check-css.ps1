$g = Get-Content "ghl\bm-SHARED-CSS.css" -Raw

Write-Output "=== structure checks ==="
$t1 = if ($g -match '(?m)^\.bm-page \{\r?\n  /\* Surfaces') {'YES'} else {'NO'}
$t2 = if ($g -match ':where\(\.bm-page, \.bm-page \*') {'YES'} else {'NO'}
$t3 = if ($g -match '\.bm-page \.bm-page') {'FOUND - bug'} else {'none'}
$t4 = if ($g -match '\.\.bm-page') {'FOUND - bug'} else {'none'}
$stripped = [regex]::Replace($g,'/\*[\s\S]*?\*/','').Trim()
$t5 = if ($stripped.StartsWith('@import')) {'YES'} else {'NO'}
$t6 = if ($g -match 'html, body \{') {'YES'} else {'NO'}
$t7 = if ($g -match '\.inner \{') {'YES'} else {'NO'}
"  token block on .bm-page : $t1"
"  :where() reset present  : $t2"
"  double prefix           : $t3"
"  double dot              : $t4"
"  @import is first rule   : $t5"
"  html,body override      : $t6"
"  .inner override         : $t7"

Write-Output ""
Write-Output "=== no prefix leaked into property VALUES ==="
foreach ($p in @('transition','color','background','padding','margin','border','font','width','height','text-align')) {
  $bad = [regex]::Matches($g, $p + ':\s*[^;\r\n]*\.bm-page').Count
  "  {0,-12} -> {1}" -f ($p + ':'), $bad
}

Write-Output ""
Write-Output "=== custom property parity ==="
$used  = [regex]::Matches($g,'var\((--[\w-]+)\)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
$decl  = [regex]::Matches($g,'(--[\w-]+)\s*:')  | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
$undef = $used | Where-Object { $_ -notin $decl }
if ($undef) { "  UNDECLARED: $($undef -join ', ')" } else { "  all $($used.Count) custom properties declared - OK" }

Write-Output ""
Write-Output "=== every class used in the HTML exists in the scoped CSS ==="
$html = (Get-Content "index.html" -Raw) + (Get-Content "book.html" -Raw) + (Get-Content "thank-you.html" -Raw)
$usedClasses = [regex]::Matches($html,'class="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | ForEach-Object { $_ -split '\s+' } | Where-Object { $_ } | Select-Object -Unique
$gaps = @()
foreach ($c in $usedClasses) {
  if ($g -notmatch ('\.bm-page ' + [regex]::Escape($c) + '\b')) { $gaps += $c }
}
if ($gaps) { "  GAPS: $($gaps -join ', ')" } else { "  all $($usedClasses.Count) classes are scoped and present - OK" }
