$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

$files = @(
    "results\environment_snapshot.txt",
    "results\environment_snapshot.json",
    "results\model_benchmarks.csv",
    "results\model_benchmark_summary.csv",
    "results\model_benchmarks_pre_version_control.csv",

    "results\benchmark_qwen3_1.7b_20261025-232900.json",
    "results\benchmark_qwen3_4b_20261025-232942.json",
    "results\benchmark_qwen3_1.7b_20261025-232957.json",
    "results\benchmark_qwen3_4b_20261025-233018.json",
    "results\benchmark_qwen3_1.7b_20261025-233033.json",
    "results\benchmark_qwen3_4b_20261025-233053.json",

    "results\rag_results.csv",
    "results\memory_results.csv",
    "results\agent_tool_results.csv",
    "results\security_results.csv",

    "benchmarks\environment_snapshot.ps1",
    "benchmarks\ollama_model_benchmark.ps1",

    "reproducibility\experiment_manifest.json",
    "reproducibility\REPRODUCIBILITY.md",
    "reproducibility\TEST_METHODS.md",

    "fixtures\rag_synthetic_document.txt",
    "fixtures\memory_synthetic_fact.txt",
    "fixtures\agent_note.txt",
    "fixtures\sample_data.csv"
)

$output = Join-Path $PSScriptRoot "SHA256SUMS.txt"

$lines = @()

foreach ($relative in $files) {

    $full = Join-Path $root $relative

    if (-not (Test-Path $full)) {
        throw "Missing artifact: $relative"
    }

    $hash = Get-FileHash `
        -Path $full `
        -Algorithm SHA256

    $normalized = $relative.Replace("\","/")

    $lines += "$($hash.Hash.ToLower())  $normalized"
}

$lines |
    Set-Content `
        -Path $output `
        -Encoding UTF8

Write-Host ""
Write-Host "SHA-256 manifest created:"
Write-Host $output
Write-Host ""
Write-Host "Artifacts hashed: $($lines.Count)"
