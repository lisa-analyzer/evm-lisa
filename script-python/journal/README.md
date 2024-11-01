# Run benchmark

Install solc:
```
brew install solc-select
solc-select install 0.5.17
solc-select use 0.5.17
pip install tqdm
pip install scipy
```

Compile bytecodes:
```
python3.11 compile-all.py
```

Start the benchmark:
```
python3.11 run-benchmark.py
```