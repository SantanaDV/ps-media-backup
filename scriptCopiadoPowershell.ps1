# === Configuración ===
$destRoot   = 'T:\Backup_FotosVideos_C'   # <-- cambia T: por la letra real del Toshiba
$sourceRoot = 'C:\'

# Extensiones a copiar
$imgExt = @('.jpg','.jpeg','.png','.gif','.bmp','.tif','.tiff','.webp',
            '.heic','.heif','.raw','.cr2','.nef','.arw','.rw2','.dng')
$vidExt = @('.mp4','.mov','.m4v','.avi','.wmv','.mkv','.mts','.m2ts','.3gp')
$wantedExt = ($imgExt + $vidExt | Select-Object -Unique)

# Carpetas a EXCLUIR para acelerar y evitar errores de permisos
$excludeDirs = @(
  'C:\Windows',
  'C:\Program Files',
  'C:\Program Files (x86)',
  'C:\ProgramData',
  'C:\PerfLogs',
  'C:\$Recycle.Bin',
  'C:\System Volume Information'
)

# --- utilidades ---
function In-ExcludedPath {
    param([string]$FullPath)
    foreach ($ex in $excludeDirs) {
        if ($FullPath.StartsWith($ex, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Get-UniquePath {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $Path }
    $dir  = Split-Path -Parent  $Path
    $name = Split-Path -Leaf    $Path
    $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
    $ext  = [System.IO.Path]::GetExtension($name)
    $i = 1
    do {
        $candidate = Join-Path $dir ("{0} ({1}){2}" -f $base,$i,$ext)
        $i++
    } until (-not (Test-Path -LiteralPath $candidate))
    return $candidate
}

# --- preparación ---
New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
$logPath = Join-Path $destRoot ("backup_fotos_videos_{0:yyyy-MM-dd_HHmmss}.log" -f (Get-Date))
"Inicio: $(Get-Date)" | Out-File -FilePath $logPath -Encoding UTF8
"Origen: $sourceRoot" | Tee-Object -FilePath $logPath -Append
"Destino: $destRoot"  | Tee-Object -FilePath $logPath -Append

Write-Host "Indexando archivos en $sourceRoot (esto puede tardar)..." -ForegroundColor Cyan

# Enumerar todos los ficheros y filtrar por extensión + exclusiones
$allFiles = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File -ErrorAction SilentlyContinue
$files = foreach ($f in $allFiles) {
    if ($null -ne $f.Extension) {
        $ext = $f.Extension.ToLowerInvariant()
        if ($wantedExt -contains $ext) {
            if (-not (In-ExcludedPath -FullPath $f.FullName)) { $f }
        }
    }
}

$total = $files.Count
if ($total -eq 0) {
    Write-Host "No se encontraron fotos/vídeos en C:\ con las extensiones definidas." -ForegroundColor Yellow
    "No se encontraron archivos objetivo." | Tee-Object -FilePath $logPath -Append
    return
}

Write-Host ("Se copiarán {0:n0} archivos." -f $total) -ForegroundColor Green

# --- bucle de copia con progreso y ETA ---
$start = Get-Date
$processed = 0
$filesCopied = 0
$filesSkipped = 0
$lastDirShown = ""

foreach ($f in $files) {
    $processed++

    try {
        # Ruta relativa respecto a C:\
        $rel = $f.FullName.Substring($sourceRoot.Length).TrimStart('\')
        $destPath = Join-Path $destRoot $rel
        $destDir  = Split-Path -Parent $destPath

        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        }

        $finalPath = Get-UniquePath -Path $destPath
        Copy-Item -LiteralPath $f.FullName -Destination $finalPath -ErrorAction Stop
        $filesCopied++
        "OK  -> $finalPath" | Tee-Object -FilePath $logPath -Append
    }
    catch {
        $filesSkipped++
        "ERR -> $($f.FullName) :: $($_.Exception.Message)" | Tee-Object -FilePath $logPath -Append
    }

    # --- progreso y ETA ---
    if ($processed -eq 1 -or ($processed % 50 -eq 0)) {
        $elapsed = (Get-Date) - $start
        $rate = if ($elapsed.TotalSeconds -gt 0) { $processed / $elapsed.TotalSeconds } else { 0 }
        $remaining = $total - $processed
        $etaSec = if ($rate -gt 0) { [int]([math]::Ceiling($remaining / $rate)) } else { -1 }

        $pct = [int]([math]::Floor(($processed / $total) * 100))
        $currentDir = Split-Path -Parent $f.FullName

        if ($currentDir -ne $lastDirShown) {
            Write-Host ("Procesando: {0}" -f $currentDir)
            $lastDirShown = $currentDir
        }

        Write-Progress -Activity "Copiando fotos y vídeos desde C:\" `
                        -Status ("Procesando: {0}" -f $currentDir) `
                        -PercentComplete $pct `
                        -SecondsRemaining $etaSec
    }
}

# Cerrar barra de progreso
Write-Progress -Activity "Copiando fotos y vídeos desde C:\" -Completed

"Fin: $(Get-Date)" | Tee-Object -FilePath $logPath -Append
"Copiados: $filesCopied | Omitidos: $filesSkipped | Total vistos: $total" | Tee-Object -FilePath $logPath -Append

Write-Host ""
Write-Host "Hecho. Revisa el backup en: $destRoot" -ForegroundColor Green
Write-Host "Log: $logPath"
