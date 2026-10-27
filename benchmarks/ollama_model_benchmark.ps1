param(
    [Parameter(Mandatory=$true)]
    [string]$Model,

    [int]$Context = 4096,

    [int]$Predict = 128,

    [string]$KeepAlive = "10m"
)

$ErrorActionPreference = "Stop"

$OutputDir = Join-Path $PSScriptRoot "..\results"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# ------------------------------------------------------------
# HELPERS
# ------------------------------------------------------------

function Get-FreeRamGB {

    $os = Get-CimInstance Win32_OperatingSystem

    return [math]::Round(
        $os.FreePhysicalMemory / 1MB,
        2
    )
}


function Get-GpuSnapshot {

    try {

        $raw = (
            nvidia-smi `
                --query-gpu=name,memory.used,memory.total,utilization.gpu,utilization.memory `
                --format=csv,noheader,nounits 2>&1 |
            Out-String
        ).Trim()

        $parts = $raw -split ","

        if ($parts.Count -ge 5) {

            return [ordered]@{
                name               = $parts[0].Trim()
                memory_used_mib    = [int]$parts[1].Trim()
                memory_total_mib   = [int]$parts[2].Trim()
                gpu_utilization_pct = [int]$parts[3].Trim()
                memory_utilization_pct = [int]$parts[4].Trim()
            }
        }

        return [ordered]@{
            raw = $raw
        }
    }
    catch {

        return [ordered]@{
            error = $_.Exception.Message
        }
    }
}


function Get-OllamaPsText {

    try {
        return (
            ollama ps 2>&1 |
            Out-String
        ).Trim()
    }
    catch {
        return "Unable to query ollama ps"
    }
}


# ------------------------------------------------------------
# CHECK OLLAMA
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================"
Write-Host " ODYSSEUS LOCAL MODEL BENCHMARK"
Write-Host "============================================"
Write-Host ""

Write-Host "Model       : $Model"
Write-Host "Context     : $Context"
Write-Host "Predict     : $Predict"
Write-Host "Keep alive  : $KeepAlive"
Write-Host ""

try {

    $ollamaVersion = (
        Invoke-RestMethod `
            -Uri "http://127.0.0.1:11434/api/version" `
            -Method Get
    ).version

    Write-Host "Ollama API  : $ollamaVersion"
}
catch {

    Write-Host ""
    Write-Host "ERROR: Ollama API is not reachable."
    Write-Host ""

    throw
}


# ------------------------------------------------------------
# CLEAN MODEL STATE
# ------------------------------------------------------------

Write-Host ""
Write-Host "=== CLEANING LOADED MODELS ==="

try {

    $psState = Invoke-RestMethod `
        -Uri "http://127.0.0.1:11434/api/ps" `
        -Method Get

    if ($psState.models) {

        foreach ($loaded in $psState.models) {

            if ($loaded.name) {

                Write-Host "Stopping:" $loaded.name

                ollama stop $loaded.name |
                    Out-Null
            }
        }

        Start-Sleep -Seconds 3
    }
}
catch {

    Write-Host "Could not enumerate loaded models through /api/ps."
    Write-Host "Continuing with current Ollama state."
}


# ------------------------------------------------------------
# BASELINE
# ------------------------------------------------------------

Write-Host ""
Write-Host "=== BASELINE ==="

$baselineRam = Get-FreeRamGB
$baselineGpu = Get-GpuSnapshot
$baselineOllamaPs = Get-OllamaPsText

Write-Host "Free RAM:" $baselineRam "GB"

if ($baselineGpu.memory_used_mib -ne $null) {
    Write-Host "GPU memory:" $baselineGpu.memory_used_mib "MiB"
}

Write-Host ""
Write-Host $baselineOllamaPs


# ------------------------------------------------------------
# WARM-UP
# ------------------------------------------------------------

Write-Host ""
Write-Host "=== WARM-UP ==="

$warmBody = @{

    model = $Model

    prompt = "Reply with READY"

    stream = $false

    think = $false

    options = @{
        num_ctx     = $Context
        num_predict = 8
        temperature = 0
    }

    keep_alive = $KeepAlive

} | ConvertTo-Json -Depth 6


$warmResult = Invoke-RestMethod `
    -Uri "http://127.0.0.1:11434/api/generate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $warmBody

Write-Host "Warm-up complete."

Start-Sleep -Seconds 1


# ------------------------------------------------------------
# CONTROLLED SUSTAINED TEST
# ------------------------------------------------------------

Write-Host ""
Write-Host "=== SUSTAINED GENERATION TEST ==="

$testPrompt = @"
Output the integers from 1 through 500 in order, separated by commas only. Do not use ellipsis, do not abbreviate, do not explain, and do not stop early.
"@


$body = @{

    model = $Model

    prompt = $testPrompt.Trim()

    stream = $false

    think = $false

    options = @{
        num_ctx     = $Context
        num_predict = $Predict
        temperature = 0
    }

    keep_alive = $KeepAlive

} | ConvertTo-Json -Depth 6


$testStart = Get-Date

$result = Invoke-RestMethod `
    -Uri "http://127.0.0.1:11434/api/generate" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body

$testEnd = Get-Date


# ------------------------------------------------------------
# CALCULATE METRICS
# ------------------------------------------------------------

$generationTPS = 0

if ($result.eval_duration -gt 0) {

    $generationTPS = [math]::Round(
        $result.eval_count /
        ($result.eval_duration / 1000000000),
        2
    )
}


$promptTPS = 0

if ($result.prompt_eval_duration -gt 0) {

    $promptTPS = [math]::Round(
        $result.prompt_eval_count /
        ($result.prompt_eval_duration / 1000000000),
        2
    )
}


$loadDurationMs = [math]::Round(
    $result.load_duration / 1000000,
    2
)


