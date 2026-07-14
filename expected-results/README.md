# Expected evaluation results

These compact files are a reviewer baseline. Running `scripts/evaluate.sh`
generates detailed logs, CSV tables, timings, and Alectryon pages under
`results/` and checks the benchmark total rows automatically.

- `tool-versions.txt` records the versions pinned by the Docker image.
- `benchmark-totals.csv` records the paper's three evaluated source sets.
- `proof-hygiene.txt` records the successful source-level proof scan.
- `summary.txt` records the expected pass/fail outcomes.

Wall-clock timings are intentionally omitted because they depend on the host.
