$text = (Get-Content productsDB.js -Raw -Encoding UTF8) -replace '^window\.productsDB = ', '' -replace ';$', ''
$json = ConvertFrom-Json -InputObject $text
$vinhos = $json.vinhos.files
Write-Host "Total Vinhos: $($vinhos.Count)"
foreach ($v in $vinhos) {
    Write-Host "Name: $($v.name) - Hierarchy: $($v.hierarchy) - Brand: $($v.brand)"
}
