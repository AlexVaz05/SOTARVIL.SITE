$item = Get-Item "produtos\Vinhos\Vinhos do Porto\Rozés"
$hierarchy = "Vinhos do Porto > " + $item.Name
$obj = @{ name = $item.Name; hierarchy = $hierarchy }
$json = $obj | ConvertTo-Json
[System.IO.File]::WriteAllText("test_out.json", $json, [System.Text.Encoding]::UTF8)
