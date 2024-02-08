# EVMLiSA: an abstract interpretation-based static analyzer for EVM bytecode built upon [LiSA](https://unive-ssv.github.io/lisa/) (Library for Static Analysis)

[![GitHub license](https://img.shields.io/github/license/lisa-analyzer/evm-lisa)](https://github.com/lisa-analyzer/evm-lisa/blob/master/LICENSE)
![GitHub last commit](https://img.shields.io/github/last-commit/lisa-analyzer/evm-lisa)
![GitHub issues](https://img.shields.io/github/issues-raw/lisa-analyzer/evm-lisa)

EVMLiSA is a static analyzer based on abstract interpretation for [EVM bytecode](https://www.ethervm.io/) of smart contracts deployed on Ethereum blockchain written in Solidity. 

# 🛠 Building EVMLiSA
Compiling EVMLiSA requires:
- JDK >= 11
- [Gradle](https://gradle.org/releases/) >= 6.6
- [Etherscan API key](https://etherscan.io/myapikey)

Development is done in [Eclipse](https://www.eclipse.org/downloads/).
You need to:
- Install the Gradle IDE Pack plugin through the Eclipse Marketplace; from the eclipse menu bar:
  - *Help*
  - *Eclipse Marketplace...*
  - *Search* for *Gradle IDE Pack 3.8*
  - *Install Gradle IDE Pack 3.8*
- Import the project into the eclipse workspace as a Gradle project.
- Set an Environment Variable in *Run / Run Configurations* called `ETHERSCAN_API_KEY` with your Etherscan API key.

# ⚙️ Running EVMLiSA
To execute the analysis of an Ethereum smart contract using EVMLiSA, follow these steps:

Build the Project:
```bash
./gradlew build
```

Create Distribution Zip:
```bash
./gradlew distZip
```

Unzip the Distribution:
```bash
unzip build/distributions/evm-lisa.zip -d execution
cd execution/evm-lisa/bin
```

Run EVMLiSA:
```bash
./evm-lisa -a <smart_contract_address> [options]
```
Replace `<smart_contract_address>` with the address of the Ethereum smart contract you want to analyze.

This command will initiate the analysis process for the specified smart contract, providing insights and results based on the Ethereum Virtual Machine (EVM) bytecode of the contract.

```bash
Options:
-a, --address <arg>        address of smart contract
-c, --dumpcfg              dump the CFG
-d, --dumpanalysis <arg>   dump the analysis (html, dot)
-f, --filepath <arg>       filepath of smart contract
-o, --output <arg>         output directory path
-s, --dumpStatistics       dump statistics
```
