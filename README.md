# EVMLiSA
An abstract interpretation-based static analyzer for [EVM bytecode](https://www.ethervm.io/) built upon [LiSA](https://unive-ssv.github.io/lisa/) (Library for Static Analysis)

# 🛠 Build
EVMLiSA comes as a [Gradle 6.6](https://gradle.org/releases/) project.

Development is done in [Eclipse](https://www.eclipse.org/downloads/).
You need to:
- install the Gradle IDE Pack plugin through the Eclipse Marketplace; from the eclipse menu bar:
  - *Help*
  - *Eclipse Marketplace...*
  - *Search* for *Gradle IDE Pack 3.8*
  - *Install Gradle IDE Pack 3.8*
- import the project into the eclipse workspace as a Gradle project.
- run the `./evm-lisa/gradlew build`

# ⚙️ Run
To run the project by using Eclipse you can use *Run as Java application* in Eclipse and passing a path to a file containing EVM bytecode of a smart contract as first argument.

The result will be put under the `output` folder, which will have all the enabled reports and a [.dot](https://en.wikipedia.org/wiki/DOT_(graph_description_language)) file with the [LiSA-CFG](https://unive-ssv.github.io/lisa/)

You can run other gradle task with
```bash
./evm-lisa/gradlew -q :tasks --all
```
