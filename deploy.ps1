# Script de Deploy para Firebase
# Executa o build do Flutter e faz o deploy para o Firebase Hosting

Write-Host "Building Flutter web app..." -ForegroundColor Green
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "Copying files to Firebase public directory..." -ForegroundColor Green
    Set-Location "build\web"
    
    Copy-Item -Path "*.html", "*.js", "*.json", "favicon.png" -Destination "public" -Force
    Copy-Item -Path "assets", "canvaskit", "icons" -Destination "public" -Recurse -Force
    
    Write-Host "Deploying to Firebase..." -ForegroundColor Green
    firebase deploy
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deploy complete!" -ForegroundColor Green
        Write-Host "Your app is live at: https://bingofy-7b434.web.app" -ForegroundColor Cyan
    } else {
        Write-Host "Error during Firebase deploy!" -ForegroundColor Red
    }
} else {
    Write-Host "Error during Flutter build!" -ForegroundColor Red
}

Set-Location "..\..\"