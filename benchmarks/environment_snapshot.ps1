param(
    [string]$OdysseusRepo = "D:\Projects\odysseus\odysseus",
    [string]$ChromaPython = "D:\Projects\odysseus\chroma-venv\Scripts\python.exe"
)

$ErrorActionPreference = "Continue"

$OutputDir = Join-Path $PSScriptRoot "..\results"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$TxtFile  = Join-Path $OutputDir "environment_snapshot.txt"
$JsonFile = Join-Path $OutputDir "environment_snapshot.json"

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

Write-Host ""
Write-Host "============================================"
Write-Host " ODYSSEUS EVALUATION - ENVIRONMENT SNAPSHOT"
Write-Host "============================================"
Write-Host ""

# ------------------------------------------------------------
# OPERATING SYSTEM
# ------------------------------------------------------------

$os = Get-CimInstance Win32_OperatingSystem

# ------------------------------------------------------------
# CPU
# ------------------------------------------------------------

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

# ------------------------------------------------------------
# MEMORY
# ------------------------------------------------------------

$totalRamGB = [math]::Round(
    $os.TotalVisibleMemorySize / 1MB,
    2
)

$freeRamGB = [math]::Round(
    $os.FreePhysicalMemory / 1MB,
    2
)

# ------------------------------------------------------------
# GPU
# ------------------------------------------------------------

$gpuRaw = ""

try {
    $gpuRaw = (
        nvidia-smi `
            --query-gpu=name,driver_version,memory.total `
            --format=csv,noheader 2>&1 |
        Out-String
    ).Trim()
}
catch {
    $gpuRaw = "nvidia-smi unavailable"
}

# ------------------------------------------------------------
# ODYSSEUS PYTHON
# ------------------------------------------------------------

$OdysseusPython = Join-Path $OdysseusRepo "venv\Scripts\python.exe"

$pythonVersion = ""
$pythonExecutable = ""

if (Test-Path $OdysseusPython) {

    $pythonVersion = (
        & $OdysseusPython --version 2>&1 |
        Out-String
    ).Trim()

    $pythonExecutable = (
        & $OdysseusPython -c "import sys; print(sys.executable)" 2>&1 |
        Out-String
    ).Trim()
}
else {
    $pythonVersion = "Odysseus Python not found"
    $pythonExecutable = "Not found"
}

# ------------------------------------------------------------
# OLLAMA
# ------------------------------------------------------------

$ollamaVersion = ""
$ollamaApiVersion = ""
$ollamaList = ""
$ollamaPs = ""

try {
    $ollamaVersion = (
        ollama --version 2>&1 |
        Out-String
    ).Trim()
}
catch {
    $ollamaVersion = "Ollama command unavailable"
}

try {
    $ollamaApiVersion = (
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:11434/api/version" `
            -Method Get
    ).version
}
catch {
    $ollamaApiVersion = "Ollama API unavailable"
}

try {
    $ollamaList = (
        ollama list 2>&1 |
        Out-String
    ).Trim()
}
catch {
    $ollamaList = "Unable to query Ollama models"
}

try {
    $ollamaPs = (
        ollama ps 2>&1 |
        Out-String
    ).Trim()
}
catch {
    $ollamaPs = "Unable to query loaded Ollama models"
}

# ------------------------------------------------------------
# CHROMADB
# ------------------------------------------------------------

$chromaVersion = ""

if (Test-Path $ChromaPython) {
    $chromaVersion = (
        & $ChromaPython `
            -c "import chromadb; print(chromadb.__version__)" 2>&1 |
        Out-String
    ).Trim()
}
else {
    $chromaVersion = "Chroma Python environment not found"
}

# ------------------------------------------------------------
# GIT / ODYSSEUS
# ------------------------------------------------------------

$gitBranch = ""
$gitCommit = ""
$gitStatus = ""
$gitState = ""

if (Test-Path $OdysseusRepo) {

    Push-Location $OdysseusRepo

    try {
        $gitBranch = (git branch --show-current).Trim()
        $gitCommit = (git rev-parse HEAD).Trim()
        $gitStatus = (git status --short | Out-String).Trim()

        if ([string]::IsNullOrWhiteSpace($gitStatus)) {
            $gitState = "CLEAN"
        }
        else {
            $gitState = "DIRTY"
        }
    }
    finally {
        Pop-Location
    }
}
else {
    $gitBranch = "Repository not found"
    $gitCommit = "Repository not found"
    $gitState = "UNKNOWN"
}

# ------------------------------------------------------------
# STRUCTURED SNAPSHOT
# ------------------------------------------------------------

$snapshot = [ordered]@{

    timestamp = $timestamp

    operating_system = [ordered]@{
        caption      = $os.Caption
        version      = $os.Version
        build_number = $os.BuildNumber
    }

    cpu = [ordered]@{
        name                = $cpu.Name.Trim()
        cores               = $cpu.NumberOfCores
        logical_processors  = $cpu.NumberOfLogicalProcessors
    }

    memory = [ordered]@{
        total_ram_gb = $totalRamGB
        free_ram_gb  = $freeRamGB
    }

    gpu = [ordered]@{
        nvidia_smi = $gpuRaw
    }

    python = [ordered]@{
        version    = $pythonVersion
        executable = $pythonExecutable
    }

    ollama = [ordered]@{
        cli_version = $ollamaVersion
        api_version = $ollamaApiVersion
    }

    chromadb = [ordered]@{
        version = $chromaVersion
    }

    odysseus = [ordered]@{
        repository = $OdysseusRepo
        branch     = $gitBranch
        commit     = $gitCommit
        git_state  = $gitState
    }
}

# ------------------------------------------------------------
# JSON OUTPUT
# ------------------------------------------------------------

$snapshot |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -Path $JsonFile `
        -Encoding UTF8

# ------------------------------------------------------------
# HUMAN-READABLE OUTPUT
# ------------------------------------------------------------

$report = @"

ODYSSEUS LOCAL AI WINDOWS EVALUATION
====================================

Snapshot time
-------------
$timestamp


OPERATING SYSTEM
----------------
Caption : $($os.Caption)
Version : $($os.Version)
Build   : $($os.BuildNumber)


CPU
---
Name                : $($cpu.Name.Trim())
Physical cores      : $($cpu.NumberOfCores)
Logical processors  : $($cpu.NumberOfLogicalProcessors)


SYSTEM MEMORY
-------------
Total RAM : $totalRamGB GB
Free RAM  : $freeRamGB GB


GPU
---
$gpuRaw


PYTHON
------
Version    : $pythonVersion
Executable : $pythonExecutable


OLLAMA
------
CLI version : $ollamaVersion
API version : $ollamaApiVersion


INSTALLED OLLAMA MODELS
-----------------------
$ollamaList


CURRENTLY LOADED OLLAMA MODELS
------------------------------
$ollamaPs


CHROMADB
--------
Version : $chromaVersion


ODYSSEUS GIT
------------
Repository : $OdysseusRepo
Branch     : $gitBranch
Commit     : $gitCommit
Git state  : $gitState

"@

$report |
    Set-Content `
        -Path $TxtFile `
        -Encoding UTF8

Write-Host $report

Write-Host ""
Write-Host "Snapshot files created:"
Write-Host "  $TxtFile"
Write-Host "  $JsonFile"
Write-Host ""
