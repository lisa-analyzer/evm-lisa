# Run benchmark

Install dependencies:
```
brew install solc-select
pip install tqdm
pip install scipy
```

Compile smart contracts into bytecode:
```
python3.11 compile-smart-contracts.py [-h] [--solidifi] [--smartbugs] [--slise] [--longest-bytecode]
```

Run the benchmark:
```
python3.11 run-benchmark.py [-h] [--solidifi] [--smartbugs] [--slise] [--no-analysis] [--reentrancy] [--tx-origin] [--timestamp-dependency]
```

## Dataset used
1. https://github.com/DependableSystemsLab/SolidiFI-benchmark
2. https://github.com/DependableSystemsLab/SolidiFI
3. https://github.com/smartbugs/smartbugs-curated