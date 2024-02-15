package it.unipr;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.MyLogger;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.checker.JumpSolver;
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
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Set;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.commons.lang3.tuple.Triple;

public class EVMLiSA {
	private final static String OUTPUT_DIR = "execution/results/";
	private String STATISTICS_FULLPATH = "";
	private String FAILURE_FULLPATH = "";

	/**
	 * Generates a control flow graph (represented as a LiSA {@code Program})
	 * from a EVM bytecode smart contract and runs the analysis on it.
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

		// String parameters
		Option addressOption = new Option("a", "address", true, "address of an Ethereum smart contract");
		addressOption.setRequired(false);
		options.addOption(addressOption);

		Option outputOption = new Option("o", "output", true, "output directory path");
		outputOption.setRequired(false);
		options.addOption(outputOption);

		Option dumpAnalysisOption = new Option("d", "dump-analysis", true, "dump the analysis (html, dot)");
		dumpAnalysisOption.setRequired(false);
		options.addOption(dumpAnalysisOption);

		Option filePathOption = new Option("f", "filepath", true, "filepath of the Etherem smart contract");
		filePathOption.setRequired(false);
		options.addOption(filePathOption);

		// Boolean parameters
		Option dumpStatisticsOption = Option.builder("s")
				.longOpt("dump-stats")
				.desc("dump statistics")
				.required(false)
				.hasArg(false)
				.build();
		options.addOption(dumpStatisticsOption);
		Option dumpCFGOption = Option.builder("c")
				.longOpt("dump-cfg")
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
		String dumpAnalysis = cmd.getOptionValue("dump-analysis");
		boolean dumpStatistics = cmd.hasOption("dump-stats");
		String filepath = cmd.getOptionValue("filepath");

		if (addressSC == null && filepath == null) {
			// Error: no address and no filepath
			System.out.println("address or filepath required");
			formatter.printHelp("help", options);
			System.exit(1);
		}

		Files.createDirectories(Paths.get(OUTPUT_DIR));

		if (outputDir == null)
			outputDir = OUTPUT_DIR + addressSC + "_REPORT";

		STATISTICS_FULLPATH = OUTPUT_DIR + addressSC + "_STATISTICS" + ".csv";
		FAILURE_FULLPATH = OUTPUT_DIR + addressSC + "_FAILURE" + ".csv";

		String BYTECODE_FULLPATH = "";
		if (filepath == null) {
			BYTECODE_FULLPATH = OUTPUT_DIR + addressSC + ".sol";
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
		JumpSolver checker = new JumpSolver();
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

			Triple<Integer, Integer, Pair<Integer, Integer>> pair;

			pair = dumpStatistics(checker);

			finish = System.currentTimeMillis();

			String msg2 = "\nResults \n" +
					"Address: " + addressSC + "\n" +
					"Opcodes: " + baseCfg.getNodesCount() + "\n" +
					"Jumps: " + baseCfg.getAllJumps().size() + "\n" +
					"PreciselyResolvedJumps: " + pair.getLeft() + "\n" +
					"SoundResolvedJumps: " + pair.getMiddle() + "\n" +
					"UnreachableJumps: " + pair.getRight() + "\n" +
					"Time (in millis): " + (finish - start) + "\n";

			System.out.println(msg2);

			if (dumpStatistics) {
				String msg = MyLogger.newLogger()
						.address(addressSC)
						.opcodes(baseCfg.getNodesCount())
						.jumps(baseCfg.getAllJumps().size())
						.preciselyResolvedJumps(pair.getLeft())
						.soundResolvedJumps(pair.getMiddle())
						.definitelyUnreachableJumps(pair.getRight().getLeft())
						.definitelyUnreachableJumps(pair.getRight().getRight())
						.time(finish - start)
						.build().toString();

				toFileStatistics(msg);
				System.out.println("Statistics successfully written in " + STATISTICS_FULLPATH);
			}

		} catch (Throwable e) {
			finish = System.currentTimeMillis();

			String msg = MyLogger.newLogger()
					.address(addressSC)
					.notes("failure: " + e + " - details: " + e.getMessage())
					.time(finish - start)
					.build().toString();

			System.err.println(msg);

			if (dumpStatistics) {
				toFileFailure(msg);
				System.out.println("Failures successfully written in " + FAILURE_FULLPATH);
			}
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
	public static Triple<Integer, Integer, Pair<Integer, Integer>> dumpStatistics(JumpSolver checker) {
		EVMCFG cfg = checker.getComputedCFG();
		Set<Statement> unreachableJumpNodes = checker.getUnreachableJumps();
		int preciselyResolvedJumps = 0;
		int soundResolvedJumps = 0;
		int definitelyUnreachable = 0;
		int maybeUnreachable = 0;

		// we are safe supposing that we have a single entry point
		Statement entryPoint = cfg.getEntrypoints().stream().findAny().get();
		for (Statement jumpNode : cfg.getAllJumps())
			if (jumpNode instanceof Jump) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 1)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 1)
					soundResolvedJumps++;
				else if (cfg.reachableFrom(entryPoint, jumpNode) && unreachableJumpNodes.contains(jumpNode))
					definitelyUnreachable++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode))
					maybeUnreachable++;
			} else if (jumpNode instanceof Jumpi) {
				if (cfg.getOutgoingEdges(jumpNode).size() == 2)
					preciselyResolvedJumps++;
				else if (cfg.getOutgoingEdges(jumpNode).size() > 2)
					soundResolvedJumps++;
				else if (cfg.reachableFrom(entryPoint, jumpNode) && unreachableJumpNodes.contains(jumpNode))
					definitelyUnreachable++;
				else if (!cfg.reachableFrom(entryPoint, jumpNode))
					maybeUnreachable++;
			}

		System.err.println("##############");
		System.err.println("Total opcodes: " + cfg.getNodesCount());
		System.err.println("Total jumps: " + cfg.getAllJumps().size());
		System.err.println("Precisely solved jumps: " + preciselyResolvedJumps);
		System.err.println("Sound solved jumps: " + soundResolvedJumps);
		System.err.println("Definitely unreachable jumps: " + definitelyUnreachable);
		System.err.println("Maybe unreachable jumps: " + maybeUnreachable);
		System.err.println("##############");

		return Triple.of(preciselyResolvedJumps, soundResolvedJumps, Pair.of(definitelyUnreachable, maybeUnreachable));
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

}
