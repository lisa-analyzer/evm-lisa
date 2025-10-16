<img src="logo/emv-lisa-logo-no-background.png">

# EVMLiSA: an abstract interpretation-based static analyzer for EVM bytecode

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/lisa-analyzer/evm-lisa/gradle-master.yml)
![GitHub last commit](https://img.shields.io/github/last-commit/lisa-analyzer/evm-lisa)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/lisa-analyzer/evm-lisa)
![GitHub issues](https://img.shields.io/github/issues-raw/lisa-analyzer/evm-lisa)

EVMLiSA is a static analyzer based on abstract interpretation for [EVM bytecode](https://www.ethervm.io/) of smart contracts deployed on Ethereum blockchain and built upon [LiSA](https://unive-ssv.github.io/lisa/). Given a EVM bytecode smart contract, EVMLiSA builds a sound and precise control-flow graph of the smart contract.

EVMLiSA is based on the peer-reviewed publication
> Vincenzo Arceri, Saverio Mattia Merenda, Greta Dolcetti, Luca Negrini, Luca Olivieri, Enea Zaffanella. _**"Towards a Sound Construction of EVM Bytecode Control-Flow Graphs"**_. In Proceedings of the 26th ACM International Workshop on Formal Techniques for Java-like Programs (FTfJP 2024), co-located with ECOOP 2024.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [Environment Setup](#environment-setup)
- [Execution Methods](#execution-methods)
  - [Using Docker](#using-docker)
  - [Using CLI](#using-command-line)
- [Options](#options)
- [The Abstract Stack Set Domain](#the-abstract-stack-set-domain)
- [Jump Classification](#jump-classification)
- [Usage Example](#usage-example)
  - [Example Output](#example-output)
- [EVMLiSA as a Library](#EVMLiSA-as-a-library)

---

## Requirements

To build and run EVMLiSA, you will need:

- JDK 11 or higher (optional when using Docker)
- [Gradle](https://gradle.org/releases/) 8.0 or higher (optional when using Docker)
- [Etherscan API key](https://etherscan.io/myapikey)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/lisa-analyzer/evm-lisa.git
   cd evm-lisa
   ```

2. (Optional) Import the project into Eclipse or IntelliJ as a Gradle project.

### Environment Setup

Before running EVMLiSA, you must configure your Etherscan API key:

1. Create a `.env` file in the project root directory.
2. Add the following line to the file:
   ```
   ETHERSCAN_API_KEY=<your_etherscan_api_key>
   ```
3. Replace `<your_etherscan_api_key>` with your actual key from [Etherscan](https://etherscan.io/myapikey).

Alternatively, you can pass your API key directly using the `--etherscan-api-key <key>` option when executing the analyzer.

## Execution Methods

### Using Docker

1. Build the Docker container:
   ```bash
   mkdir -p outputs/docker &&
   docker build -t evm-lisa:latest .
   ```

2. Run EVMLiSA with Docker:
   ```bash
   docker run --rm -it \
   -v $(pwd)/.env:/app/.env \
   -v $(pwd)/outputs/docker:/app/outputs \
   evm-lisa:latest \
   [options]
   ```

   - `-v $(pwd)/.env:/app/.env`: Mounts your environment file
   - `-v $(pwd)/outputs/docker:/app/outputs`: Shares the results directory

### Using Command Line

1. Build the project:
   ```bash
   ./gradlew assemble
   ```

2. Run EVMLiSA:
   ```bash
   java -jar build/libs/evm-lisa-all.jar [options]
   ```

## Options

```
Options:
 -a,--address <arg>                        Address of an Ethereum smart contract.
    --abi <arg>                            ABI of the bytecode to be analyzed (JSON format).
    --abi-path <arg>                       Filepath of the ABI file.
 -b,--bytecode <arg>                       Bytecode to be analyzed (e.g., 0x6080...).
    --benchmark <arg>                      Filepath of the benchmark.
    --bytecode-path <arg>                  Filepath of the bytecode file.
 -c,--cores <arg>                          Number of cores used in benchmark.
    --checker-all                          Enable all security checkers.
    --checker-reentrancy                   Enable reentrancy checker.
    --checker-timestampdependency          Enable timestamp-dependency checker.
    --checker-txorigin                     Enable tx-origin checker.
    --cross-chain-analysis                 Run a cross-chain analysis.
    --cross-chain-policy <arg>             Import a cross-chain policy.
    --etherscan-api-key <arg>              Insert your Etherscan API key.
    --link-unsound-jumps-to-all-jumpdest   Link all unsound jumps to all jumpdest.
    --output-directory-path <arg>          Filepath of the output directory.
    --show-all-instructions-in-cfg         Show all instructions in the CFG representation.
    --stack-set-size <arg>                 Dimension of stack-set (default: 8).
    --stack-size <arg>                     Dimension of stack (default: 32).
    --use-live-storage                     Use the live storage in SLOAD.
```

## The Abstract Stack Set Domain

In analyzing EVM bytecode programs, EVMLiSA employs a domain of sets of abstract stacks to enhance precision, particularly for code containing loops.

The analyzer introduces the abstract stack powerset domain $\texttt{SetSt}_{k,h,l}$ consisting of sets of abstract stacks with at most $l$ elements and a maximum height of $h$. This domain allows the analyzer to maintain collections of abstract stacks, avoiding the need to compute the least upper bound (lub) and allowing each element of an abstract stack to be a $k$ integer set.

## Jump Classification

EVMLiSA classifies jump instructions in the following categories:

- **Resolved**: All destinations of the jump node have been successfully resolved
- **Definitely unreachable**: The jump node is unreachable (reached with the bottom abstract state)
- **Maybe unreachable**: The jump node is not reachable from the entry point, but may be reachable via a potentially unsound jump node
- **Unsound**: The jump node is reached with a stack containing an unknown numerical value that may correspond to a valid jump destination
- **Maybe unsound**: The stack set exceeded the maximum configured stack size

## Usage Example

Analyze a smart contract with specific configuration parameters:

**Using Command Line:**
```bash
java -jar build/libs/evm-lisa-all.jar \
-a 0x7c21C4Bbd63D05Fa9F788e38d14e18FC52E9557B \
--stack-size 64 \
--stack-set-size 10 \
--link-unsound-jumps-to-all-jumpdest
```

**Using Docker:**
```bash
docker run --rm -it \
-v $(pwd)/.env:/app/.env \
-v $(pwd)/outputs/docker:/app/outputs \
evm-lisa:latest \
-a 0x7c21C4Bbd63D05Fa9F788e38d14e18FC52E9557B \
--stack-size 64 \
--stack-set-size 10 \
--link-unsound-jumps-to-all-jumpdest
```

> **Tip**: Use `docker run -a stderr` to output only the JSON report to standard output.

### Example Output

```
##############
Total opcodes: 344
Total jumps: 45
Resolved jumps: 44
Definitely unreachable jumps: 1
Maybe unreachable jumps: 0
Unsound jumps: 0
Maybe unsound jumps: 0
##############
```

## EVMLiSA as a Library

EVMLiSA can be integrated as a Java library to analyze EVM smart contracts programmatically:

```java
// Analyze by contract address
EVMLiSA.analyzeContract(new SmartContract("0x123456..."));

// Analyze from bytecode file path
EVMLiSA.analyzeContract(new SmartContract(Path.of("bytecode", "code.bytecode")));

// Analyze from bytecode string
EVMLiSA.analyzeContract(new SmartContract().setBytecode("0x6080..."));

// Analyze multiple contracts
EVMLiSA.analyzeSetOfContracts(Path.of("list-of-contracts.txt"));
```

## Cross-Chain Policy Configuration

For cross-chain analysis, EVMLiSA supports policy files that define event-function mappings between smart contracts. The policy file should be a JSON file with the following structure:

### Policy JSON format

```json
{
  "policy": [
    {
      "sourceFunction": {
        "name": "deposit",
        "events": ["Deposit"]
      },
      "destinationFunction": {
        "name": "deposit"
      }
    }
  ]
}
```

### Policy structure explanation

- `policy`: An array of objects, each containing:
  - `sourceFunction`: An object describing the source function and its events:
    - `name`: The name of the function that emits the event
    - `events`: An array of event names that trigger cross-chain operations
  - `destinationFunction`: An object describing the destination function:
    - `name`: The name of the function that should be called in response to the event

### Example

```json
{
  "policy": [
    {
      "sourceFunction": {
        "name": "initGenesisBlock",
        "events": [
          "InitGenesisBlockEvent"
        ]
      },
      "destinationFunction": {
        "name": "initGenesisBlock"
      }
    },
    {
      "sourceFunction": {
        "name": "pause",
        "events": [
          "Paused"
        ]
      },
      "destinationFunction": {
        "name": "pause"
      }
    }
  ]
}
```

### Usage with Policy

When running cross-chain analysis, specify the policy file using the `--cross-chain-policy` option:

```bash
java -jar build/libs/evm-lisa-all.jar \
--cross-chain-analysis \
--bytecode-directory-path /path/to/bytecode  \
--abi-directory-path /path/to/abi \
--cross-chain-policy /path/to/policy.json
```

> Note: if no policy file is provided, EVMLiSA will use a default policy that matches events and functions by name.

## Contributors

<a href="https://github.com/lisa-analyzer/evm-lisa/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=lisa-analyzer/evm-lisa" />
</a>