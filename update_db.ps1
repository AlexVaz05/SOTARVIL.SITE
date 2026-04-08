# PowerShell Script to Update Products Database with Sub-categories
# Run this script whenever you add or move images in the 'produtos' folder.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$baseDir = "C:\Users\vazfa\.gemini\antigravity\scratch\sotarvil"
$produtosDir = Join-Path $baseDir "produtos"
$outputFile = Join-Path $baseDir "productsDB.js"

# Title mappings for clean display
$titles = @{
    "cervejas"         = "Cervejas"
    "aguas"            = "Aguas"
    "refrigerantes"    = "Refrigerantes"
    "nectares"         = "Nectares e Sumos"
    "cafes"            = "Cafes e Bebidas Quentes"
    "bebidas-brancas"  = "Bebidas Brancas"
    "vinhos"           = "Vinhos"
    "espumantes"       = "Espumantes"
    "champanhes"       = "Champanhes"
    "alimentares"      = "Produtos Alimentares"
    "detergentes"      = "Detergentes"
    "energeticos"      = "Energeticos"
    "sidras"           = "Sidras"
    "laticinios"       = "Laticinios"
    "pressao"          = "Cerveja de Pressao"
    "la-casera"        = "La Casera"
    "azeites"          = "Azeites, Oleos e Vinagres"
}

function Get-ProductBrand {
    param($parts, $prodName, $catName)
    $brand = if ($parts.Count -ge 3) { $parts[$parts.Count-2] } else { $catName }
    if ($parts.Count -ge 4 -and $brand -eq "engarrafadas") { $brand = $parts[$parts.Count-3] }

    if ($brand -eq "engarrafadas" -or $brand -eq "Geral" -or $brand -eq "Alimentares") {
        if ($prodName -match "Super Bock") { return "Super Bock" }
        if ($prodName -match "Sagres") { return "Sagres" }
        if ($prodName -match "Somersby") { return "Somersby" }
        if ($prodName -match "Carlsberg") { return "Carlsberg" }
        if ($prodName -match "Compal") { return "Compal" }
        if ($prodName -match "Luso") { return "Luso" }
        if ($prodName -match "Vitalis") { return "Vitalis" }
        if ($prodName -match "Castello") { return "Castello" }
    }
    return $brand
}

$db = New-Object System.Collections.Hashtable
foreach ($key in $titles.Keys) {
    $db[$key] = @{
        "title" = $titles[$key]
        "files" = New-Object System.Collections.Generic.List[PSObject]
    }
}

# Map actual folder names to category keys in the database
# Using [char] escapes to avoid encoding issues (file has no UTF-8 BOM)
$folderToKey = @{
    "cervejas"                 = "cervejas"
    "Champanhes"               = "champanhes"
    "Detergentes"              = "detergentes"
    "Espumantes"               = "espumantes"
    "Refrigerantes"            = "refrigerantes"
    "Sidras"                   = "sidras"
    "Vinhos"                   = "vinhos"
    "Press$([char]0x00E3)o"    = "pressao"
    "$([char]0x00C1)guas"      = "aguas"
    "Bebidas Brancas"          = "bebidas-brancas"
    "Bebidas Quentes e Caf$([char]0x00E9)s" = "cafes"
    "Energ$([char]0x00E9)ticos" = "energeticos"
    "La Casera"                = "la-casera"
    "Produtos Alimentares"     = "alimentares"
}

$tempDb = @{} # Category -> List of product IDs in order
$productDetails = @{} # ProductID -> Object
$totalFilesFound = 0

