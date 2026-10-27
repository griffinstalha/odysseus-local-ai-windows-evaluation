# Reproducing the Odysseus Local AI Windows Evaluation

## 1. Purpose
This package documents a reproducible systems evaluation of Odysseus, a self-hosted agentic AI workspace, on consumer Windows hardware. The evaluation covers local LLM inference, resource use, RAG, vector memory, agent-tool reliability, filesystem-boundary behavior, and native Windows deployment issues. This repository is an evaluation artifact and does not claim authorship of Odysseus.

## 2. Tested Environment
- Evaluation epoch: 2026-10-25
- Windows 11 Pro, version/build 10.0.26200 / 26200
- AMD Ryzen 7 5800H, 8 cores / 16 logical processors
- 15.86 GB RAM
- NVIDIA GeForce RTX 3050 Laptop GPU, 4096 MiB VRAM
- NVIDIA driver 621.01
- Python 3.12.10
- Ollama 0.34.4
- ChromaDB 1.5.9

## 3. Odysseus Source Revision
- Upstream repository: https://github.com/odysseus-dev/odysseus
- Upstream baseline commit: `451900fc151554f4c8654d1e4d3dadc1d029b047`
- Evaluation branch: `experiment-v1.0.3-windows`
- Evaluation commit: `7b776b6ceb090f2d5374e1c0c7c8f2dae7fe81a7`
- Working tree during standardized evaluation: CLEAN

### Local compatibility patch
The tested baseline referenced `Any` in `src/agent_loop.py` without importing it. The evaluation branch contains the minimal compatibility fix:

```python
from typing import Any, AsyncGenerator, List, Dict, Optional, Set
```

## 4. Local Models
- `qwen3:1.7b` — ID `8f68893c685c`, stored size about 1.4 GB
- `qwen3:4b` — ID `359d7dd4bcda`, stored size about 2.5 GB
- `all-minilm:l6-v2` — ID `1b226e2802db`, stored size about 45 MB, embedding dimension 384

## 5. Local Services
Ollama endpoint:
```text
http://127.0.0.1:11434
```

Start Ollama:
```powershell
ollama serve
```

Verify:
```powershell
curl.exe http://127.0.0.1:11434/api/version
ollama list
ollama ps
```

Start ChromaDB:
```powershell
cd D:\Projects\odysseus
.\chroma-venv\Scripts\chroma.exe run `
  --path "D:\Projects\odysseus\chroma-data" `
  --host 127.0.0.1 `
  --port 8100
```

Start Odysseus:
```powershell
cd D:\Projects\odysseus\odysseus
$env:NO_PROXY=[Environment]::GetEnvironmentVariable("NO_PROXY","User")
$env:no_proxy=$env:NO_PROXY
.\venv\Scripts\python.exe -m uvicorn app:app `
  --host 127.0.0.1 `
  --port 7000
```

UI:
```text
http://127.0.0.1:7000
```

## 6. Embedding Warm-Up
Under Ollama 0.34.4, the first cold load of `all-minilm:l6-v2` exceeded the startup embedding timeout in the tested setup. Warm it first:

```powershell
$body = @{
  model = "all-minilm:l6-v2"
  input = "Odysseus embedding warmup test"
} | ConvertTo-Json

$result = Invoke-RestMethod `
  -Uri "http://127.0.0.1:11434/v1/embeddings" `
  -Method Post `
  -ContentType "application/json" `
  -Body $body `
  -TimeoutSec 120

$result.data[0].embedding.Count
```

Expected output:
```text
384
```

## 7. Standardized Model Benchmark
Script:
```text
benchmarks/ollama_model_benchmark.ps1
```

Configuration:
- Ollama 0.34.4
- context 4096
- 128 requested generation tokens
- temperature 0
- thinking requested false
- warm-up before measured generation
- three runs per model

Execution order:
1. qwen3:1.7b
2. qwen3:4b
3. qwen3:1.7b
4. qwen3:4b
5. qwen3:1.7b
6. qwen3:4b

## 8. Standardized Benchmark Results
Qwen3 1.7B:
- runs: 66.36, 106.86, 107.37 tok/s
- median: 106.86 tok/s
- mean: 93.53 tok/s
- range: 66.36–107.37 tok/s
- sample SD: 23.53 tok/s
- median RAM delta: 0.67 GB
- median VRAM delta: 1716 MiB
- processor allocation: 100% GPU

Qwen3 4B:
- runs: 22.31, 24.70, 25.68 tok/s
- median: 24.70 tok/s
- mean: 24.23 tok/s
- range: 22.31–25.68 tok/s
- sample SD: 1.73 tok/s
- median RAM delta: 1.50 GB
- median VRAM delta: 2312 MiB
- processor allocation: 33% CPU / 67% GPU

In this specific standardized configuration, the median 1.7B throughput was about 4.33× the 4B median. This is not a universal model-speed ratio.

## 9. RAG Evaluation
Structured results:
```text
results/rag_results.csv
```

