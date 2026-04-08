Get-ChildItem -Path "produtos\Vinhos\Vinhos do Porto" | ForEach-Object {
    $name = $_.Name
    $title = (Get-Culture).TextInfo.ToTitleCase($name.ToLower())
    Write-Host "Name: $name -> TitleCase: $title"
}
