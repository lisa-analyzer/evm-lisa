package it.unipr;

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
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Set;
import org.apache.commons.cli.*;
import org.apache.commons.lang3.tuple.Triple;

public class EVMLiSA {

	private String STATISTICS_FULLPATH = "";
	private String FAILURE_FULLPATH = "";

	/**
	 * Generates a control flow graph (represented as a LiSA {@code Program})
	 * from a Solidity contract and runs the analysis on it.
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
		Option addressOption = new Option("a", "address", true, "address of smart contract");
		addressOption.setRequired(false);
		options.addOption(addressOption);

		Option outputOption = new Option("o", "output", true, "output directory path");
		outputOption.setRequired(false);
		options.addOption(outputOption);

//		Option dumpCFGOption = new Option("c", "dumpcfg", true, "dump the CFG (html, dot)");
//		dumpCFGOption.setRequired(false);
//		options.addOption(dumpCFGOption);

		Option dumpAnalysisOption = new Option("d", "dumpanalysis", true, "dump the analysis (html, dot)");
		dumpAnalysisOption.setRequired(false);
		options.addOption(dumpAnalysisOption);

		Option filePathOption = new Option("f", "filepath", true, "filepath of smart contract");
		filePathOption.setRequired(false);
		options.addOption(filePathOption);

		// Boolean
		Option dumpStatisticsOption = Option.builder("s")
				.longOpt("dumpStatistics")
				.desc("dump statistics")
				.required(false)
				.hasArg(false)
				.build();
		options.addOption(dumpStatisticsOption);
		Option dumpCFGOption = Option.builder("c")
				.longOpt("dumpcfg")
				.desc("dump the CFG")
				.required(false)
				.hasArg(false)
				.build();
		options.addOption(dumpCFGOption);

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

		String addressSC = cmd.getOptionValue("address");
		String outputDir = cmd.getOptionValue("output");
		Boolean dumpCFG = cmd.hasOption("dumpcfg");
		String dumpAnalysis = cmd.getOptionValue("dumpanalysis");
		boolean dumpStatistics = cmd.hasOption("dumpStatistics");
		String filepath = cmd.getOptionValue("filePathOption");

		if (addressSC == null && filepath == null) {
			// Error: no address and no filepath
			System.out.println("address or filepath required");
			formatter.printHelp("help", options);
			System.exit(1);
		}

		if (outputDir == null)
			outputDir = "OUTPUT_" + addressSC;

		STATISTICS_FULLPATH = "STATISTICS_" + addressSC + ".csv";
		FAILURE_FULLPATH = "FAILURE_" + addressSC + ".csv";

		String BYTECODE_FULLPATH = "";
		if (filepath == null) {
			BYTECODE_FULLPATH = addressSC + ".sol";
			EVMFrontend.parseContractFromEtherscan(addressSC, BYTECODE_FULLPATH);
		} else
			BYTECODE_FULLPATH = filepath;

		Program program = EVMFrontend.generateCfgFromFile(BYTECODE_FULLPATH);

		long start = System.currentTimeMillis();
		long finish;

		LiSAConfiguration conf = new LiSAConfiguration();
		conf.serializeInputs = dumpCFG;
		conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(), new EVMAbstractState(),
				new TypeEnvironment<>(new InferredTypes()));
		conf.jsonOutput = true;
		conf.workdir = outputDir;
		conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
		JumpChecker checker = new JumpChecker();
		conf.semanticChecks.add(checker);
		conf.callGraph = new RTACallGraph();
		conf.serializeResults = true;
		conf.optimize = false;

		if (dumpAnalysis != null) {
			if (dumpAnalysis.equals("dot"))
				conf.analysisGraphs = GraphType.DOT;
			else if (dumpAnalysis.equals("html"))
				conf.analysisGraphs = GraphType.HTML_WITH_SUBNODES;
		}

		try {
			LiSA lisa = new LiSA(conf);
			lisa.run(program);

			EVMCFG baseCfg = checker.getComputedCFG();

			Triple<Integer, Integer, Integer> pair;

			pair = dumpStatistics(checker);

			finish = System.currentTimeMillis();

			String msg = MyLogger.newLogger()
					.address(addressSC)
					.opcodes(baseCfg.getNodesCount())
					.jumps(baseCfg.getAllJumps().size())
					.preciselyResolvedJumps(pair.getLeft())
					.soundResolvedJumps(pair.getMiddle())
					.unreachableJumps(pair.getRight())
					.time(finish - start)
					.build().toString();

			System.out.println(msg);

			if (dumpStatistics)
				toFileStatistics(msg);

		} catch (Throwable e) {
			finish = System.currentTimeMillis();

			String msg = MyLogger.newLogger()
					.address(addressSC)
					.notes("failure: " + e + " - details: " + e.getMessage())
					.time(finish - start)
					.build().toString();

			System.err.println(msg);

			if (dumpStatistics)
				toFileFailure(msg);
		}
	}

	/**
	 * Calculates and prints statistics about the control flow graph (CFG) of
	 * the provided EVMCFG object.
	 *
	 * @param checker The control flow graph (CFG) of the Ethereum Virtual
	 *                    Machine (EVM) bytecode.
	 * 
	 * @return A Triple containing the counts of precisely resolved jumps, sound
	 *             resolved jumps, and unreachable jumps.
	 */
	private Triple<Integer, Integer, Integer> dumpStatistics(JumpChecker checker) {
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
				else if (!cfg.reachableFrom(entryPoint, jumpNode) || unreachableJumpNodes.contains(jumpNode))
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
	 * Writes the given statistics to a file.
	 *
	 * @param stats The statistics to be written to the file.
	 */
	private void toFileStatistics(String stats) {
		synchronized (STATISTICS_FULLPATH) {
			String init = "Smart Contract, Total Opcodes, Total Jumps, Precisely solved Jumps, Sound solved Jumps, Unreachable Jumps, Total solved Jumps, % Precisely Solved, % Total Solved, Time (millis), Thread, Notes \n";
			try {
				File idea = new File(STATISTICS_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred.");
				e.printStackTrace();
			}
		}
	}

	/**
	 * Writes the given failures to a file.
	 *
	 * @param stats The failures to be written to the file.
	 */
	private void toFileFailure(String stats) {
		synchronized (FAILURE_FULLPATH) {
			String init = "Smart Contract, Total Opcodes, Total Jumps, Precisely solved Jumps, Sound solved Jumps, Unreachable Jumps, Total solved Jumps, % Precisely Solved, % Total Solved, Time (millis), Thread, Notes \n";
			try {
				File idea = new File(FAILURE_FULLPATH);
				if (!idea.exists()) {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(init + stats);
					myWriter.close();

				} else {
					FileWriter myWriter = new FileWriter(idea, true);
					myWriter.write(stats);
					myWriter.close();
				}

			} catch (IOException e) {
				System.err.println("An error occurred.");
				e.printStackTrace();
			}
		}
	}

	/**
	 * Represents a logger object for recording statistical data related to
	 * Ethereum smart contracts.
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
