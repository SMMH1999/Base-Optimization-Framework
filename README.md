# Metaheuristic Optimization Benchmarking Framework (MATLAB)

## Who am I?
This repository is maintained as part of my **research work** in metaheuristic optimization.  
**Name:** _[Your Name]_  
**Affiliation:** _[Your University / Lab / Research Group]_  

### Contact & Communication
- **Email:** _osonhast@gmail.com_  
- **GitHub:** _https://github.com/SMMH1999_  
- **LinkedIn:** _https://www.linkedin.com/in/smmh1999/_
- **ResearchGate:** _https://www.researchgate.net/profile/Seyed-Hashemi-35_
- **ORCID:** _https://orcid.org/0009-0000-0855-7856_
- **Website:** _[optional links]_  

If you use this repository in your research or want to collaborate, feel free to reach out.

---

## Project Goal (Research-Oriented)
This project provides a **modular MATLAB framework** for **benchmarking metaheuristic optimization algorithms** on common **CEC benchmark suites** and **real‑world/engineering problems**.  
It is intended as a **research tool** to compare algorithm performance in a standardized and reproducible way.

---

## Related Repositories (Required Dependencies)
This repository is connected to two other repositories (as Git submodules):

1. **Optimization Algorithms (submodule)**  
   https://github.com/SMMH1999/Optimization-Algorithms

2. **Optimization Benchmarks (submodule)**  
   https://github.com/SMMH1999/optimization-benchmarks

These two repositories contain the algorithm implementations and benchmark definitions used by this framework.

---

## What This Repository Does (High-Level)
At a high level, this repository:

- Loads a list of algorithms and benchmark functions
- Executes algorithms on selected CEC or real‑world problems
- Logs results across multiple runs
- Produces summary outputs (tables, plots, logs)

This is **not a deep dive into every file**—the goal here is to explain the overall purpose and usage flow.

---

## Download & Setup

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
3. (Optional) run:
```matlab
ensureAlgorithmsSubmodule
```

---

## How to Run (Basic Usage)

### Single‑objective CEC benchmarks and Real‑world/engineering problems
```matlab
main
```


The experiment settings (dimensions, number of runs, algorithms list, etc.) are configured in the scripts under `src/` and the metadata files in `prerequisites/`.

---

## How to Add New Algorithms

### 1) Register the algorithm name
Add the algorithm’s **function name** to:
```
prerequisites/AlgorithmsName.txt
```

Each line must match the MATLAB function name of your algorithm.

### 2) Place the algorithm implementation
Place the algorithm folder inside:
```
optimization algorithms/
```

That folder is a **separate repository** and has its own README and structure.  
Please follow the guide here:
**https://github.com/SMMH1999/Optimization-Algorithms**

> The algorithm must follow the expected input/output signature used by this framework (see below).

---

## Cost Function Call + Algorithm I/O Signature

### Algorithm signature
Every algorithm is called like this:
```matlab
[best, bestPos, curve] = AlgorithmName(LB, UB, Dim, populationNo, maxItr, objectiveFunction);
```

Where:
- **LB, UB**: Lower/upper bounds  
- **Dim**: dimension of the search space  
- **populationNo**: population size  
- **maxItr**: number of iterations  
- **objectiveFunction**: function handle provided by the framework  
- **best**: best objective value  
- **bestPos**: best solution vector  
- **curve**: convergence curve (length = maxItr)

### Cost function signature
The objective is passed to algorithms as a function handle.  
It expects **x** in shape **Dim × N** or **1 × Dim** and returns a fitness value.

Typical calls:
- **CEC 2014+ style**:
  ```matlab
  f = objectiveFunction(x, functionNo);
  ```
- **CEC 2005 style**:
  ```matlab
  f = objectiveFunction(x);
  ```

---

## What This Repository Delivers
After running experiments, the framework produces:

- **Excel summaries** (statistics per function/dimension)
- **Convergence plots** (JPG/SVG)
- **MAT logs** (raw run data, FE counters, etc.)

All results are stored under:
```
results/
```

---

## Current Supported Benchmarks (Updatable)
At the moment, the framework supports:

- **CEC 2005**
- **CEC 2014**
- **CEC 2017**
- **CEC 2019**
- **CEC 2020**
- **CEC 2022**
- **Real‑world/engineering problems**

The benchmark list is **updatable**, and additional suites can be integrated through the same structure.

---

## License
This repository includes third‑party algorithms and benchmark resources.  
Please check the LICENSE files in each submodule for details.
