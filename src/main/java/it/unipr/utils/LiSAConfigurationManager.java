package it.unipr.utils;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.contract.SmartContract;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import java.nio.file.Path;

public class LiSAConfigurationManager {

	/**
	 * Creates a LiSA configuration for analyzing the given smart contract.
	 *
	 * @param contract The smart contract to be analyzed.
	 *
	 * @return A configured instance of {@link LiSAConfiguration}.
	 */
	public static LiSAConfiguration createConfiguration(SmartContract contract) {
		return createConfiguration(contract, false);
	}

	/**
	 * Creates a LiSA configuration for analyzing the given smart contract.
	 *
	 * @param contract    The smart contract to be analyzed.
	 * @param dumpResults Dump the jsonOutput and html version of the CFG.
	 *
	 * @return A configured instance of {@link LiSAConfiguration}.
	 */
	public static LiSAConfiguration createConfiguration(SmartContract contract, boolean dumpResults) {
		String address = EthereumUtils.isValidEVMAddress(contract.getAddress()) ? contract.getAddress() : null;

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new EVMAbstractState(address),
				new TypeEnvironment<>(new InferredTypes()));
		conf.workdir = contract.getWorkingDirectory().toString();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;
		conf.useWideningPoints = false;
		conf.jsonOutput = false;

		if (dumpResults) {
			conf.analysisGraphs = LiSAConfiguration.GraphType.DOT;
			conf.jsonOutput = true;
		}

		return conf;
	}

	public static LiSAConfiguration createConfiguration(Path path, boolean dumpResults) {
		LiSAConfiguration conf = new LiSAConfiguration();
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
				new EVMAbstractState(null),
				new TypeEnvironment<>(new InferredTypes()));
		conf.workdir = path.toString();
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = false;
		conf.optimize = false;
		conf.useWideningPoints = false;
		conf.jsonOutput = false;

		if (dumpResults) {
			conf.analysisGraphs = LiSAConfiguration.GraphType.DOT;
			conf.jsonOutput = true;
		}

		return conf;
	}

	public static LiSAConfiguration createConfiguration(Path path) {
		return createConfiguration(path, false);
	}
}
