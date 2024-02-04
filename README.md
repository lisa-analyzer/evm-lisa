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
You can add the addresses of the smart contracts you want to analyze in the `benchmark/smartContracts.txt` file.  
Finally, you can start the analysis with:
```bash
./gradlew test --tests it.unipr.analysis.cron.EVMBytecodeTest
```
Once the analysis is finished, you will find the statistics result in `evm-output/statistics.xls`.

You can run other gradle task with
```bash
./evm-lisa/gradlew -q :tasks --all
```