$totalDurationSec = [math]::Round(
    $result.total_duration / 1000000000,
    2
)


# ------------------------------------------------------------
# POST-TEST RESOURCE STATE
# ------------------------------------------------------------

Start-Sleep -Seconds 2

$postRam = Get-FreeRamGB
$postGpu = Get-GpuSnapshot
$postOllamaPs = Get-OllamaPsText


$ramDeltaGB = [math]::Round(
    $baselineRam - $postRam,
    2
)


$vramDeltaMiB = $null

if (
    $baselineGpu.memory_used_mib -ne $null -and
    $postGpu.memory_used_mib -ne $null
) {

    $vramDeltaMiB =
        $postGpu.memory_used_mib -
        $baselineGpu.memory_used_mib
}


# ------------------------------------------------------------
# RESPONSE PREVIEW
# ------------------------------------------------------------

$responsePreview = $result.response

if ($responsePreview.Length -gt 200) {

    $responsePreview =
        $responsePreview.Substring(0,200)
}


# ------------------------------------------------------------
# BUILD STRUCTURED RESULT
# ------------------------------------------------------------

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

$safeModelName = $Model `
    -replace ":", "_" `
    -replace "/", "_" `
    -replace "\\", "_"


$record = [ordered]@{

    timestamp = $timestamp

    benchmark = [ordered]@{
        model          = $Model
        context        = $Context
        requested_tokens = $Predict
        temperature    = 0
        think           = $false
        keep_alive      = $KeepAlive
        warm_run        = $true
    }

    generation = [ordered]@{
        generated_tokens       = $result.eval_count
        generation_tps         = $generationTPS
        prompt_tokens           = $result.prompt_eval_count
        prompt_tps              = $promptTPS
        load_duration_ms        = $loadDurationMs
        total_duration_sec      = $totalDurationSec
        done_reason             = $result.done_reason
        response_characters     = $result.response.Length
        response_preview        = $responsePreview
    }

    memory = [ordered]@{
        baseline_free_ram_gb = $baselineRam
        post_free_ram_gb     = $postRam
        observed_ram_delta_gb = $ramDeltaGB
    }

    gpu = [ordered]@{
        baseline = $baselineGpu
        post_test = $postGpu
        observed_vram_delta_mib = $vramDeltaMiB
    }

    ollama = [ordered]@{
        version = $ollamaVersion
        baseline_ps = $baselineOllamaPs
        post_test_ps = $postOllamaPs
    }
}


# ------------------------------------------------------------
# SAVE JSON
# ------------------------------------------------------------

$fileTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$jsonFile = Join-Path `
    $OutputDir `
    ("benchmark_" + $safeModelName + "_" + $fileTimestamp + ".json")


$record |
    ConvertTo-Json -Depth 8 |
    Set-Content `
        -Path $jsonFile `
        -Encoding UTF8


# ------------------------------------------------------------
# APPEND SUMMARY CSV
# ------------------------------------------------------------

$csvFile = Join-Path `
    $OutputDir `
    "model_benchmarks.csv"


$csvRow = [PSCustomObject]@{

    timestamp = $timestamp
    model = $Model
    ollama_version = $ollamaVersion

    context = $Context
    requested_tokens = $Predict
    generated_tokens = $result.eval_count

    done_reason = $result.done_reason

    generation_tps = $generationTPS
    prompt_tps = $promptTPS

    load_duration_ms = $loadDurationMs
    total_duration_sec = $totalDurationSec

    baseline_free_ram_gb = $baselineRam
    post_free_ram_gb = $postRam
    observed_ram_delta_gb = $ramDeltaGB

    baseline_vram_mib = $baselineGpu.memory_used_mib
    post_vram_mib = $postGpu.memory_used_mib
    observed_vram_delta_mib = $vramDeltaMiB
}


if (Test-Path $csvFile) {

    $csvRow |
        Export-Csv `
            -Path $csvFile `
            -Append `
            -NoTypeInformation `
            -Encoding UTF8
}
else {

    $csvRow |
        Export-Csv `
            -Path $csvFile `
            -NoTypeInformation `
            -Encoding UTF8
}


# ------------------------------------------------------------
# DISPLAY RESULT
# ------------------------------------------------------------

Write-Host ""
Write-Host "============================================"
Write-Host " BENCHMARK RESULT"
Write-Host "============================================"

Write-Host ""
Write-Host "Model:" $Model

Write-Host ""
Write-Host "Generated tokens:" $result.eval_count
Write-Host "Done reason:" $result.done_reason

Write-Host ""
Write-Host "Generation speed:" $generationTPS "tok/s"
Write-Host "Prompt speed:" $promptTPS "tok/s"

Write-Host ""
Write-Host "Load duration:" $loadDurationMs "ms"
Write-Host "Total duration:" $totalDurationSec "sec"

Write-Host ""
Write-Host "Baseline free RAM:" $baselineRam "GB"
Write-Host "Post-test free RAM:" $postRam "GB"
Write-Host "Observed RAM delta:" $ramDeltaGB "GB"

if ($vramDeltaMiB -ne $null) {

    Write-Host ""
    Write-Host "Baseline VRAM:" $baselineGpu.memory_used_mib "MiB"
    Write-Host "Post-test VRAM:" $postGpu.memory_used_mib "MiB"
    Write-Host "Observed VRAM delta:" $vramDeltaMiB "MiB"
}

Write-Host ""
Write-Host "=== OLLAMA PS ==="
Write-Host $postOllamaPs

Write-Host ""
Write-Host "=== RESPONSE PREVIEW ==="
Write-Host $responsePreview

Write-Host ""
Write-Host "Saved:"
Write-Host "  $jsonFile"
Write-Host "  $csvFile"
Write-Host ""
