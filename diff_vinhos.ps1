$allFiles = Get-ChildItem -Path "produtos\Vinhos" -Recurse -File -Include *.png,*.jpg,*.jpeg,*.webp,*.gif | Select-Object -ExpandProperty FullName
$text = (Get-Content productsDB.js -Raw -Encoding UTF8) -replace '^window\.productsDB = ', '' -replace ';$', ''
$json = ConvertFrom-Json -InputObject $text
$includedPaths = @{}
foreach ($v in $json.vinhos.files) {
    if ($v.isGroup) {
        foreach ($variant in $v.variants) {
            $p = $variant.img.Replace("/", "\").Replace("%20", " ")
            $includedPaths[$p] = $true
        }
    } else {
        $p = $v.img.Replace("/", "\").Replace("%20", " ")
        $includedPaths[$p] = $true
    }
}
$missing = 0
foreach ($f in $allFiles) {
    $rel = $f.Replace("C:\Users\vazfa\.gemini\antigravity\scratch\sotarvil\", "")
    # Check naive and uri decoded match
    $matched = $false
    foreach ($k in $includedPaths.Keys) {
        if ($rel -match ([regex]::Escape($k))) { $matched = $true; break }
        $decoded = [Uri]::UnescapeDataString($k)
        if ($rel -match ([regex]::Escape($decoded))) { $matched = $true; break }
    }
    if (-not $matched) {
        Write-Host "Missing: $rel"
        $missing++
        if ($missing -ge 20) { break }
    }
}
Write-Host "Total missing found: $missing"
