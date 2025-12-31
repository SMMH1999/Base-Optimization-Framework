# Metaheuristic Optimization Benchmarking Framework (MATLAB)

A modular MATLAB framework for **benchmarking metaheuristic optimization algorithms** on **CEC benchmark suites (2005–2022)** and **real‑world/engineering problems**, with automated result logging, plotting, and Excel export.

> ⚠️ **Work in progress:** The codebase is actively developed. Some folders may contain duplicated/legacy scripts. This is expected for now.

---

## Highlights

- Large collection of **metaheuristic algorithms** (maintained as a Git submodule)
- Supports **single-objective** benchmark suites (CEC 2005, 2014, 2017, 2019, 2020, 2022)
- Includes **real‑world/engineering** problem runners (and early multi-objective scaffolding)
- Generates **Excel result tables**, **plots (JPG/SVG)**, and **MAT logs**
- Built-in **statistical analysis** utilities (e.g., t-test modules)
- Modular design: add algorithms/benchmarks with minimal wiring

---

## Repository Layout (Quick Map)

```
.
├── main.m / main2.m / mainRW.m               # Entry points (single-objective / experiments / real-world)
├── ensureAlgorithmsSubmodule.m               # Helper to init/update algorithm submodule
├── optimization algorithms/                  # Algorithms (Git submodule)
├── optimization benchmarks/                  # Benchmark suites (CEC single/multi-objective + real-world structure)
├── src/                                      # Core framework logic
│   ├── conf/                                 # Project context/config
│   ├── single-objective/                     # Main benchmark pipeline (CEC)
│   ├── multi-objective/                      # (Under development)
│   ├── real-world-objective/                 # Real-world runners & plots
│   └── results_template/                     # Excel templates used for exporting results
├── results/                                  # Generated outputs (timestamped runs)
├── prerequisites/                            # Lists/metadata for algorithms & problem sets
└── (Persian folders)                         # Additional cost functions & datasets
```

### Important folders

- **`optimization algorithms/`**  
  A large algorithm library (submodule). Contains grouped metaheuristics (animal/plant, evolutionary, physics/math, human-inspired, etc.).

- **`optimization benchmarks/`**  
  CEC benchmark implementations and data files (shift/rotation matrices, shuffle data, etc.).

- **`src/single-objective/`**  
  The main benchmarking engine: loads benchmarks, initializes populations, runs algorithms, saves results, plots, and performs statistics.

- **`src/real-world-objective/`**  
  Real-world benchmark loading, comparison, plotting, and summary tools.

- **`results/`**  
  Output directory for completed runs. Each run is stored under a timestamped folder.

---

## Requirements

- MATLAB **R2019b+** (recommended)
- Windows is recommended if you want to use the provided **MEX** binaries (e.g., CEC 2014/2017/2019/2020/2022 `.mexw64`)
- No special MATLAB toolboxes are required beyond core MATLAB (unless your own additions need them)

> If you are on macOS/Linux, you may need to compile the CEC `.cpp` MEX files for your platform.

---

## Installation

### 1) Clone with submodules (recommended)

```bash
git clone --recurse-submodules <REPO_URL>
cd <REPO_FOLDER>
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

### 2) MATLAB setup

1. Open MATLAB
2. Set the repository root as your **Current Folder**
3. (Optional) Run the helper script to ensure the algorithm submodule is initialized:

```matlab
ensureAlgorithmsSubmodule
```

---

## How to Run

### Single-objective benchmark runs

Run the main entry script:

```matlab
main
```

You may also find experimental/alternative runners:

```matlab
main2
```

### Real-world/engineering problems

```matlab
mainRW
```

> Exact experiment settings (dimensions, number of runs, selected algorithms, benchmark suite selection, etc.) are controlled by the project’s configuration/scripts under `src/` and `prerequisites/`.

---

## Outputs

Runs generate a timestamped result folder under:

```
results/
  result YY-MM-DD HH-MM/
    ├── CEC2005/
    ├── CEC2014/
    ├── CEC2017/
    ├── CEC2019/
    ├── CEC2020/
    ├── CEC2022/
    └── Real World Problems/
```

Typical artifacts include:

- **Excel tables** (summary statistics per function/dimension)
- **Convergence plots** (JPG/SVG)
- **MAT logs** (e.g., evaluation history, FE logs)

---

## Configuration & Metadata

This repository uses plain-text lists under `prerequisites/` to register algorithms and problem sets, for example:

- `prerequisites/AlgorithmsName.txt`
- `prerequisites/Address.txt`
- `prerequisites/RWP/*` (real-world problem metadata, cost function lists, etc.)

These are used by the loaders/runners to dynamically discover and run algorithms/benchmarks.

---

## Extending the Framework

### Add a new algorithm

1. Add your algorithm implementation under **`optimization algorithms/`** (preferred) or your custom module folder.
2. Register its name in:

```
prerequisites/AlgorithmsName.txt
```

3. Make sure it follows the expected interface used by `src/single-objective/Get_algorithm.m` (and related runner scripts).

> Tip: Use `optimization algorithms/Template Algorithm (TA)/` as a reference template (contains metadata + README format).

### Add a new benchmark/problem

- For benchmark-style functions: add them under **`optimization benchmarks/`** and update the loader logic in `src/single-objective/Load_CEC_Function.m` (if needed).
- For real-world problems: update the lists under `prerequisites/RWP/` and extend `src/real-world-objective/` modules.

---

## Troubleshooting

### MEX errors (e.g., `Invalid MEX-file` / missing `.mexw64`)

- Ensure you are using the correct OS/architecture for the provided binaries.
- If you’re not on Windows, compile the corresponding `*.cpp` files using:

```matlab
mex cecXX_func.cpp
```

(Replace `XX` with the suite year, e.g., `14`, `17`, `19`, `20`, `22`.)

### Submodule not found / empty algorithm folder

Run:

```bash
git submodule update --init --recursive
```

Or in MATLAB, run:

```matlab
ensureAlgorithmsSubmodule
```

---

## License

This repository includes multiple third-party algorithm implementations and benchmark resources.  
Licensing may differ per folder/submodule. Please check:

- `optimization algorithms/LICENSE` (and per-algorithm folders, when provided)
- `optimization benchmarks/LICENSE`

---

## Citation

If you use this framework in academic work:

- Cite the relevant **CEC benchmark suite** references
- Cite each algorithm you use (many folders include `CITATION.md`)

A project-level citation file can be added later (recommended for releases).

---

## Contributing

Issues and PRs are welcome—especially for:

- standardizing algorithm interfaces
- improving multi-objective support
- improving documentation and examples
- adding reproducibility utilities (seed control, config snapshots, etc.)

---

## Release Notes (Suggested)

When you create your first public release, consider including:

- supported MATLAB version(s)
- supported CEC suites and dimensions
- list of included algorithms (or link to the submodule)
- known limitations (multi-objective status, OS requirements for MEX)
- example commands and expected outputs
