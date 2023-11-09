package it.unipr;

import it.unipr.analysis.SymbolicStack;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.AnalysisException;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.conf.LiSAConfiguration.GraphType;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.Program;
import java.io.IOException;

public class EVMLiSA {

	// Directory where the analysis outcome is stored
	private final static String OUTPUT_DIR = "output";

	// Directory where contracts (.sol files) are stored
	private final static String CONTRACTS_DIR = "evm-testcases";

	/**
	 * Generates a control flow graph (represented as a LiSA {@code Program})
	 * from a Solidity contract and runs the analysis on it. TODO: store
	 * contract filename in {@code args}
	 * 
	 * @param args
	 * 
	 * @throws AnalysisException
	 * @throws IOException
	 */
	public static void main(String[] args) throws AnalysisException, IOException {
		Program cfg = EVMFrontend.generateCfgFromFile(getContractPath("dummy.sol"));

		EVMLiSA.analyzeCFG(cfg, EVMLiSA.OUTPUT_DIR);
	}

	/**
	 * Analyzes a control flow graph (represented as a LiSA {@code Program}) and
	 * stores the outcome in the chosen {@code outputDir}.
	 * 
	 * @param program   the control flow graph represented as a LiSA
	 *                      {@code Program} to be analyzed.
	 * @param outputDir the directory where the analysis outcome should be
	 *                      stored.
	 * 
	 * @throws AnalysisException
	 */
	private static void analyzeCFG(Program program, String outputDir) throws AnalysisException {
		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = true;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new SymbolicStack(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = true;
		conf.workdir = outputDir;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = true;
		conf.analysisGraphs = GraphType.DOT;
		conf.optimize = false;

		LiSA lisa = new LiSA(conf);
		lisa.run(program);
	}

	/**
	 * Returns the path of the contract file based on its name appended to the
	 * {@code CONTRACTS_DIR} path.
	 * 
	 * @param contractFilename the name of the contract file
	 * 
	 * @return the path of the contract file
	 */
	private static String getContractPath(String contractFilename) {
		return EVMLiSA.CONTRACTS_DIR + "/" + contractFilename;
	}
}