Synthetic markers:
- `SILVER-MOON-482`
- `AURORA-NODE`
- `927451`

Recorded tests:
- direct vector retrieval — PASS
- exact fact retrieval — PASS
- semantic fact retrieval — PASS
- restart persistence — PASS

These results demonstrate tested functionality, not large-scale retrieval quality.

## 10. Vector Memory Evaluation
Structured results:
```text
results/memory_results.csv
```

Synthetic marker:
```text
COBALT-RIVER-731
```

Recorded tests:
- manual storage — PASS
- fresh-conversation recall — PASS
- continued vector-memory availability — PASS

This is not a comprehensive long-term memory benchmark.

## 11. Agent Tool Evaluation
Structured results:
```text
results/agent_tool_results.csv
```

Synthetic verification marker:
```text
ORBIT-GLASS-219
```

Natural `read_file` invocation:
- qwen3:1.7b — FAIL
- qwen3:4b — FAIL

When the correct textual tool protocol was supplied:
- parser detection — PASS
- read_file execution — PASS
- end-to-end response loop — PASS

The supported conclusion is that autonomous tool-protocol emission was unreliable in the tested task, while the parser/backend path worked when valid protocol was supplied.

## 12. Filesystem Boundary Evaluation
Structured results:
```text
results/security_results.csv
```

Dedicated file tools:
- relative read escape — BLOCKED
- absolute read outside workspace — BLOCKED
- relative write escape — BLOCKED
- absolute write outside workspace — BLOCKED

Executable tools:
- Bash outside-workspace read — ALLOWED
- Bash outside-workspace write — ALLOWED
- Python outside-workspace read — ALLOWED

Interpretation: the selected workspace acted as a boundary for the tested dedicated file tools, but as an initial working directory rather than an OS-level filesystem sandbox for Bash/Python.

## 13. Shell UI / Request-Policy Observation
The visible shell control could show disabled while an Agent-intent request contained:
```text
allow_bash=true
```

This supports a request-state inconsistency observation. Successful Bash execution from that specific disabled UI state was not demonstrated.

## 14. Environment and Integration Issues
Observed reproducibility-relevant issues included:
1. missing `typing.Any` import in the tested baseline,
2. earlier NVIDIA driver incompatibility,
3. Windows proxy interference with localhost Python/httpx traffic,
4. separate ChromaDB service requirement,
5. embedding-model configuration,
6. embedding cold-start timeout under Ollama 0.34.4,
7. optional MCP failures independent of core local RAG/vector memory,
8. runtime version drift between experimental dates.

## 15. Historical Benchmark Data
Historical September data:
```text
results/model_benchmarks_pre_version_control.csv
```

Standardized October data:
```text
results/model_benchmarks.csv
```

Do not merge them directly because runtime conditions differed.

## 16. Environment Snapshot
Run:
```powershell
cd D:\Projects\odysseus-evaluation
& .\benchmarks\environment_snapshot.ps1
```

Outputs:
```text
results/environment_snapshot.txt
results/environment_snapshot.json
```

## 17. Experiment Manifest
Machine-readable metadata:
```text
reproducibility/experiment_manifest.json
```

Validate:
```powershell
Get-Content ".\reproducibility\experiment_manifest.json" -Raw |
  ConvertFrom-Json | Out-Null
```

## 18. Artifact Integrity
Generate hashes:
```powershell
& .\reproducibility\generate_hashes.ps1
```

Verify:
```powershell
& .\reproducibility\verify_hashes.ps1
```

Frozen package result:
```text
Passed: 18
Failed: 0
INTEGRITY CHECK: PASS
```

## 19. Result Files
Primary structured outputs:
```text
results/model_benchmarks.csv
results/model_benchmark_summary.csv
results/rag_results.csv
results/memory_results.csv
results/agent_tool_results.csv
results/security_results.csv
```

## 20. Synthetic Fixtures
Publication/reproduction fixtures:
```text
fixtures/rag_synthetic_document.txt
fixtures/memory_synthetic_fact.txt
fixtures/agent_note.txt
fixtures/sample_data.csv
```

They use synthetic identifiers only.

## 21. Safety and Privacy
Recommended operating assumptions:
- bind Odysseus, Ollama, and ChromaDB to localhost,
- retain authentication,
- do not expose raw model ports publicly,
- do not use real credentials in fixtures,
- do not assume the workspace is an OS sandbox for Bash/Python,
- review MCP integrations before enabling untrusted servers.

## 22. Limitations and Reproduction Principle
Limitations:
- one Windows laptop,
- two generation models,
- three standardized runs per model,
- context 4096,
- 128-token generation limit,
- small controlled agent task,
- synthetic RAG/memory fixtures,
- controlled boundary study rather than penetration testing,
- version-specific behavior.

Reproduction principle: match versions and environment as closely as practical, record deviations, and treat materially different environments as separate experimental epochs. Report median, range, variability, hardware allocation, and limitations together rather than relying on one benchmark run.
