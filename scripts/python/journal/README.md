# Run benchmark

Install dependencies:
```
brew install solc-select
pip install tqdm
pip install scipy
```

Compile bytecodes:
```
python3.11 compile.py [-h] [--solidifi] [--smartbugs] [--longest-bytecode]
```

Run the benchmark:
```
python3.11 run-benchmark.py [-h] [--solidifi] [--smartbugs]
```

## Dataset
1. https://github.com/DependableSystemsLab/SolidiFI-benchmark
2. https://github.com/DependableSystemsLab/SolidiFI
3. https://github.com/smartbugs/smartbugs-curated