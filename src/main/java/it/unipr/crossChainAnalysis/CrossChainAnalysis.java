package it.unipr.crossChainAnalysis;

import it.unipr.EVMLiSA;
import it.unipr.analysis.*;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.checker.JumpSolver;
import it.unipr.frontend.EVMFrontend;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.interprocedural.ModularWorstCaseAnalysis;
import it.unive.lisa.interprocedural.callgraph.RTACallGraph;
import it.unive.lisa.program.ClassUnit;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class CrossChainAnalysis {
	private static final Logger log = LogManager.getLogger(CrossChainAnalysis.class);

	private final Path _abiFolder;
	private final Path _bytecodeFolder;
	private final Bridge _bridge;
	private EVMCFG _xCFG;
	private Set<Edge> _crossChainEdges;

	public CrossChainAnalysis(Path abi, Path bytecode) {
		this._abiFolder = abi;
		this._bytecodeFolder = bytecode;
		this._bridge = new Bridge(abi, bytecode);
		this._xCFG = null;
		this._crossChainEdges = new HashSet<>();
	}

	/**
	 * Runs the cross-chain smart contract analysis. Starts the analysis, builds
	 * the partial cross-chain CFG (xCFG), and adds cross-chain edges.
	 */
	public void run() {
		try {
			startAnalysis();
		} catch (InterruptedException e) {
			log.error("Thread pool interrupted: {}", e.getMessage());
		}

		this._xCFG = buildPartialXCFG();

		this._crossChainEdges = addCrossChainEdges();

		log.debug("Final xCFG");
		printInfo(_xCFG);
	}

	/**
	 * Adds cross-chain edges by linking log statements to function entry points
	 * in different contracts.
	 *
	 * @return A set of added cross-chain edges.
	 */
	private Set<Edge> addCrossChainEdges() {
		Set<Edge> crossChainEdges = new HashSet<>();

		for (Statement logx : _xCFG.getAllLogX()) {
			for (SmartContract contract : _bridge) {
				for (Pair<String, Statement> functionEntrypoint : contract.getFunctionEntrypointsSet()) {
					Statement target = functionEntrypoint.getRight();
					Edge crossChainEdge = new SequentialEdge(logx, target);
					_xCFG.addEdge(crossChainEdge);
					crossChainEdges.add(crossChainEdge);
				}

			}
		}

		log.debug("Added {} cross chain edges", crossChainEdges.size());
		return crossChainEdges;
	}

	/**
	 * Builds the partial cross-chain control flow graph (xCFG) by merging
	 * individual smart contract CFGs into a unified representation.
	 *
	 * @return The constructed xCFG.
	 */
	private EVMCFG buildPartialXCFG() {
		String filePath = _bytecodeFolder.toString();
		ClassUnit unit = new ClassUnit(new ProgramCounterLocation(-1, -1), null, "program", false);
		String normalizedFilePath = FilenameUtils.separatorsToUnix(filePath);
		CodeMemberDescriptor cfgDesc = new CodeMemberDescriptor(new ProgramCounterLocation(-1, -1), unit, false,
				normalizedFilePath);

		EVMCFG xCFG = new EVMCFG(cfgDesc);

		log.debug("xCFG generated");
		printInfo(xCFG);

		// debug variables
		int sumNodes = 0;
		int sumEdges = 0;
		int sumLogX = 0;

		for (SmartContract contract : _bridge) {
			for (Statement n : contract.getCFG().getNodes())
				xCFG.addNode(n);

			for (Edge e : contract.getCFG().getEdges())
				xCFG.addEdge(e);

			for (Statement log : contract.getCFG().getAllLogX())
				xCFG.getAllLogX().add(log);

			for (Statement entry : contract.getCFG().getEntrypoints()) {
				// TODO (bug) entrypoint is always one, we should have
				// _bridge.size() entrypoint
				xCFG.getEntrypoints().add(entry);
			}

			log.debug("xCFG updated adding {}", contract.getName());
			printInfo(xCFG);

			// TODO (bug) these results must be the same, this does not happen
			// because some nodes and edges of different CFG could have the same
			// hashcode
			sumNodes += contract.getCFG().getNodesCount();
			sumEdges += contract.getCFG().getEdgesCount();
			sumLogX += contract.getCFG().getAllLogX().size();
			log.warn("Real Nodes count: {}", sumNodes);
			log.warn("Real Edge count: {}", sumEdges);
			log.warn("Real LOGx count: {}", sumLogX);

		}

		return xCFG;
	}

	/**
	 * Starts the smart contract analysis process, setting up the execution
	 * environment and running the analysis in parallel using a thread pool.
	 *
	 * @throws InterruptedException If the thread pool execution is interrupted.
	 */
	private void startAnalysis() throws InterruptedException {
		// Setup options
		EVMFrontend.setUseCreationCode();
		AbstractStack.setStackLimit(32);
		AbstractStackSet.setStackSetSize(12);
		JumpSolver.setLinkUnsoundJumpsToAllJumpdest();
		int cores = Runtime.getRuntime().availableProcessors() - 1;
		ExecutorService executor = Executors.newFixedThreadPool(cores > 0 ? cores : 1);

		// Run the analysis in parallel
		for (SmartContract contract : _bridge) {
			executor.submit(() -> {
				try {
					String bytecodeFullPath = contract.getBytecodePath().toString();

					String bytecode = new String(Files.readAllBytes(Paths.get(bytecodeFullPath)));
					if (bytecode.startsWith("0x"))
						EVMFrontend.opcodesFromBytecode(bytecode, bytecodeFullPath);

					Program program = EVMFrontend.generateCfgFromFile(bytecodeFullPath);

					LiSAConfiguration conf = new LiSAConfiguration();
					conf.abstractState = new SimpleAbstractState<>(new MonolithicHeap(),
							new EVMAbstractState(contract.getName()),
							new TypeEnvironment<>(new InferredTypes()));
					conf.workdir = contract.getBytecodePath().toString();
					conf.interproceduralAnalysis = new ModularWorstCaseAnalysis<>();
					JumpSolver checker = new JumpSolver();
					conf.semanticChecks.add(checker);
					conf.callGraph = new RTACallGraph();
					conf.serializeResults = false;
					conf.optimize = false;
					conf.useWideningPoints = false;

					LiSA lisa = new LiSA(conf);
					lisa.run(program);

					contract.setCFG(checker.getComputedCFG());
					contract.computeFunctionEntrypoints();

					// check soundness
					if (!Objects.requireNonNull(
							EVMLiSA.dumpStatistics(checker,
									EVMLiSA.getSoundlySolvedJumps(checker, lisa, program)))
							.isSound())
						log.warn("UNSOUND on {}", contract.getName());

				} catch (NullPointerException npe) {
					log.error("Error checking soundness in bytecode {}: {}", contract.getName(), npe.getMessage());
				} catch (Exception e) {
					log.error("Error processing bytecode {}: {}", contract.getName(), e.getMessage());
				}
			});
		}

		// Shutdown the executor and wait for completion
		executor.shutdown();
		if (!executor.awaitTermination(1, TimeUnit.HOURS)) {
			log.error("Timeout reached while waiting for thread pool to terminate.");
			executor.shutdownNow();
		}
	}

	void printInfo(EVMCFG xCFG) {
		log.info("Nodes count: {}", xCFG.getNodesCount());
		log.info("Edge count: {}", xCFG.getEdgesCount());
		log.info("Opcode count: {}", xCFG.getOpcodeCount());
		log.info("xCFG entrypoints: {}", xCFG.getEntrypoints());
		log.info("xCFG LOGx opcodes: {}", xCFG.getAllLogX().size());
	}

	private void getCFGHashCode() {
		log.debug("CFG hashcode");
		for (SmartContract contract : _bridge) {
			if (contract.getCFG() == null)
				log.debug("{}: null", contract.getName());
			else
				log.debug("{}: {}", contract.getName(), contract.getCFG().hashCode());
		}
	}
}
