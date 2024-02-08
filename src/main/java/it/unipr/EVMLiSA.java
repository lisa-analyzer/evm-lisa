package it.unipr;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Set;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpChecker;
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
import it.unive.lisa.program.cfg.statement.Statement;

import org.apache.commons.cli.*;
import org.apache.commons.lang3.tuple.Triple;

public class EVMLiSA {

	// Directory where the analysis outcome is stored
	private final static String OUTPUT_DIR = "evm-outputs";

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
	public static void main(String[] args) throws AnalysisException, IOException, Exception {
		new EVMLiSA().go(args);
	}
	
	private void go(String[] args) throws Exception {
		Options options = new Options();

		// String
		Option input = new Option("i", "input", true, "input file path");
		input.setRequired(false);
		options.addOption(input);
		
		Option address = new Option("a", "address", true, "address of smart contract");
		address.setRequired(true);
		options.addOption(address);

		Option output = new Option("o", "output", true, "output file path");
		output.setRequired(true);
		options.addOption(output);
		
		Option statistics = new Option("s", "statistics", true, "statistics file path");
		statistics.setRequired(false);
		options.addOption(statistics);
		
		// Boolean
		Option dumpOpt = Option.builder("d")
			    .longOpt("dumpCFG")
			    .desc("dump the CFG")
			    .required(false)
			    .hasArg(false)
			    .build();
			options.addOption(dumpOpt);
		
		CommandLineParser parser = new DefaultParser();
		HelpFormatter formatter = new HelpFormatter();
		CommandLine cmd = null;

		try {
			cmd = parser.parse(options, args);
		} catch (ParseException e) {
			System.out.println(e.getMessage());
			formatter.printHelp("help", options);

			System.exit(1);
		}
		
		String filePath = cmd.getOptionValue("input");
		String addressSC = cmd.getOptionValue("address");
		String statisticsDir = cmd.getOptionValue("statistics");

		String outputDir = cmd.getOptionValue("output");

		String analysis = cmd.getOptionValue("analysis");
		boolean dumpCFG = cmd.hasOption("dumpCFG");
		
		System.out.println("input " + filePath);
		System.out.println("address " + addressSC);
		System.out.println("statistics " + statisticsDir);
		System.out.println("output " + outputDir);
		System.out.println("analysis " + analysis);
		System.out.println("dumpCFG " + dumpCFG);
		
		String BYTECODE_FULLPATH = "/" + addressSC + "/" + addressSC + ".sol";

		// Directory setup and bytecode retrieval
		Files.createDirectories(Paths.get(addressSC));

		// If the file does not exists, we will do an API request to Etherscan
		File file = new File(BYTECODE_FULLPATH);
//		if (!file.exists()) {
		if (!file.exists()) {
			FileWriter myWriter = new FileWriter(file);
			EVMFrontend.parseContractFromEtherscan(addressSC, BYTECODE_FULLPATH);
		}

		Program cfg = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		EVMLiSA.analyzeCFG(cfg, outputDir);
		
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
		long start = System.currentTimeMillis();
		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = true;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = true;
		conf.workdir = outputDir;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		JumpChecker checker = new JumpChecker();
		conf.semanticChecks.add(checker);
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = true;
		conf.analysisGraphs = GraphType.DOT;
		conf.optimize = false;

		LiSA lisa = new LiSA(conf);
		lisa.run(program);
		
		EVMCFG baseCfg = checker.getComputedCFG();

		Triple<Integer, Integer, Integer> pair;
		
		pair = dumpStatistics(checker);
		
		long finish = System.currentTimeMillis();

		String msg = MyLogger.newLogger()
//				.address(address)
				.opcodes(baseCfg.getNodesCount())
				.jumps(baseCfg.getAllJumps().size())
				.preciselyResolvedJumps(pair.getLeft())
				.soundResolvedJumps(pair.getMiddle())
				.unreachableJumps(pair.getRight())
				.time(finish - start)
				.build().toString();
		System.out.println(msg);
		
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
	
	/**
	 * Calculates and prints statistics about the control flow graph (CFG) of the provided EVMCFG object.
	 *
	 * @param checker The control flow graph (CFG) of the Ethereum Virtual Machine (EVM) bytecode.
	 * @return A Triple containing the counts of precisely resolved jumps, sound resolved jumps, and unreachable jumps.
	 */
	private static Triple<Integer, Integer, Integer> dumpStatistics(JumpChecker checker) {
		EVMCFG cfg = checker.getComputedCFG();
		Set<Statement> unreachableJumpNodes = checker.getUnreachableJumps();
		int preciselyResolvedJumps = 0;
		int soundResolvedJumps = 0;
		int unreachableJumps = 0;

		// we are safe supposing that we have a single entry point
		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();
		for (Statement jumpNode : cfg.getAllJumps())
			if (jumpNode instanceof Jump) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 1)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 1)
					soundResolvedJumps++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode) || unreachableJumpNodes.contains(jumpNode))
					unreachableJumps++;
			} else if (jumpNode instanceof Jumpi) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 2)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 2)
					soundResolvedJumps++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode)|| unreachableJumpNodes.contains(jumpNode))
					unreachableJumps++;
			}

		System.err.println("##############");
		System.err.println("Total opcodes: " + cfg.getNodesCount());
		System.err.println("Total jumps: " + cfg.getAllJumps().size());
		System.err.println("Precisely solved jumps: " + preciselyResolvedJumps);
		System.err.println("Sound solved jumps: " + soundResolvedJumps);
		System.err.println("Unreachable jumps: " + unreachableJumps);
		System.err.println("##############");

		return Triple.of(preciselyResolvedJumps, soundResolvedJumps, unreachableJumps);
	}
	
	/**
	 * Represents a logger object for recording statistical data related to Ethereum smart contracts.
	 */
	private static class MyLogger {
		private static String divider = ", ";
		private String address;
		private int opcodes;
		private int jumps;
		private int preciselyResolvedJumps;
		private int soundResolvedJumps;
		private int unreachableJumps;
		private int totalResolvedJumps;
		private double preciselySolvedJumpsPercent;
		private double solvedJumpsPercent;
		private long time;
		private String notes;
		private String currentThread;

		private MyLogger() {
			this.address = null;
			this.opcodes = 0;
			this.jumps = 0;
			this.preciselyResolvedJumps = 0;
			this.soundResolvedJumps = 0;
			this.unreachableJumps = 0;
			this.solvedJumpsPercent = 0;
			this.time = 0;
			this.notes = "";
			this.currentThread = null;
		}

		private MyLogger(String address, int opcodes, int jumps, int preciselyResolvedJumps, int soundResolvedJumps,
				int unreachableJumps, int totalResolvedJumps, double solvedJumpsPercent, long time, String notes) {
			this.address = address;
			this.opcodes = opcodes;
			this.jumps = jumps;
			this.preciselyResolvedJumps = preciselyResolvedJumps;
			this.soundResolvedJumps = soundResolvedJumps;
			this.unreachableJumps = unreachableJumps;
			if (jumps != 0) {
				if (solvedJumpsPercent == 0)
					this.solvedJumpsPercent = ((double) (preciselyResolvedJumps + soundResolvedJumps + unreachableJumps)
							/ jumps);
				this.preciselySolvedJumpsPercent = ((double) (preciselyResolvedJumps) / jumps);
			} else {
				if (solvedJumpsPercent == 0)
					this.solvedJumpsPercent = -1;
				this.preciselySolvedJumpsPercent = -1;
			}
			this.totalResolvedJumps = preciselyResolvedJumps + soundResolvedJumps;
			this.notes = notes;
			this.time = time;
			this.currentThread = Thread.currentThread().getName();
		}

		public static MyLogger newLogger() {
			return new MyLogger();
		}

		public MyLogger address(String address) {
			this.address = address;
			return this;
		}

		public MyLogger opcodes(int opcodes) {
			this.opcodes = opcodes;
			return this;
		}

		public MyLogger jumps(int jumps) {
			this.jumps = jumps;
			return this;
		}

		public MyLogger preciselyResolvedJumps(int preciselyResolvedJumps) {
			this.preciselyResolvedJumps = preciselyResolvedJumps;
			return this;
		}

		public MyLogger soundResolvedJumps(int soundResolvedJumps) {
			this.soundResolvedJumps = soundResolvedJumps;
			return this;
		}

		public MyLogger unreachableJumps(int unreachableJumps) {
			this.unreachableJumps = unreachableJumps;
			return this;
		}

		public MyLogger solvedJumpsPercent(double solvedJumpsPercent) {
			this.solvedJumpsPercent = solvedJumpsPercent;
			return this;
		}

		public MyLogger time(long time) {
			this.time = time;
			return this;
		}

		public MyLogger notes(String notes) {
			this.notes = notes;
			return this;
		}

		public MyLogger build() {
			return new MyLogger(address, opcodes, jumps, preciselyResolvedJumps, soundResolvedJumps,
					unreachableJumps, totalResolvedJumps, solvedJumpsPercent, time, notes);
		}
		
		public int jumpSize() { 
			return jumps; 
		}

		@Override
		public String toString() {
			return address + divider +
					opcodes + divider +
					jumps + divider +
					preciselyResolvedJumps + divider +
					soundResolvedJumps + divider +
					unreachableJumps + divider +
					totalResolvedJumps + divider +
					preciselySolvedJumpsPercent + divider +
					solvedJumpsPercent + divider +
					time + divider +
					currentThread + divider +
					notes + " \n";
		}
	}
}
