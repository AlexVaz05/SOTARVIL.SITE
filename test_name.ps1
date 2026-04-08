$item = Get-Item "produtos\Vinhos\Vinhos do Porto\Rozés"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($item.Name)
$hex = [System.BitConverter]::ToString($bytes)
Write-Host "Name: $($item.Name)"
Write-Host "Bytes: $hex"
