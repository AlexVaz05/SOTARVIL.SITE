Add-Type -AssemblyName System.Drawing

function Optimize-Image {
    param ($Path)
    $fullPath = Resolve-Path $Path -ErrorAction SilentlyContinue
    if (-Not $fullPath) {
        Write-Host "File not found: $Path"
        return
    }
    
    $fullPath = $fullPath.Path
    Write-Host "Processing $fullPath ..."

    $bmp = New-Object System.Drawing.Bitmap $fullPath
    $minX = $bmp.Width
    $minY = $bmp.Height
    $maxX = 0
    $maxY = 0

    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $pixel = $bmp.GetPixel($x, $y)
            if ($pixel.A -gt 10) { 
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($minX -lt $maxX -and $minY -lt $maxY) {
        $rect = New-Object System.Drawing.Rectangle($minX, $minY, ($maxX - $minX + 1), ($maxY - $minY + 1))
        $cropped = $bmp.Clone($rect, $bmp.PixelFormat)
        $bmp.Dispose()
        
        $newPath = $fullPath.Replace(".png", "_recortado.png")
        $cropped.Save($newPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $cropped.Dispose()
        Write-Host "Success: Created $newPath"
    } else {
        $bmp.Dispose()
        Write-Host "Failed: No visible pixels found."
    }
}

Optimize-Image ".\logo-secundario-escuro.png"
Optimize-Image ".\logo-principal-escuro.png"
Optimize-Image ".\logo-principal.png"
Optimize-Image ".\logo-simbolo-escuro.png"
