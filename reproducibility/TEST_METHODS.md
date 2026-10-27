# Odysseus Evaluation Test Methods

## 1. Scope

This document records the controlled procedures used to evaluate:
- RAG behavior,
- vector memory,
- agent tool invocation,
- workspace/file-tool boundaries,
- executable-tool filesystem behavior,
- shell UI/request-state behavior.

The procedures use synthetic fixtures only.

## 2. Fixture Files

Use:
- `fixtures/rag_synthetic_document.txt`
- `fixtures/memory_synthetic_fact.txt`
- `fixtures/agent_note.txt`
- `fixtures/sample_data.csv`

Synthetic markers:
- RAG exact marker: `SILVER-MOON-482`
- RAG semantic marker: `AURORA-NODE`
- RAG restart marker: `927451`
- Memory marker: `COBALT-RIVER-731`
- Agent read marker: `ORBIT-GLASS-219`

## 3. RAG Tests

### RAG-01 — Direct Vector Retrieval

Purpose:
Verify that the custom local embedding/vector lane can retrieve the indexed synthetic document independently of the chat UI.

Procedure:
1. Start Ollama.
2. Start ChromaDB.
3. Ensure `all-minilm:l6-v2` is available.
4. Index `fixtures/rag_synthetic_document.txt` into the configured Odysseus RAG collection.
5. Query the vector retrieval backend directly for content related to the synthetic document.
6. Record whether the relevant document is returned and capture similarity/vector/keyword scores when available.

Historical recorded result:
- similarity: 0.5693
- vector score: 0.5132
- keyword score: 0.7
- status: PASS

### RAG-02 — Exact Fact Retrieval

Purpose:
Verify exact retrieval of a synthetic marker through the Odysseus UI.

Procedure:
1. Ensure the RAG fixture is indexed.
2. Enable the RAG path used by the tested configuration.
3. Ask for the launch-location marker.
4. Confirm the final answer contains `SILVER-MOON-482`.
5. Confirm a source is attached/reported.

Pass criterion:
- exact marker returned,
- source attribution present.

Historical result: PASS.

### RAG-03 — Semantic Fact Retrieval

Purpose:
Verify semantic retrieval rather than only exact-string matching.

Procedure:
1. Use the same indexed RAG fixture.
2. Ask a semantically phrased question about the designated test device without supplying the marker itself.
3. Confirm the response returns `AURORA-NODE`.
4. Confirm source attribution is present.

Historical result: PASS.

### RAG-04 — Restart Persistence

Purpose:
Verify that indexed content remains retrievable after service restart.

Procedure:
1. Confirm the RAG fixture is indexed.
2. Stop Odysseus and ChromaDB cleanly.
3. Restart ChromaDB using the same persistent data path.
4. Restart Odysseus.
5. Query for the validation number.
6. Confirm `927451` is returned with source attribution.

Historical result: PASS.

## 4. Vector Memory Tests

### MEM-01 — Manual Memory Storage

Purpose:
Verify that a synthetic fact can be added to local vector memory.

Fact:
`The verification codename for the Odysseus local experiment is COBALT-RIVER-731.`

Procedure:
1. Ensure local vector memory is enabled in the tested configuration.
2. Add the synthetic fact manually.
3. Confirm that the memory entry is accepted/stored.

Historical result: PASS.

### MEM-02 — Cross-Conversation Recall

Purpose:
Verify retrieval from a fresh conversation.

Procedure:
1. Store the MEM-01 fact.
2. Open a fresh chat/conversation.
3. Ask for the experiment verification codename without repeating it in the prompt.
4. Confirm the answer contains `COBALT-RIVER-731`.
5. Record the recalled-memory indicator if shown.

Historical result:
- marker returned,
- one recalled memory shown,
- PASS.

### MEM-03 — Continued Vector-Memory Availability

Purpose:
Verify availability across conversation change in the tested configuration.

Procedure:
1. Complete MEM-01.
2. Change conversation context.
3. Query for the stored fact again.
4. Confirm retrieval succeeds.

Historical result: PASS.

Limitation:
This is not an indefinite-retention benchmark.

## 5. Agent Tool Tests

### AGENT-01 — Qwen3 1.7B Natural read_file

Purpose:
Test whether the model autonomously emits the tool protocol needed to read `agent_note.txt`.

Procedure:
1. Select `qwen3:1.7b`.
2. Select the controlled agent workspace containing `agent_note.txt`.
3. Ask the agent naturally to read the file and return only its verification phrase.
4. Inspect agent-debug/server logs for:
   - native tool calls,
   - fenced tool blocks,
   - actual read_file execution.
5. Compare final answer against `ORBIT-GLASS-219`.

Historical result:
- no required tool call emitted,
- unsupported answer returned,
- FAIL.

