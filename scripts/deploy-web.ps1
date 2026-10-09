param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-fA-F0-9]{32}$')]
    [string]$SpotifyClientId
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$firebaseProject = 'bingusfy-rooms-20261008'
$spotifyRedirectUri = "https://$firebaseProject.web.app/"

Push-Location $projectRoot
try {
    & flutter build web --release "--dart-define=SPOTIFY_CLIENT_ID=$SpotifyClientId" "--dart-define=SPOTIFY_REDIRECT_URI=$spotifyRedirectUri"
    if ($LASTEXITCODE -ne 0) { throw 'O build do Flutter falhou. Nenhum deploy foi realizado.' }

    & npx --yes firebase-tools@15.33.0 deploy --only hosting --project $firebaseProject
    if ($LASTEXITCODE -ne 0) { throw 'O deploy do Firebase Hosting falhou.' }

    Write-Host "Site publicado: $spotifyRedirectUri"
    Write-Host "Cadastre essa mesma URL, incluindo a barra final, nas Redirect URIs do Spotify."
} finally {
    Pop-Location
}
