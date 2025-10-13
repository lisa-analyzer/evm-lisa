# Compile smart contract and run benchmark

Create a virtual environment:
```bash
conda create --name evm-lisa-environment python=3.11
```

```bash
conda activate evm-lisa-environment
```

Install dependencies:
```bash
brew install solc-select # compiler
pip install -r requirements.txt
```

## Compile smart contracts into bytecode
```
compile-smart-contracts.py [-h] [--solidifi] [--smartbugs] [--slise] [--longest-bytecode] [--cross-chain]
```
```
options:
  --solidifi          Compile SolidiFI dataset
  --smartbugs         Compile SmartBugs dataset
  --slise             Compile SliSE dataset
  --longest-bytecode  Save only the longest bytecode
  --cross-chain       Compile cross-chain dataset
```

## Run the benchmark
```
run-benchmark.py [-h] [--solidifi] [--smartbugs] [--slise] [--no-analysis] [--reentrancy] [--tx-origin] [--randomness-dependency]
```
```
options:
  --solidifi                Run analysis on SolidiFI dataset
  --smartbugs               Run analysis on SmartBugs dataset
  --slise                   Run analysis on SliSE dataset
  --no-analysis             Do not run the analysis, compute only the results
  --reentrancy              Run analysis on reentrancy contracts
  --tx-origin               Run analysis on tx-origin contracts
  --randomness-dependency   Run analysis on randomness-dependency contracts
```

## Dataset used
1. https://github.com/DependableSystemsLab/SolidiFI-benchmark
2. https://github.com/DependableSystemsLab/SolidiFI
3. https://github.com/smartbugs/smartbugs-curated