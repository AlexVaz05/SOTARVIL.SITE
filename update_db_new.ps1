[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$baseDir = "C:\Users\vazfa\.gemini\antigravity\scratch\sotarvil"
$imagesDir = Join-Path $baseDir "produtos"
$outputFile = Join-Path $baseDir "productsDB.js"

# Use regex patterns for mapping to handle accents/casing accurately
# Using [ordered] to allow specific overrides (e.g. Laticínios inside Cafés)
$categoryMap = [ordered]@{
    '.*Vinhos.*' = 'vinhos'
    '.*cervejas.*' = 'cervejas'
    '^Pres.*o.*' = 'cervejas'
    '.*Refrigerantes.*' = 'refrigerantes'
    '.*guas.*' = 'aguas'
    '.*Bebidas Brancas.*' = 'bebidas-brancas'
    '.*Caf.*s.*' = 'cafes'
    '.*Champanhes.*' = 'champanhes'
    '.*Detergentes.*' = 'detergentes'
    '.*nerg.*ticos.*' = 'energeticos'
    '.*Espumantes.*' = 'espumantes'
    '.*La Casera.*' = 'la-casera'
    '.*Produtos Alimentares.*' = 'alimentares'
    '.*Sidras.*' = 'sidras'
    '.*atic.*nios.*' = 'laticinios'
}

$titles = @{
    'cervejas' = 'Cervejas'
    'pressao' = "Press$([char]0x00E3)o"
    'sidras' = 'Sidras'
    'refrigerantes' = 'Refrigerantes'
    'nectares' = "N$([char]0x00E9)ctares e Sumos"
    'aguas' = "$([char]0x00C1)guas"
    'vinhos' = 'Vinhos'
    'bebidas-brancas' = 'Bebidas Brancas'
    'champanhes' = 'Champanhes'
    'espumantes' = 'Espumantes'
    'cafes' = "Caf$([char]0x00E9)s e Bebidas Quentes"
    'laticinios' = "Latic$([char]0x00ED)nios"
    'azeites' = "Azeites, $([char]0x00D3)leos e Vinagres"
    'alimentares' = 'Produtos Alimentares'
    'detergentes' = 'Detergentes'
    'energeticos' = "Energ$([char]0x00E9)ticos"
    'la-casera' = 'La Casera'
}

$db = @{}
foreach ($key in $titles.Keys) {
    $db[$key] = @{ title = $titles[$key]; files = @() }
}

function Invoke-StringCleanup($s) {
    if (!$s) { return "" }
    # Only remove leading numbers and separators at the START of the string
    $s = $s -replace '^\d+[\s\-_.]+', ''
    return $s
}

function Get-Name($f) {
    $name = Invoke-StringCleanup($f.BaseName)
    $name = $name -replace '_', ' ' -replace '-', ' '
    return (Get-Culture).TextInfo.ToTitleCase($name.ToLower())
}

$files = Get-ChildItem -Path $imagesDir -Recurse -File | Where-Object { $_.Extension -match "\.(png|jpg|jpeg|webp|gif|heic|heif)$" } | Sort-Object { [regex]::Replace($_.FullName, '\d+', { $args[0].Value.PadLeft(10, '0') }) }

$imagesDirFixed = if ($imagesDir.EndsWith("\")) { $imagesDir } else { $imagesDir + "\" }

foreach ($f in $files) {
    if (-not $f.FullName.StartsWith($imagesDirFixed)) { continue }
    $relPath = $f.FullName.Substring($imagesDirFixed.Length)
    $parts = $relPath.Split([IO.Path]::DirectorySeparatorChar)
    
    if ($parts.Length -lt 1) { continue }
    
    $topFolder = $parts[0]
    
    $categoryKey = "outros"
    foreach ($pattern in $categoryMap.Keys) {
        if ($relPath -match $pattern) {
            $categoryKey = $categoryMap[$pattern]
        }
    }

    if ($topFolder -match '^Press.*o$') {
        $categoryKey = 'pressao'
    }
    
    $brand = $topFolder
    $type = ""
    $hierarchy = ""
    
    if ($parts.Length -gt 2) {
        $brand = $parts[$parts.Length - 2]
        $hierarchyParts = $parts[1..($parts.Length - 2)]
        $hierarchy = $hierarchyParts -join " > "
    } else {
        $brand = $topFolder
        $hierarchy = ""
    }
    
    # Special logics
    if ($categoryKey -eq 'aguas') {
        if ($relPath -match 'Lisas') { $type = 'lisa' }
        elseif ($relPath -match 'Sem Sabor') { $type = 'gas-sem-sabor' }
        elseif ($relPath -match 'Com Sabor') { $type = 'gas-com-sabor' }
    }
    
    if ($topFolder -match '^Pres.*o$') {
        $type = 'pressao'
        $brand = "Press$([char]0x00E3)o"
        # We WANT them in the 'pressao' category for the dedicated tab
        $categoryKey = 'pressao'
    } elseif ($categoryKey -eq 'cervejas' -and $type -ne 'pressao') {
        $type = 'engarrafada'
    }
    
    if ($topFolder -eq 'Refrigerantes') {
        if ($relPath -match 'Compal' -or $relPath -match 'Super Bock Group') {
            $categoryKey = 'nectares'
        }
    }
    
    if ($categoryKey -eq 'cafes' -and $relPath -match 'Latic.nios') {
        $categoryKey = 'laticinios'
    }

    if ($categoryKey -eq 'alimentares' -and $relPath -match 'Azeite, .*leo, Vinagre') {
        $categoryKey = 'azeites'
    }
    
    # Manual path construction to match JS output (forward slashes)
    $imgPath = "produtos/" + (($parts | ForEach-Object { [uri]::EscapeDataString($_) }) -join "/")

    if (-not $db.ContainsKey($categoryKey)) {
        $db[$categoryKey] = @{ title = $categoryKey; files = @() }
    }
    
    $itemData = @{
        img = $imgPath
        name = Get-Name($f)
        brand = Invoke-StringCleanup($brand)
        type = $type
        hierarchy = ($hierarchy -split " > " | ForEach-Object { Invoke-StringCleanup($_) }) -join " > "
    }

    $db[$categoryKey].files += $itemData

    # Special duplication for Pressão: also add to cervejas category if it was mapped to pressao
    if ($categoryKey -eq 'pressao') {
        if (-not $db.ContainsKey('cervejas')) { $db['cervejas'] = @{ title = $titles['cervejas']; files = @() } }
        $db['cervejas'].files += $itemData
    }
}

$json = $db | ConvertTo-Json -Depth 10 -Compress
$content = "window.productsDB = $json;"
# Using UTF8NoBOM to be safe for browsers
$utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($outputFile, $content, $utf8NoBOM)

Write-Host "Successfully generated productsDB.js with $($files.Count) items."