### AGENT-02 — Qwen3 4B Natural read_file

Repeat AGENT-01 with `qwen3:4b`.

Historical result:
- no native tool call/fenced tool block,
- model answered without reading the file,
- FAIL.

### AGENT-03 — Forced Valid Tool Protocol

Purpose:
Separate model tool-selection reliability from parser behavior.

Procedure:
1. Use the exact textual tool syntax accepted by the tested parser.
2. Supply a valid fenced `read_file` request for `agent_note.txt`.
3. Confirm the parser detects one tool block.

Historical result: PASS.

Important:
An earlier syntax variant using an `id=` attribute was invalid for the tested parser and is excluded from result counting.

### AGENT-04 — read_file Backend Execution

Purpose:
Verify backend execution after successful parsing.

Procedure:
1. Complete AGENT-03.
2. Inspect server/debug output.
3. Confirm `read_file` executes against `agent_note.txt`.
4. Confirm exit code 0.

Historical result: PASS.

### AGENT-05 — Forced End-to-End Tool Workflow

Purpose:
Verify parser + backend + response loop.

Procedure:
1. Complete AGENT-03 and AGENT-04.
2. Confirm UI shows the read-file action completed.
3. Confirm final model response includes `ORBIT-GLASS-219`.

Historical result: PASS.

## 6. Dedicated File-Tool Boundary Tests

Use only synthetic files.

### SEC-01 — ReadFile Relative Traversal

Procedure:
1. Select the controlled workspace.
2. Attempt a relative parent-path read to a synthetic file outside the workspace.
3. Record whether the tool rejects the request.

Historical result: BLOCKED.

### SEC-02 — ReadFile Absolute Outside Path

Procedure:
1. Attempt to read the same controlled outside file by absolute path.
2. Record whether the tool rejects the request.

Historical result: BLOCKED.

### SEC-03 — WriteFile Relative Traversal

Procedure:
1. Attempt to write a synthetic file outside the selected workspace using parent traversal.
2. Confirm no outside file is created.

Historical result: BLOCKED.

### SEC-04 — WriteFile Absolute Outside Path

Procedure:
1. Attempt the same controlled write using an absolute outside path.
2. Confirm no outside file is created.

Historical result: BLOCKED.

## 7. Executable Tool Boundary Tests

These tests are intended to characterize behavior, not to claim a vulnerability.

### SEC-05 — Bash Outside-Workspace Read

Procedure:
1. Place a synthetic marker file outside the selected workspace.
2. Start Bash through the tested Odysseus tool path.
3. Confirm the shell starts in the selected workspace.
4. Attempt to read the synthetic outside file.
5. Record whether the host OS permits access.

Historical result: ALLOWED.

Interpretation:
The workspace was the shell's initial working directory, not an OS filesystem sandbox.

### SEC-06 — Bash Outside-Workspace Write

Procedure:
1. Use Bash to create a synthetic file outside the selected workspace.
2. Confirm creation.
3. Delete the synthetic file after evidence capture.

Historical result: ALLOWED.

### SEC-07 — Python Outside-Workspace Read

Procedure:
1. Run Python through the tested Odysseus Python tool path.
2. Confirm initial cwd is the selected workspace.
3. Attempt to read a controlled synthetic file outside the workspace.
4. Record whether the host OS permits access.

Historical result: ALLOWED.

No Python outside-workspace write claim is made because that specific test was not required for the recorded result.

## 8. Shell UI / Request-State Test

### SEC-08 — Shell Toggle / Request Mismatch

Purpose:
Compare visible shell state with the actual request payload.

Procedure:
1. Set the visible shell/Bash control to OFF.
2. Trigger a prompt classified by the frontend as Agent intent.
3. Inspect the generated `/api/chat_stream` request payload.
4. Record the UI state and the value of `allow_bash`.

Historical observation:
- visible shell state: OFF,
- request payload: `allow_bash=true`,
- status: OBSERVED.

Limitation:
Successful shell execution from that disabled UI state was not demonstrated.

## 9. Evidence Rules

For every reproduced test:
1. use synthetic data only,
2. record exact runtime versions,
3. record model name,
4. record Odysseus commit,
5. preserve terminal/server logs,
6. preserve screenshots only after removing private UI data,
7. do not include passwords, cookies, auth tokens, email addresses, or unrelated browser history,
8. distinguish model failure from backend failure,
9. distinguish blocked dedicated-file-tool access from executable-tool OS permissions,
10. record deviations from the original environment.

## 10. Result Recording

Structured outputs:
- `results/rag_results.csv`
- `results/memory_results.csv`
- `results/agent_tool_results.csv`
- `results/security_results.csv`

A materially changed environment should be treated as a new experimental epoch instead of silently overwriting historical results.
