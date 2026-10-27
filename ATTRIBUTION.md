# Attribution

## Odysseus

This repository is an independent evaluation of the external open-source project **Odysseus**.

Upstream repository:

https://github.com/odysseus-dev/odysseus

Tested upstream baseline commit:

`451900fc151554f4c8654d1e4d3dadc1d029b047`

Local evaluation commit:

`7b776b6ceb090f2d5374e1c0c7c8f2dae7fe81a7`

The local evaluation branch includes a minimal compatibility correction that imports `typing.Any` in `src/agent_loop.py` so the tested baseline can start successfully.

## Scope of this repository

This repository is intended to contain independently created evaluation material, including:

- benchmark scripts,
- structured experimental results,
- synthetic fixtures,
- reproducibility documentation,
- sanitized public evidence,
- research notes.

It should not be presented as the original Odysseus application or as an official Odysseus repository.

## Upstream licensing

Before redistributing any copied or modified Odysseus source code, preserve all applicable upstream copyright, attribution, and license requirements.

This evaluation repository should preferably remain separate from the upstream application source unless a specific upstream patch or fork is intentionally published.
