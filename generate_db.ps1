[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$htmlFile = "C:\Users\vazfa\.gemini\antigravity\scratch\sotarvil\categoria.html"
$imagesDir = "C:\Users\vazfa\.gemini\antigravity\scratch\sotarvil\produtos"

Write-Host "A ler imagens de $imagesDir"

$files = Get-ChildItem -Path $imagesDir -File | Where-Object { $_.Extension -match "\.(png|jpg|jpeg|webp|gif|heic)$" }

$cervejas = @()
$aguas = @()
$refrig = @()
$nectar = @()
$cafes = @()
$bebidas = @()
$espumantes = @()
$champ = @()
$alimentares = @()
$lat = @()
$vinhos = @()

foreach ($f in $files) {
    $n = $f.Name
    $nLower = $n.ToLower()
    $ext = $f.Extension
    
    $cleanName = $n.Substring(0, $n.Length - $ext.Length)
    
    # 1. Cleaning up the noise from the filenames
    $cleanName = $cleanName -replace '[-_]', ' '
    $cleanName = $cleanName -replace '(?i)\b(product|low|removebg|preview|frente|caixa|gift box|supreme|bottle spritz|front|color colletion|colors colection|coletion)\b', ''
    $cleanName = $cleanName -replace '(?i)^imagem \d{4} \d{2} \d{2} \d{9}', ''
    $cleanName = $cleanName -replace '(?i)^(1022|1040|158|98|2050223|2202675|88\.01054 01)', ''
    $cleanName = $cleanName -replace '(?i)@2x SchwSELECTION', 'Schweppes Selection'
    $cleanName = $cleanName -replace '\s+', ' '
    $cleanName = $cleanName.Trim()
    
    # 2. To Title Case
    $cleanName = (Get-Culture).TextInfo.ToTitleCase($cleanName.ToLower())
    
    $brand = "Sotarvil"
    if ($nLower -match 'alcool00' -or $nLower -match 'alcool 00') { $cleanName = "Super Bock 0.0" }
    elseif ($nLower -match 'guaraná') { $cleanName = "Guaraná Brasil" }
    elseif ($nLower -match 'coca cola') { $cleanName = "Coca-Cola" }
    
    # 3. Use "produtos" as base path and URI Encode the filename
    $safeN = [uri]::EscapeDataString($n)
    $imgPath = "produtos/$safeN"
    
    $obj = @{
        name = $cleanName
        img = $imgPath
        brand = $brand
    }
    
    if ($nLower -match "superbock|carlsberg|coruja|cheers|seleccao|grimbergen") { 
        $obj.brand = "Cervejas"
        if ($nLower -match "superbock") { $obj.Add("score", 100) }
        else { $obj.Add("score", 0) }
        $cervejas += $obj
    }
    elseif ($nLower -match "agua|pedras|caramulo|vitalis|vidago|castello") { 
        $obj.brand = "Águas"
        $aguas += $obj
    }
    elseif ($nLower -match "coca|guaraná|frisumo|snappy|schweppes|redbull|pepsi|7up|joi|ice|sprite|fanta") { 
        $obj.brand = "Refrigerantes"
        $refrig += $obj
    }
    elseif ($nLower -match "compal|sumol|frutea|frutis") { 
        $obj.brand = "Sumos e Néctares"
        $nectar += $obj
    }
    elseif ($nLower -match "delta|mokate|cafe|café") { 
        $obj.brand = "Cafés"
        $cafes += $obj
    }
    elseif ($nLower -match "brandy|aguardente|gin|vodka|absinto|licor|tequila|rum|whisky|ponche|amarguinha|baileys|martini|safari|amendoa|cachaça|favaios|crf|macieira|velho|chivas|cutty|cardhu|black|montanha|ros|per|lim|morang|apple|pes") { 
        $obj.brand = "Espirituosas"
        $bebidas += $obj
    }
    elseif ($nLower -match "murganheira|bruto|espumante|aliança|corte real|raposeira|fidalga|frisante|seco") { 
        $obj.brand = "Espumante"
        $espumantes += $obj
    }
    elseif ($nLower -match "pommery|demoiselle|champanhe|vranken") { 
        $obj.brand = "Champanhe"
        $champ += $obj
    }
    elseif ($nLower -match "gresso|ucal") { 
        $obj.brand = "Laticínios"
        $lat += $obj
    }
    elseif ($nLower -match "azeite|vinagre|flor|sal") { 
        $obj.brand = "Mercearia"
        $alimentares += $obj
    }
    else { 
        $obj.brand = "Caves e Vinhos"
        $vinhos += $obj
    }
}

# Sort cervejas
$cervejas = $cervejas | Sort-Object -Property @{Expression={$_.score}; Descending=$true}, @{Expression={$_.name}; Ascending=$true}
$cervejasFinal = @()
foreach ($c in $cervejas) {
    $cervejasFinal += @{ name = $c.name; img = $c.img; brand = $c.brand }
}

$db = @{
    cervejas = @{ title = 'Cervejas'; files = $cervejasFinal }
    aguas = @{ title = 'Águas'; files = $aguas }
    refrigerantes = @{ title = 'Refrigerantes'; files = $refrig }
    nectares = @{ title = 'Néctares'; files = $nectar }
    cafes = @{ title = 'Cafés'; files = $cafes }
    "bebidas-brancas" = @{ title = 'Bebidas Brancas'; files = $bebidas }
    vinhos = @{ title = 'Vinhos'; files = $vinhos }
    espumantes = @{ title = 'Espumantes'; files = $espumantes }
    champanhes = @{ title = 'Champanhes'; files = $champ }
    alimentares = @{ title = 'Produtos Alimentares'; files = $alimentares }
    laticinios = @{ title = 'Laticínios'; files = $lat }
}

$jsonDb = $db | ConvertTo-Json -Depth 5 -Compress

$utf8 = New-Object System.Text.UTF8Encoding $false
$htmlContent = [System.IO.File]::ReadAllText($htmlFile, $utf8)

$htmlContent = $htmlContent -replace '(?s)const productsDB = \{.*?\};', "const productsDB = $jsonDb;"

[System.IO.File]::WriteAllText($htmlFile, $htmlContent, $utf8)

Write-Host "Total imagens catalogadas: $($files.Count) de 'produtos'."
