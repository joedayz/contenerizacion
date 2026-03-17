Param(
  [string]$ClusterName = "microservices"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script de apoyo para entornos Windows con Docker Desktop + kind.
# Para alumnos que usan solo el clúster de Docker Desktop (sin kind),
# basta con hacer 'docker build' como indica el README.

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir

$dir        = "expense-service"
$name       = "expense-service"
$dockerfile = "src/main/docker/Dockerfile.jvm"

Write-Host ""
Write-Host "=== Building $name in $dir ==="
Set-Location (Join-Path $RootDir $dir)

mvn -q package -DskipTests

$tag = "${name}:latest"

docker build -f $dockerfile -t $tag .

Write-Host "Loading $tag into kind cluster '$ClusterName'..."
kind load docker-image $tag --name $ClusterName

Write-Host ""
Write-Host "=== Done: $name loaded into kind cluster '$ClusterName' ==="
