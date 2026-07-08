# CloudRoute Lab - Infrastructure Blueprint to PDF Converter
# This script converts the HTML blueprint to PDF

Write-Host "CloudRoute Lab - Infrastructure Blueprint PDF Converter" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Check if the HTML file exists
$htmlFile = "E:\github\CloudRoute Lab\INFRASTRUCTURE_BLUEPRINT.html"
if (-not (Test-Path $htmlFile)) {
    Write-Host "Error: HTML file not found at $htmlFile" -ForegroundColor Red
    exit 1
}

Write-Host "HTML file found: $htmlFile" -ForegroundColor Green
Write-Host ""

# Method 1: Using wkhtmltopdf (if installed)
$wkhtmltopdfPath = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
if (Test-Path $wkhtmltopdfPath) {
    Write-Host "Using wkhtmltopdf to convert HTML to PDF..." -ForegroundColor Yellow
    $outputPdf = "E:\github\CloudRoute Lab\INFRASTRUCTURE_BLUEPRINT.pdf"
    
    try {
        & $wkhtmltopdfPath --enable-local-file-access --page-size A4 --margin-top 20mm --margin-bottom 20mm --margin-left 20mm --margin-right 20mm $htmlFile $outputPdf
        Write-Host "Successfully created PDF: $outputPdf" -ForegroundColor Green
    }
    catch {
        Write-Host "Error converting with wkhtmltopdf: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "wkhtmltopdf not found. Trying alternative methods..." -ForegroundColor Yellow
    Write-Host ""
    
    # Method 2: Using Chrome/Edge in headless mode
    $chromePaths = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    )
    
    $chromePath = $null
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            $chromePath = $path
            break
        }
    }
    
    if ($chromePath) {
        Write-Host "Using Chrome/Edge to convert HTML to PDF..." -ForegroundColor Yellow
        $outputPdf = "E:\github\CloudRoute Lab\INFRASTRUCTURE_BLUEPRINT.pdf"
        $htmlUrl = "file:///$($htmlFile -replace '\\', '/')"
        
        try {
            & $chromePath --headless --disable-gpu --no-sandbox --print-to-pdf=$outputPdf --print-to-pdf-no-header $htmlUrl
            Write-Host "Successfully created PDF: $outputPdf" -ForegroundColor Green
        }
        catch {
            Write-Host "Error converting with Chrome/Edge: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "No PDF conversion tool found." -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual conversion options:" -ForegroundColor Yellow
        Write-Host "1. Open INFRASTRUCTURE_BLUEPRINT.html in your browser" -ForegroundColor White
        Write-Host "2. Press Ctrl+P to print" -ForegroundColor White
        Write-Host "3. Select 'Save as PDF' as the printer" -ForegroundColor White
        Write-Host "4. Save as INFRASTRUCTURE_BLUEPRINT.pdf" -ForegroundColor White
        Write-Host ""
        Write-Host "Alternative: Install wkhtmltopdf from https://wkhtmltopdf.org/" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Conversion complete!" -ForegroundColor Cyan
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "- INFRASTRUCTURE_BLUEPRINT.md (Markdown version)" -ForegroundColor White
Write-Host "- INFRASTRUCTURE_BLUEPRINT.html (HTML version)" -ForegroundColor White
if (Test-Path "E:\github\CloudRoute Lab\INFRASTRUCTURE_BLUEPRINT.pdf") {
    Write-Host "- INFRASTRUCTURE_BLUEPRINT.pdf (PDF version)" -ForegroundColor Green
}
