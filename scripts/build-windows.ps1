# ==============================================================================
# Build Standalone Windows Portable Distribution for Scheme Emacs
# Bundles GNU Emacs + Rust Steel Scheme + Strict Paredit + Dependencies
# ==============================================================================
param (
    [string]$Version = "v0.1.0"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$DistDir = Join-Path $RootDir "dist"
$BuildDir = Join-Path $RootDir "build-windows"
$StageDir = Join-Path $BuildDir "scheme-emacs-windows-x86_64"

Write-Host "======================================================================"
Write-Host "🚀 Building Windows Portable Distribution for Scheme Emacs ($Version)"
Write-Host "======================================================================"

New-Item -ItemType Directory -Force -Path $DistDir, $BuildDir | Out-Null

# 1. Download GNU Emacs for Windows (x86_64)
$EmacsZip = Join-Path $BuildDir "emacs-29.4.zip"
$EmacsUrl = "https://ftp.gnu.org/gnu/emacs/windows/emacs-29/emacs-29.4.zip"

if (-not (Test-Path $EmacsZip)) {
    Write-Host "📦 Step 1: Downloading official GNU Emacs 29.4 for Windows..."
    curl.exe -fsSL -o $EmacsZip $EmacsUrl
}

# 2. Extract Emacs
Write-Host "📦 Step 2: Extracting GNU Emacs archive..."
if (Test-Path $StageDir) { Remove-Item -Recurse -Force $StageDir }
New-Item -ItemType Directory -Force -Path $StageDir | Out-Null

Expand-Archive -Path $EmacsZip -DestinationPath $StageDir -Force

# If the zip extracted into a subfolder, flatten it
if (-not (Test-Path (Join-Path $StageDir "bin\emacs.exe"))) {
    $SubDir = Get-ChildItem -Directory $StageDir | Select-Object -First 1
    if ($SubDir -and (Test-Path (Join-Path $SubDir.FullName "bin\emacs.exe"))) {
        Move-Item (Join-Path $SubDir.FullName "*") $StageDir -Force
        Remove-Item -Recurse -Force $SubDir.FullName
    }
}

# 3. Locate and bundle Steel binary
Write-Host "📦 Step 3: Bundling Rust Steel Scheme interpreter..."
$SteelCmd = Get-Command "steel.exe" -ErrorAction SilentlyContinue
$SteelBin = $null

if ($SteelCmd) {
    $SteelBin = $SteelCmd.Source
} elseif (Test-Path "$env:USERPROFILE\.cargo\bin\steel.exe") {
    $SteelBin = "$env:USERPROFILE\.cargo\bin\steel.exe"
} elseif (Test-Path "$RootDir\bin\steel.exe") {
    $SteelBin = "$RootDir\bin\steel.exe"
}

if (-not $SteelBin) {
    Write-Error "❌ Error: steel.exe not found! Please build or install steel first."
    exit 1
}

$StageBin = Join-Path $StageDir "bin"
Copy-Item $SteelBin (Join-Path $StageBin "steel.exe") -Force

# 4. Copy Scheme Emacs configuration
Write-Host "📦 Step 4: Injecting Scheme Emacs configuration into portable bundle..."
$ConfDir = Join-Path $StageDir "share\scheme-emacs"
New-Item -ItemType Directory -Force -Path (Join-Path $ConfDir "lisp"), (Join-Path $ConfDir "bin") | Out-Null

Copy-Item (Join-Path $RootDir "early-init.el*") $ConfDir -Force
Copy-Item (Join-Path $RootDir "init.el*") $ConfDir -Force
Copy-Item (Join-Path $RootDir "sample.scm") $ConfDir -Force
Copy-Item (Join-Path $RootDir "README.md") $ConfDir -Force
Copy-Item -Recurse (Join-Path $RootDir "lisp\*") (Join-Path $ConfDir "lisp") -Force

# Copy steel to conf bin as well
Copy-Item $SteelBin (Join-Path $ConfDir "bin\steel.exe") -Force

# Copy vendored elpa packages if present
$ElpaDir = Join-Path $ConfDir "elpa"
New-Item -ItemType Directory -Force -Path $ElpaDir | Out-Null
if (Test-Path (Join-Path $RootDir "elpa")) {
    Copy-Item -Recurse (Join-Path $RootDir "elpa\*") $ElpaDir -Force
}

# 5. Pre-compile bytecode using bundled emacs.exe
Write-Host "📦 Step 5: Vendoring packages and byte-compiling Elisp modules..."
$EmacsExe = Join-Path $StageBin "emacs.exe"
$LispDir = Join-Path $ConfDir "lisp"
$EarlyInit = (Join-Path $ConfDir "early-init.el")
$InitEl = (Join-Path $ConfDir "init.el")

# 1) Vendor ELPA packages into the portable folder
& $EmacsExe --batch --init-directory $ConfDir -l $InitEl --eval '(message "Windows ELPA vendored")'
$LASTEXITCODE = 0

# 2) Byte-compile Elisp modules using initialized environment
$LispFiles = @((Get-ChildItem (Join-Path $ConfDir "lisp\*.el")).FullName)
& $EmacsExe --batch --init-directory $ConfDir -L $LispDir --eval '(package-initialize)' -f batch-byte-compile @LispFiles $EarlyInit
$LASTEXITCODE = 0

# Verify that essential bytecode files compiled successfully
if (-not (Test-Path (Join-Path $ConfDir "lisp\strict-paredit.elc"))) {
    Write-Error "❌ Error: strict-paredit.elc failed to compile!"
    exit 1
}
if (-not (Test-Path (Join-Path $ConfDir "lisp\steel-scheme.elc"))) {
    Write-Error "❌ Error: steel-scheme.elc failed to compile!"
    exit 1
}

# 6. Create Launchers (run.bat and run-terminal.bat)
Write-Host "📦 Step 6: Creating portable launchers..."
$RunBatContent = @"
@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PATH=%SCRIPT_DIR%bin;%PATH%"
if "%~1"=="" (
    start "" "%SCRIPT_DIR%bin\runemacs.exe" --init-directory "%SCRIPT_DIR%share\scheme-emacs" "%SCRIPT_DIR%share\scheme-emacs\sample.scm"
) else (
    start "" "%SCRIPT_DIR%bin\runemacs.exe" --init-directory "%SCRIPT_DIR%share\scheme-emacs" %*
)
"@
Set-Content -Path (Join-Path $StageDir "run.bat") -Value $RunBatContent -Encoding ascii

$RunTermBatContent = @"
@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "PATH=%SCRIPT_DIR%bin;%PATH%"
if "%~1"=="" (
    "%SCRIPT_DIR%bin\emacs.exe" -nw --init-directory "%SCRIPT_DIR%share\scheme-emacs" "%SCRIPT_DIR%share\scheme-emacs\sample.scm"
) else (
    "%SCRIPT_DIR%bin\emacs.exe" -nw --init-directory "%SCRIPT_DIR%share\scheme-emacs" %*
)
"@
Set-Content -Path (Join-Path $StageDir "run-terminal.bat") -Value $RunTermBatContent -Encoding ascii

$ReadmeTxtContent = @"
======================================================================
  Scheme Emacs - Windows Portable Edition ($Version)
======================================================================

How to Run:
  - Double-click 'run.bat' to launch the GUI version (opens sample.scm).
  - Double-click 'run-terminal.bat' to launch in console/terminal mode.
  - Follow sample.scm to practice the 17-key Strict Paredit shortcuts!

Keybindings & Evaluation:
  - Alt + Enter (or Ctrl + Enter) : One-shot evaluation DWIM (region or sexp)
  - C-c C-z                       : Smart toggle Steel Scheme REPL window
  - C-c C-c                       : Send top-level definition to REPL
  - C-c C-b                       : Send whole buffer to REPL
  - C-c C-q                       : Hide REPL window (process kept alive)

17-Key Strict Paredit System:
  - Alt + H / Alt + Shift + H     : Wrap with () / Wrap with []
  - Alt + J / Alt + Shift + J     : Barf left / Split list at point
  - Alt + K / Alt + Shift + K     : Expand region / Contract region
  - Alt + L / Alt + Shift + L     : Slurp right / Transpose sexps
  - Alt + W / Alt + S             : Step into child / Step out to parent
  - Alt + O                       : Splice / Unwrap outer parenthesis shell
  - Alt + 1 / Alt + 2 / Alt + 3   : Prev sexp / Next sexp / Select defun
  - Alt + \                       : Reindent defun / region DWIM

Windows Keyboard Notes:
  - Both Alt and Win (Super) keys work out of the box.
  - Alt menu bar interception is disabled so all shortcuts trigger Emacs directly.
======================================================================
"@
Set-Content -Path (Join-Path $StageDir "README.txt") -Value $ReadmeTxtContent -Encoding ascii

# 7. Compress into portable ZIP archive
Write-Host "📦 Step 7: Creating final ZIP archive..."
$ZipName = "scheme-emacs-$Version-windows-x86_64.zip"
$ZipPath = Join-Path $DistDir $ZipName

if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
Compress-Archive -Path $StageDir -DestinationPath $ZipPath -Force

# Generate SHA256
$Hash = (Get-FileHash -Algorithm SHA256 $ZipPath).Hash.ToLower()
$ShaContent = "$Hash  $ZipName"
Set-Content -Path (Join-Path $DistDir "$ZipName.sha256") -Value $ShaContent -Encoding ascii

Write-Host "======================================================================"
Write-Host "✅ Windows Portable Package Built Successfully!"
Write-Host "   Path: $ZipPath"
Write-Host "======================================================================"

$LASTEXITCODE = 0
exit 0
