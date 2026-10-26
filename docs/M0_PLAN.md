# M0 implementation plan

Target: the M0 software milestone of `virtual_student_implementation_spec.md`
§25. Everything runs on CPU with dummy backends; no paid API calls, no E1
unlock, no large model downloads.

## Environment

- Python 3.12 managed by `uv`, project venv at `.venv`, exact pins in `uv.lock`.
- Core deps: pydantic 2, PyYAML, jsonschema, pyarrow, numpy, pandas, scipy,
  statsmodels, pytest.
- Optional extra `train`: torch, transformers, peft, accelerate, datasets, trl.
  Tests that need it are skipped when it is absent.
- Optional extra `api`: boto3 (Bedrock), anthropic. Never exercised by tests.
- All 8 A100s are currently ~95% occupied by other work, so the "GPU smoke"
  (§24.4) runs a tiny random-weight model on CPU. It proves load / generate /
  LoRA update / checkpoint round-trip, not GPU throughput.

## Steps (each ends with tests passing and a commit)

1. **Scaffold.** `pyproject.toml`, package layout of §3, Pydantic config
   models (unknown fields rejected), `configs/schema.json` generated from the
   models, CLI skeleton with every command of §21, `--json-log`, `--dry-run`.
   Unresolved values: the literal strings `REQUIRED` / `TBD` parse to an
   `Unresolved` sentinel; development runs may carry them in fields the run
   does not use, confirmatory preflight rejects any of them. Values only valid
   for development are listed in a top-level `development_only` list, which
   must be empty in confirmatory mode.
2. **Determinism and data.** `derive_seed` with golden tests; canonical JSON
   and content-derived `item_id`; answer parser (§11); deterministic
   key-balanced answer-position permutation; Parquet schemas for every table in
   §7 with validation; split lock + development-mode E-set guard + access log;
   exact/normalised-text deduplication (embedding dedup is an interface whose
   model is `REQUIRED`).
3. **Fixture and importer.** A committed fixture (2 skills, 16 P, 4 P+, 4 W,
   4 D, 4 E1, 4 S, 2 dummy panel models, sibling map). An importer for the
   sat-reading-platform bank: items from `sat-reading-original.jsonl` (authored
   labels, never the panel-adjusted ones) plus the AI batches, panel responses
   from `eval_results*/`. Split assignment for the real bank is a hash-based
   development-only rule; confirmatory mode requires an explicit split file.
4. **Panel.** Per-skill alternating MAP calibration of panel abilities and
   item difficulties (priors are config values, `REQUIRED` in confirmatory),
   Laplace variances, PanelProbe scoring of new items with frozen abilities,
   raw smoothed pass-rate difficulty for P0, sub-panel support. Sanity check:
   on the real bank our `difficulty_hat` should correlate strongly with the
   existing `calibrated_s`.
5. **Tracker, schedule, selection.** Tracker (§12) incl. uncertainty variant
   and process noise rules; rotating round-robin schedule; candidate slates
   (§9.2); R, L, C, P0, PP, PP-u, PT; deterministic tie-breaking.
6. **Backends and cache.** Content-addressed atomic cache with quarantine;
   dummy student (a simulated learner whose per-skill ability rises with
   training signal ∝ p(1−p), so targeting has a real effect), dummy tutor and
   judges with injectable leaks and transport failures; real adapters
   (Transformers+PEFT student, Bedrock/Anthropic tutor) behind the same
   protocols.
7. **Feedback.** F0–F5 state machines (§15), guess filter, leakage checks,
   standalone validator, sibling check, F5 profile with redaction, offline F3
   script library.
8. **Training loop, checkpoint, resume.** §17 order of operations, SFT and
   GRPO (Dr. GRPO advantages), no-gradient updates, atomic checkpoints every
   update with retention, JSONL artifact streams with recorded offsets
   materialised to Parquet at the end, exact resume.
9. **Evaluation, statistics, reports.** Scheduled evaluation, AULC, pairing,
   contrasts vs R, targeting ratio with denominator guard, paired bootstrap
   (percentile + BCa), two-way seed × item-family bootstrap, Holm per family,
   report tables.
10. **Preflight, smoke, integration.** Preflight report (§22), `smoke`
    command (< 5 min CPU), integration tests of §24.2, optional tiny-model
    smoke, README with the spec-to-code mapping and every deviation.

## Design decisions made here (software only)

- **Resume granularity is one logical update.** Checkpoints are written after
  every update; a crash mid-update re-runs that update, and every external or
  student call already made is served from the cache, so no completed call is
  replayed. "Pending feedback events" in the checkpoint are therefore always
  empty.
- **Artifact streams.** Tables are appended as JSONL during the run (offsets
  saved in each checkpoint, truncated on resume) and written to Parquet once
  the run validates.
- **Prompts are chat messages plus metadata** (`item_id`, `kind`) rather than
  bare strings, so the dummy student can simulate behaviour; real backends
  ignore the metadata.
- **PP-u uses the exact normal-CDF band probability.** With θ and b Gaussian,
  P(σ(θ−b) ∈ [lo, hi]) is closed-form; a test checks it against high-order
  Gauss–Hermite. The configured node count is still recorded.
- **Training backend.** TRL's trainers own their data loop, which conflicts
  with per-update online selection, so SFT and GRPO losses are written
  directly on Transformers + PEFT. Flagged as a deviation from §4.

## Left `REQUIRED` (scientific, not decided here)

Everything in spec §27, plus: PT tracker-difficulty rule, panel priors,
sibling-check context (in-dialogue vs fresh), contrast families S/T/X,
misconception taxonomy (fixture ships a placeholder flagged as such),
split assignment for the real bank, dedup embedding model and threshold.

## Known blocker outside M0

A run needs 3,200 presentations without replacement, i.e. ≥ 320 pool items per
skill, plus 60 E1 items per skill. The current bank has 42–90 items per skill
in total. Preflight's pool-support check will reject any full-length run on it.
