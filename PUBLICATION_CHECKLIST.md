# Public Repository Publication Checklist

Use this checklist before pushing the Odysseus evaluation repository to a public Git host.

## 1. Ownership and attribution

- [ ] README clearly states that Odysseus is an external open-source project.
- [ ] `ATTRIBUTION.md` is present.
- [ ] Upstream repository and tested commit are documented.
- [ ] No claim suggests that this repository is the original Odysseus project.
- [ ] Any redistributed upstream source code follows its applicable license and notice requirements.

## 2. Secrets and credentials

The public repository must contain none of the following:

- [ ] passwords,
- [ ] usernames tied to private systems,
- [ ] API keys,
- [ ] access tokens,
- [ ] cookies,
- [ ] authentication headers,
- [ ] private keys,
- [ ] `.env` files,
- [ ] `credentials.txt`,
- [ ] private email credentials,
- [ ] service-account files.

Run a manual search before publication.

Example PowerShell check:

```powershell
Get-ChildItem -Recurse -File |
    Select-String -Pattern `
        "password",
        "api[_-]?key",
        "access[_-]?token",
        "secret",
        "authorization:",
        "bearer " `
    -CaseSensitive:$false
```

Every match must be reviewed manually because benign documentation may legitimately contain some of these words.

## 3. Personal and private information

- [ ] No personal email addresses unless intentionally public.
- [ ] No phone numbers.
- [ ] No private usernames.
- [ ] No home or precise location information.
- [ ] No unrelated browser tabs/bookmarks in screenshots.
- [ ] No private chat history.
- [ ] No identifiable third-party personal information.
- [ ] No authentication/session IDs.

## 4. Evidence review

### `raw-evidence/`

- [ ] Treat as private by default.
- [ ] Do not publish directly.
- [ ] Keep full logs/screenshots only for internal provenance.

### `public-evidence/`

Every file must be manually reviewed:

- [ ] crop irrelevant UI,
- [ ] redact credentials and session values,
- [ ] remove private browser history/bookmarks,
- [ ] remove unrelated file paths when unnecessary,
- [ ] retain enough context for technical interpretation,
- [ ] give the file a descriptive name.

## 5. Synthetic fixtures

Confirm that publication fixtures contain only synthetic data:

- [ ] `fixtures/rag_synthetic_document.txt`
- [ ] `fixtures/memory_synthetic_fact.txt`
- [ ] `fixtures/agent_note.txt`
- [ ] `fixtures/sample_data.csv`

Expected synthetic markers include:

- `SILVER-MOON-482`
- `AURORA-NODE`
- `927451`
- `COBALT-RIVER-731`
- `ORBIT-GLASS-219`

## 6. Results and claims

- [ ] Benchmark claims are based on the standardized October dataset.
- [ ] Historical September data remains clearly separated.
- [ ] Median, range, and variability are reported together.
- [ ] 1.7B-vs-4B speed ratio is described as machine/configuration specific.
- [ ] Natural agent-tool failures are scoped to the tested task.
- [ ] Do not claim that Qwen3 generally cannot use tools.
- [ ] Dedicated file-tool confinement is distinguished from Bash/Python OS permissions.
- [ ] Do not call Bash/Python outside-workspace access a sandbox escape unless an OS sandbox was actually established.
- [ ] Shell UI/request mismatch is described as an observed request-state inconsistency.
- [ ] Do not claim successful disabled-state shell execution.

## 7. Reproducibility

- [ ] `reproducibility/REPRODUCIBILITY.md` exists and is non-empty.
- [ ] `reproducibility/TEST_METHODS.md` exists and is non-empty.
- [ ] `reproducibility/experiment_manifest.json` parses successfully.
- [ ] `reproducibility/SHA256SUMS.txt` exists.
- [ ] `verify_hashes.ps1` reports zero failures.
- [ ] Current frozen package reports 24/24 integrity passes.
- [ ] Material environment changes are recorded as a new experimental epoch.

## 8. Repository hygiene

Do not commit:

- [ ] Python virtual environments,
- [ ] ChromaDB persistent data,
- [ ] Ollama model blobs,
- [ ] local caches,
- [ ] temporary files,
- [ ] raw credentials,
- [ ] local logs containing secrets,
- [ ] raw private screenshots,
- [ ] system-specific runtime directories.

Confirm `.gitignore` is present before the first public commit.

## 9. Final Git review

Before publishing:

```powershell
git status
git diff --cached
git ls-files
```

Review every tracked file.

Optional file-name search:

```powershell
git ls-files |
    Select-String -Pattern `
        "credential",
        "secret",
        "token",
        "\.env",
        "cookie",
        "session" `
    -CaseSensitive:$false
```

If any suspicious file appears, stop and review it before pushing.

## 10. Release readiness

Publish only when:

- [ ] README is final,
- [ ] attribution is final,
- [ ] public evidence is sanitized,
- [ ] reproducibility files are final,
- [ ] integrity check passes,
- [ ] no secrets/private information are tracked,
- [ ] claims match recorded evidence,
- [ ] repository license strategy has been decided,
- [ ] final Git diff has been manually reviewed.

## Release decision

- [ ] READY FOR PUBLICATION
- [ ] NOT READY — further review required
