<img src="logo/emv-lisa-logo-no-background.png">

# EVMLiSA: an abstract interpretation-based static analyzer for EVM bytecode


[![GitHub license](https://img.shields.io/github/license/lisa-analyzer/evm-lisa)](https://github.com/lisa-analyzer/evm-lisa/blob/master/LICENSE)
![GitHub last commit](https://img.shields.io/github/last-commit/lisa-analyzer/evm-lisa)
![GitHub issues](https://img.shields.io/github/issues-raw/lisa-analyzer/evm-lisa)

EVMLiSA is a static analyzer based on abstract interpretation for [EVM bytecode](https://www.ethervm.io/) of smart contracts deployed on Ethereum blockchain and built upon [LiSA](https://unive-ssv.github.io/lisa/). 

# 🛠 Building EVMLiSA
Compiling EVMLiSA requires:
- JDK >= 11
- [Gradle](https://gradle.org/releases/) >= 6.6
- [Etherscan API key](https://etherscan.io/myapikey)

Development is done in [Eclipse](https://www.eclipse.org/downloads/).
You need to:
- Clone the repository:
  ```bash
  https://github.com/lisa-analyzer/evm-lisa.git
  cd evm-lisa
  ```
- Install the Gradle IDE Pack plugin through the Eclipse Marketplace; from the eclipse menu bar:
  - *Help*
  - *Eclipse Marketplace...*
  - *Search* for *Gradle IDE Pack 3.8*
  - *Install Gradle IDE Pack 3.8*
- Import the project into the eclipse workspace as a Gradle project.

# ⚙️ Running EVMLiSA
Before running EVMLiSA, ensure you have set up an Environment Variable with your Etherscan API Key. Follow the steps below to set up the environment variable:

1. Begin by creating a file named `.env` in the EVMLiSA project.
2. Inside the `.env` file, add the following line:
```
ETHERSCAN_API_KEY=<your_etherscan_api_key>
```
3. Replace `<your_etherscan_api_key>` with your Etherscan API key.

> Here how to generate an [Etherscan API key](https://etherscan.io/myapikey).

Once you have set up the environment variable, follow these steps to run EVMLiSA:

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
```

Run EVMLiSA:
```bash
./execution/evm-lisa/bin/evm-lisa -a <smart_contract_address> [options]
```
Replace `<smart_contract_address>` with the address of the Ethereum smart contract you want to analyze.

This command will initiate the analysis process for the specified smart contract, providing insights and results based on the Ethereum Virtual Machine (EVM) bytecode of the contract.

```bash
Options:
 -a,--address <arg>         address of an Ethereum smart contract
 -c,--dump-cfg              dump the CFG
 -d,--dump-analysis <arg>   dump the analysis (html, dot)
 -f,--filepath <arg>        filepath of the Etherem smart contract
 -o,--output <arg>          output directory path
 -s,--dump-stats            dump statistics
```
