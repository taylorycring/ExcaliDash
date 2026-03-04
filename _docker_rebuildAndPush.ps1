#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Config ──────────────────────────────────────────────
$DOCKER_USERNAME = "taylor0225"
$BACKEND_IMAGE   = "$DOCKER_USERNAME/excalidash-backend"
$FRONTEND_IMAGE  = "$DOCKER_USERNAME/excalidash-frontend"

# ── Read version ────────────────────────────────────────
$VERSION = (Get-Content -Path "VERSION" -Raw).Trim()
if (-not $VERSION) {
    Write-Error "Cannot read version from VERSION file"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ExcaliDash Docker Builder" -ForegroundColor Cyan
Write-Host "  Version: $VERSION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Docker Hub login check ──────────────────────────────
Write-Host "[1/5] Checking Docker Hub authentication..." -ForegroundColor Yellow
$dockerInfo = docker info 2>&1 | Out-String
if ($dockerInfo -notmatch "Username") {
    Write-Host "Not logged in. Please login to Docker Hub:" -ForegroundColor Red
    docker login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker login failed"
        exit 1
    }
} else {
    Write-Host "Already logged in to Docker Hub." -ForegroundColor Green
}

# ── Build backend ───────────────────────────────────────
Write-Host ""
Write-Host "[2/5] Building backend image..." -ForegroundColor Yellow
Write-Host "  Tags: ${BACKEND_IMAGE}:${VERSION}, ${BACKEND_IMAGE}:latest"

docker build `
    --platform linux/amd64 `
    --tag "${BACKEND_IMAGE}:${VERSION}" `
    --tag "${BACKEND_IMAGE}:latest" `
    --file backend/Dockerfile `
    backend/

if ($LASTEXITCODE -ne 0) {
    Write-Error "Backend build failed"
    exit 1
}
Write-Host "Backend image built successfully." -ForegroundColor Green

# ── Build frontend ──────────────────────────────────────
Write-Host ""
Write-Host "[3/5] Building frontend image..." -ForegroundColor Yellow
Write-Host "  Tags: ${FRONTEND_IMAGE}:${VERSION}, ${FRONTEND_IMAGE}:latest"

docker build `
    --platform linux/amd64 `
    --tag "${FRONTEND_IMAGE}:${VERSION}" `
    --tag "${FRONTEND_IMAGE}:latest" `
    --build-arg "VITE_APP_VERSION=$VERSION" `
    --build-arg "VITE_APP_BUILD_LABEL=production" `
    --file frontend/Dockerfile `
    .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Frontend build failed"
    exit 1
}
Write-Host "Frontend image built successfully." -ForegroundColor Green

# ── Push backend ────────────────────────────────────────
Write-Host ""
Write-Host "[4/5] Pushing backend images..." -ForegroundColor Yellow

docker push "${BACKEND_IMAGE}:${VERSION}"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to push ${BACKEND_IMAGE}:${VERSION}"; exit 1 }

docker push "${BACKEND_IMAGE}:latest"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to push ${BACKEND_IMAGE}:latest"; exit 1 }

Write-Host "Backend images pushed successfully." -ForegroundColor Green

# ── Push frontend ───────────────────────────────────────
Write-Host ""
Write-Host "[5/5] Pushing frontend images..." -ForegroundColor Yellow

docker push "${FRONTEND_IMAGE}:${VERSION}"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to push ${FRONTEND_IMAGE}:${VERSION}"; exit 1 }

docker push "${FRONTEND_IMAGE}:latest"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to push ${FRONTEND_IMAGE}:latest"; exit 1 }

Write-Host "Frontend images pushed successfully." -ForegroundColor Green

# ── Done ────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  All images published successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Published images:" -ForegroundColor Cyan
Write-Host "  - ${BACKEND_IMAGE}:${VERSION}"
Write-Host "  - ${BACKEND_IMAGE}:latest"
Write-Host "  - ${FRONTEND_IMAGE}:${VERSION}"
Write-Host "  - ${FRONTEND_IMAGE}:latest"
Write-Host ""
Write-Host "[Deploy Reminder]" -ForegroundColor Yellow
Write-Host "  Use docker-compose.prod.yml with volume mount to persist SQLite data:"
Write-Host "    volumes:"
Write-Host "      - backend-data:/app/prisma"
Write-Host ""
Write-Host "  The entrypoint script will auto-run migrations and persist secrets."
Write-Host "  Database data survives container restarts as long as the volume exists."
Write-Host ""
