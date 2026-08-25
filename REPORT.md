# Technical Report — Offline Shona AI Coding Tutor

- Team ID: https://devpost.com/software/shona-coding-tutor-offline-on-device-ai
- Domain: coding_assistants
- Model: gemma-2-2b-it-Q4_K_M

**Africa Deep Tech Challenge 2026 — Laptop LLM Challenge**

## 1. Problem & Approach

Many first-time programmers in Zimbabwe learn Computer Science concepts in English only, with no offline option and no support in a home language. This project is an on-device coding tutor that explains core CS/Python concepts in **English and Shona**, runs entirely offline within a 7GB RAM budget, and grounds its answers in a curated syllabus via retrieval-augmented generation (RAG) rather than free generation alone.

The system has two modes: ask-a-question and generate-practice-questions; and both respect a single upfront mode/language choice.

## 2. Model Selection

Two candidates were benchmarked head-to-head, same quantization level (Q4_K_M), same hardware:

| Model | Peak RAM | Speed |
|---|---|---|
| Phi-3.5-mini-instruct | 4.75 GB | 6.8 tok/s |
| **Gemma-2-2b-it (chosen)** | **3.29 GB** | **9.67 tok/s** |

Gemma-2-2b-it was adopted as the final model: lower memory footprint, meaningfully faster, no observed quality regression on syllabus-grounded English generation in manual testing.

Increasing `n_threads` from 4 to 8 (12 cores available) gave a negligible speed gain (6.71 → 6.87 tok/s on the original model), ruling out thread count as the main lever — the gain came from model choice instead.

**Quantization:** Q5_K_M was also tested against Q4_K_M for a possible accuracy gain. Result: identical arc_easy accuracy (0.72) but 34% slower (5.65 vs 8.57 tok/s), dropping the estimated composite score from ~65.3 to ~61.5. Q4_K_M was kept as final — no accuracy benefit from the higher quantization on this benchmark, at a real performance cost.

## 3. Why Shona Answers Are Curated, Not Generated

Early testing had the model generate Shona explanations freely, using the same RAG pipeline as English. Output quality was poor and frequently incoherent — the base model's Shona generation is not reliable enough to present to a learner as an authoritative explanation.

Design response: for on-syllabus Shona questions, the tutor returns **curated, human-verified Shona content** written directly into `syllabus.json`, rather than anything model-generated. English mode continues to use live model generation grounded in retrieved context. This trades some flexibility for correctness, which matters more in an educational tool.

## 4. Shona Question Input — Retrieval Limitation

The embedding model (`all-MiniLM-L6-v2`) is not strong at cross-lingual matching for this language pair. Measured similarity between the English phrase "for loop" and its Shona equivalent was **0.154** — far too low to match reliably.

Testing across phrasing styles found a consistent pattern:
- **Fully English questions** match reliably.
- **Code-switched questions** (Shona grammar with an embedded English technical term, e.g. *"Chii chinonzi for loop"*) — match reliably.
- **Fully Shona questions with no English technical term** — do not match reliably; the fallback path triggers instead.

This is documented as an accurate capability description rather than claiming either "no Shona support" or "full Shona support" — code-switching, which is how many Shona speakers naturally phrase technical questions in practice, is supported.

## 5. Retrieval Threshold Tuning

A distance-threshold fallback was added so the tutor can recognize when a question is off-syllabus rather than confidently hallucinating a syllabus answer.

- Initial calibration: on-topic distance ≈ 0.42, paraphrased on-topic ≈ 1.10, off-topic ≈ 1.94 → threshold set at **1.4**.
- Full regression test across all syllabus topics (42 test questions: English "what is X" + Shona code-switched "Chii chinonzi X" per topic): 40/42 passed. The 2 failures were short single-word topics (Variables, Lists) narrowly exceeding the threshold.
- Threshold raised to **1.6** to fix both remaining failures while keeping a safe margin below the off-topic baseline (~1.94).

**False-positive investigation at threshold 1.6:** testing found 8–9 out of 10 genuinely off-syllabus questions were falsely matched to an unrelated syllabus topic. Two mitigations were tried:
- **Embedding enrichment** (indexing example code + common mistakes alongside the explanation) — made true-topic matching *worse* without fixing the false-positive rate. Reverted.
- **Dual per-language thresholds**: explored but abandoned given deadline pressure in favor of the last fully-tested, stable configuration.

**Syllabus expansion as the real fix:** the syllabus was expanded from 21 to 58 entries (adding algorithm design, error types, file I/O, list comprehensions, OOP classes/inheritance, recursion, lambda functions, pip installs, and debugging-strategy topics). Re-testing after expansion closed 8 of the original false-positive gaps by giving those questions a real syllabus home. Remaining false positives are concentrated on genuinely advanced/uncovered topics (decorators, metaclasses, async/await, generators, dependency injection) at a similar ~80% false-positive rate on that narrow slice.

**Current status:** `DISTANCE_THRESHOLD = 1.6`, simple (non-enriched) embeddings, shared offline `embedder.py`. Further threshold/embedding tuning was stopped given the submission deadline; the remaining false-positive risk on advanced/uncovered topics is documented here as a known, bounded limitation rather than silently left unaddressed.

## 6. Out-of-Scope Question Handling

Judges grade against domain and hidden prompts that go beyond the curated syllabus, so a design that flatly refuses every out-of-scope question would be scored poorly on accuracy even where the model could plausibly help. The handling was redesigned:

- **English, out-of-scope**: the model attempts a real answer from general knowledge (not syllabus-grounded, since there's no matched context to ground it in).
- **Shona, out-of-scope**: the tutor apologizes in Shona for not having a Shona explanation on file, then gives a real model-generated English answer — rather than a flat refusal in either language.

This applies consistently to both Q&A and practice-question modes. Input validation with a retry loop was also added for mode/language selection, plus numeric shortcuts (`1`=english, `0`=shona).

## 7. Benchmarks

**Own benchmark (`benchmark.py`)**, includes embedder/index load: peak RAM 4.75GB on the original (Phi-3.5-mini) configuration, dropping to 3.29GB after switching to Gemma-2-2b-it.

**Official ADTC profiler** (`adtc-profiler`, full run, accuracy included — not `--skip-accuracy`, since accuracy is 50% of the total score):

| Metric | Result |
|---|---|
| Peak RAM | 2.75 GB |
| Throughput | 8.57 tokens/sec |
| Thermal throttling | None observed |
| arc_easy accuracy (50 samples) | 0.72 |
| Estimated composite score | ~65.3 / 100 (S_acc=72, S_perf=57.1, S_eff=60.7) |

An earlier profiler pass reported 10.41 tok/s and 2.75GB, but that run used `--skip-accuracy` (a smoke test only) and does not reflect the scored submission; the figures above are from the full run used for `submission.json`.

`metadata.json` parameter count was corrected from an initial rough estimate of 2B to the actual value: **2,614,341,888 parameters (2.6B)**.

## 8. Known Limitations

- Fully Shona question input (no English technical term) does not match reliably — see §4.
- Retrieval can misroute genuinely advanced/uncovered topics (decorators, metaclasses, async/await, generators, dependency injection) to an unrelated syllabus entry rather than falling through cleanly to the general-knowledge path — see §5.
- Shona answers are limited to the curated set in `syllabus.json`; there is no free-form Shona generation.
- CPU-only, single-model deployment — no ensemble or larger-model fallback within the 7GB budget.

## 9. Reproducing Results

```bash
python3 build_index.py
python3 benchmark.py
adtc-profiler run --submission . --mode participant --output submission.json
```