foreach ($itemCategory in Get-ChildItem -Path $produtosDir -Directory) {
    $itemCategoryKey = if ($folderToKey.ContainsKey($itemCategory.Name)) { $folderToKey[$itemCategory.Name] } else { $itemCategory.Name.ToLower() }
    if (-not $db.ContainsKey($itemCategoryKey)) { continue }
    if (-not $tempDb.ContainsKey($itemCategoryKey)) { $tempDb[$itemCategoryKey] = New-Object System.Collections.Generic.List[string] }

    # Pre-map subfolders for grouping logic
    $groupFolders = @{}
    foreach ($fold in Get-ChildItem -Path $itemCategory.FullName -Directory -Recurse) {
        $cleanName = $fold.Name.Replace("_", " ").Replace("-", " ").Trim().ToLower()
        $groupFolders[$cleanName] = $fold.FullName
    }

    foreach ($item in Get-ChildItem -Path $itemCategory.FullName -Recurse) {
        $relPath = ($item.FullName.Replace($produtosDir + "\", "")).Replace("\", "/")
        $parts = $relPath.Split("/")
        
        # Determine if it's a variant (inside a product folder)
        $isVariant = ($parts.Count -ge 4 -and $itemCategoryKey -ne "vinhos")
        if ($itemCategoryKey -eq "aguas" -and ($relPath -match "Com Sabor" -or $relPath -match "Sem Sabor")) {
            $isVariant = $false
        }
        $productID = if ($isVariant) { $parts[0..($parts.Count-2)] -join "/" } else { $relPath }

        # Extract hierarchy
        $hierarchy = "Geral"
        if ($itemCategoryKey -eq "vinhos" -or $itemCategoryKey -eq "aguas") {
            if ($parts.Count -ge 3) {
                $offset = if ($item.PSIsContainer) { 1 } else { 2 }
                if ($offset -lt $parts.Count) {
                    $subFolds = $parts[1..($parts.Count - $offset)]
                    $hierarchy = $subFolds -join " > "
                }
            }
        } else {
            $hierarchy = if ($parts.Count -ge 3) { $parts[1] } else { "Geral" }
        }

        if ($item.PSIsContainer) {
            # Folder-based product grouping (for products with multiple sizes)
            if (($isVariant -or $parts.Count -eq 3) -and $itemCategoryKey -ne "vinhos" -and $itemCategoryKey -ne "aguas") {
                if (-not $productDetails.ContainsKey($productID)) {
                    $prodName = (Get-Culture).TextInfo.ToTitleCase($item.Name.Replace("_", " ").ToLower())
                    $calcBrand = Get-ProductBrand -parts $parts -prodName $prodName -catName $itemCategoryKey
                    
                    $pData = @{}
                    $pData["name"] = $prodName
                    $pData["brand"] = $calcBrand
                    $pData["hierarchy"] = $hierarchy
                    $pData["isGroup"] = $true
                    $pData["variants"] = New-Object System.Collections.Generic.List[PSObject]
                    $pData["img"] = ""
                    $pData["cat"] = $itemCategoryKey
                    
                    $productDetails[$productID] = $pData
                    $tempDb[$itemCategoryKey].Add($productID)
                }
            }
            continue
        }

        if ($item.Extension -notmatch "\.(png|jpg|jpeg|webp|gif)$") { continue }

        if ($isVariant) {
            if (-not $productDetails.ContainsKey($productID)) {
                $pName = (Get-Culture).TextInfo.ToTitleCase($parts[-2].Replace("_", " ").ToLower())
                $pBrand = Get-ProductBrand -parts $parts -prodName $pName -catName $itemCategoryKey
                
                $pData = @{}
                $pData["name"] = $pName
                $pData["brand"] = $pBrand
                $pData["hierarchy"] = $hierarchy
                $pData["isGroup"] = $true
                $pData["variants"] = New-Object System.Collections.Generic.List[PSObject]
                $pData["img"] = ""
                $pData["cat"] = $itemCategoryKey
                
                $productDetails[$productID] = $pData
                $tempDb[$itemCategoryKey].Add($productID)
            }
            
            $variantName = $item.BaseName -replace "[_-]", " "
            $variantName = (Get-Culture).TextInfo.ToTitleCase($variantName.ToLower())
            $prodNameRef = $productDetails[$productID].name
            $variantCleanName = $variantName -replace "(?i)$prodNameRef", "" 
            $variantCleanName = $variantCleanName -replace "^\d+[\s\-_.]+(?!\d*,?\d+\s*(cl|l|g|kg|ml)\b)", ""
            
            $noiseWords = "[\u00c1A]gua[s]?|do|da|de|das|dos|com|sem|sabor"
            $variantCleanName = ($variantCleanName -replace "(?i)\b($noiseWords)\b", "").Trim()
            
            if ($itemCategoryKey -eq "aguas" -and $variantCleanName -match "^\d+$" -and $variantCleanName -eq "33") {
                $variantCleanName = $variantCleanName + "Cl"
            }
            if (-not $variantCleanName) { $variantCleanName = $variantName }

            $variant = @{
                "name" = $variantCleanName
                "img" = "produtos/" + [Uri]::EscapeDataString($relPath).Replace("%2F", "/")
            }
            $productDetails[$productID].variants.Add($variant)
            if ($productDetails[$productID].img -eq "" -or $item.Name -match "33cl") {
                $productDetails[$productID].img = $variant.img
            }
        } else {
            $cleanFileName = $item.BaseName -replace "^\d+[\s\-_.]*", ""
            $normFileName = $cleanFileName.Replace("_", " ").Replace("-", " ").Trim().ToLower()
            if ($groupFolders.ContainsKey($normFileName)) { continue }

            if (-not $productDetails.ContainsKey($productID)) {
                $totalFilesFound++
                $pName = $item.BaseName -replace "[_-]", " "
                $pName = (Get-Culture).TextInfo.ToTitleCase($pName.ToLower())
                $pBrand = Get-ProductBrand -parts $parts -prodName $pName -catName $itemCategoryKey
                
                $pData = @{}
                $pData["img"] = "produtos/" + [Uri]::EscapeDataString($relPath).Replace("%2F", "/")
                $pData["name"] = $pName
                $pData["brand"] = $pBrand
                $pData["hierarchy"] = $hierarchy
                $pData["cat"] = $itemCategoryKey
                
                $productDetails[$productID] = $pData
                $tempDb[$itemCategoryKey].Add($productID)
            }
        }
    }
}

$descFile = Join-Path $baseDir "descriptions.json"
$descBase = $null
if (Test-Path $descFile) {
    $descBase = Get-Content $descFile -Raw -Encoding UTF8 | ConvertFrom-Json
}

Write-Host "Assembling final database..."
foreach ($catKey in $tempDb.Keys) {
    $sortedProdIDs = $tempDb[$catKey]

    if ($catKey -eq "cervejas") {
        $sbOriginalID = ""
        foreach ($id in $sortedProdIDs) { if ($id -match "Super Bock Original") { $sbOriginalID = $id; break } }
        if ($sbOriginalID) { 
            $sortedProdIDs.Remove($sbOriginalID) | Out-Null
            $sortedProdIDs.Insert(0, $sbOriginalID) 
        }
    }

    foreach ($prodID in $sortedProdIDs) {
        $p = $productDetails[$prodID]
        if ($null -eq $p) { continue }
        $p["type"] = ""
        $p["subCategory"] = ""
        $description = ""

        if ($null -ne $descBase) {
            $effectiveCat = $catKey
            if ($prodID -match "Latic") { $effectiveCat = "laticinios" }

            if ($descBase.PSObject.Properties.Name -contains "products") {
                $prodKeys = $descBase.products.PSObject.Properties.Name | Sort-Object { $_.Length } -Descending
                $pNameNorm = $p.name.ToLower().Replace("-", " ") -replace "\s+", " "
                foreach ($prodKey in $prodKeys) {
                    $kNorm = $prodKey.ToLower().Replace("-", " ") -replace "\s+", " "
                    if ($pNameNorm.Contains($kNorm)) { 
                        $description = $descBase.products.$prodKey
                        break 
                    }
                }
            }
            if (-not $description -and $descBase.PSObject.Properties.Name -contains "brands" -and $p.brand) {
                $bNameNorm = $p.brand.ToString().ToLower().Replace("-", " ") -replace "\s+", " "
                $brandKeys = $descBase.brands.PSObject.Properties.Name
                foreach ($bKey in $brandKeys) {
                    $bkNorm = $bKey.ToLower().Replace("-", " ") -replace "\s+", " "
                    if ($bkNorm -eq $bNameNorm) {
                        $description = $descBase.brands.$bKey
                        break
                    }
                }
            }
            if (-not $description -and $descBase.PSObject.Properties.Name -contains "categories") {
                if ($descBase.categories.PSObject.Properties.Name -contains $effectiveCat) {
                    $description = $descBase.categories.$effectiveCat
                }
            }
        }
        if (-not $description) { $description = "Produto premium distribuido pela Sotarvil." }
        $p["desc"] = $description

        if ($catKey -eq "aguas") {
            if ($prodID -match "Lisas") { $p["type"] = "lisa"; $p["subCategory"] = "Aguas Lisas" }
            elseif ($prodID -match "Com Sabor") { $p["type"] = "gas-com-sabor"; $p["subCategory"] = "Aguas Gaseificadas com Sabor" }
            elseif ($prodID -match "Sem Sabor") { $p["type"] = "gas-sem-sabor"; $p["subCategory"] = "Aguas Gaseificadas Naturais" }
        }
        elseif ($catKey -eq "pressao") {
            $p["type"] = "pressao"; $p["subCategory"] = "Cerveja de Pressao"; $p["brand"] = "Super Bock Group"
        }
        
        $targetCat = $catKey
        if ($catKey -eq "cafes" -and $prodID -match "Latic") { $targetCat = "laticinios" }
        if ($catKey -eq "alimentares" -and $prodID -match "Azeite") { $targetCat = "azeites" }
        
        if ($db.ContainsKey($targetCat)) {
            $db[$targetCat].files.Add($p)
        }
    }
}

if ($null -ne $db["refrigerantes"]) {
    $toNectares = $db["refrigerantes"].files | Where-Object { $_.img -match "Compal" -or $_.img -match "Super%20Bock%20Group" }
    foreach ($itm in $toNectares) { $db["nectares"].files.Add($itm) }
    $remainingRefres = $db["refrigerantes"].files | Where-Object { $_.img -notmatch "Compal" -and $_.img -notmatch "Super%20Bock%20Group" }
    $db["refrigerantes"].files = [System.Collections.Generic.List[PSObject]]@($remainingRefres)
}

$json = $db | ConvertTo-Json -Depth 10
$finalContent = "window.productsDB = " + $json + ";"
[System.IO.File]::WriteAllText($outputFile, $finalContent, [System.Text.Encoding]::UTF8)

Write-Host "Database updated successfully: $outputFile" -ForegroundColor Green
Write-Host "Files processed: $totalFilesFound" -ForegroundColor Cyan
