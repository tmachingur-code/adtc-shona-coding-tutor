# Offline Shona AI Coding Tutor

An offline AI coding tutor built for the **Africa Deep Tech Challenge 2026 — Laptop LLM Challenge**. Teaches Python and CS fundamentals in English and Shona, running fully on-device with no internet required.

## Features

- Fully offline inference (Gemma-2-2b-it, quantized GGUF Q4_K_M, via llama.cpp)
- Bilingual: English and Shona, for both explanations and practice questions
- RAG-grounded answers from a curated **58-topic** CS syllabus (Python basics through OOP, recursion, lambdas, and debugging strategy)
- Two modes: ask a question, or generate practice questions on a topic
- Runs within a 7GB RAM budget, CPU-only (official profiler measured peak: **2.75GB**)
- Attempts a real answer even for questions outside the syllabus, instead of a flat refusal — see [How It Works](#how-it-works)

## Setup

```bash
# 1. Clone and enter the repo
git clone https://github.com/tmachingur-code/adtc-shona-coding-tutor.git
cd adtc-tutor

# 2. Create virtual environment
python3 -m venv adtc-tutor-env
source adtc-tutor-env/bin/activate

# 3. Install build tools
sudo apt update && sudo apt install build-essential cmake -y

# 4. Install dependencies
pip install -r requirements.txt

# 5. Download the GGUF model + MiniLM embedder into model/ (public, no credentials)
bash download_model.sh

# 6. Build the RAG index
python3 build_index.py

# 7. Run the tutor
python3 rag_tutor.py
```

## Usage

You'll be asked to choose a mode and a language once, up front, and that choice applies consistently across both modes.

```
Choose mode - (1) Ask a question, (2) Get practice questions: 1
Language (english/shona) [1=english, 0=shona]: shona
Ask a coding question: Chii chinonzi for loop

--- Tutor's Answer ---
Musoro: For Loops
Tsanangudzo: For loop inodzokorora chikamu chekodhi kamwe nekamwe...
```

## How It Works

Your question is embedded (locally, via a shared `embedder.py` module wrapping `all-MiniLM-L6-v2`, loaded from `model/` with no network calls) and matched against the curated syllabus using FAISS.

- **English, on-syllabus questions**: the model generates the answer live, grounded in the matched syllabus context.
- **Shona, on-syllabus questions**: return curated, human-verified content directly, rather than model-generated Shona (see `REPORT.md` for why).
- **English, out-of-scope questions**: the model attempts a real answer from its general knowledge (not syllabus-grounded), rather than refusing outright, since judges may test prompts beyond the curated syllabus.
- **Shona, out-of-scope questions**: the tutor apologizes in Shona for not having a Shona explanation on file, then gives a real model-generated English answer.

**Note on Shona input:** questions phrased fully in English, or in Shona with an embedded English technical term (e.g. "Chii chinonzi for loop"), match reliably. Fully Shona questions with no English technical term do not currently match reliably — see `REPORT.md` for details.

**Note on retrieval limits:** matching is tuned against the 58-topic syllabus; genuinely advanced or uncovered topics (e.g. decorators, metaclasses, async/await, generators, dependency injection) can still be misrouted to an unrelated syllabus topic rather than falling through to the general-knowledge path. This is a known, bounded limitation — see `REPORT.md`.

## Syllabus Coverage

58 topics across: Python Basics · Control Flow · Functions · Data Structures · Algorithms & Reasoning (sorting, searching, Big-O) · Debugging Fundamentals · Error Types & File I/O · List Comprehensions · OOP (classes, inheritance) · Recursion · Lambda Functions · pip/package installs · Debugging Strategy.

## Checking Performance

Own benchmark script (RAM + speed, includes embedder/index load):

```bash
python3 benchmark.py
```

Official ADTC profiler (throughput, memory, thermals, accuracy):

```bash
pip install "git+https://github.com/Africa-Deep-Tech-Foundation/adtc-profiler.git"
adtc-profiler run --submission . --mode participant --output submission.json
```

Latest official run: **8.57 tokens/sec**, **2.75GB peak RAM**, no thermal throttling, arc_easy accuracy **0.72** (50 samples) — estimated composite score **~65.3/100**. Full breakdown in `REPORT.md`.

See `REPORT.md` for full design rationale, constraints, benchmarks, and known limitations.

## Repository Structure

```
├── metadata.json          # Team, model, and test prompt metadata
├── download_model.sh      # Downloads the model weights + embedder to model/
├── REPORT.md              # Technical writeup
├── model/                 # Model weights (downloaded, not committed)
├── data/
│   ├── syllabus.json      # Curated CS syllabus, 58 topics (English + Shona)
│   ├── syllabus_map.json  # Generated lookup used by the RAG pipeline
│   └── syllabus.index     # Generated FAISS index
├── embedder.py             # Shared offline embedding module (all-MiniLM-L6-v2, local)
├── rag_tutor.py            # Main application
├── build_index.py         # Builds the FAISS index from syllabus.json
├── benchmark.py          #Own RAM/Speed benchmark script
├──submission.json         
├──README.md              #Project description and usage
└── requirements.txt

```

## License

MIT — see `LICENSE`.

## Acknowledgements

Built for the Africa Deep Tech Challenge 2026 — Laptop LLM Challenge, hosted by the Africa Deep Tech Foundation.

