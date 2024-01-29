package it.unipr.checker;

import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jump;
import it.unipr.cfg.Jumpi;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.frontend.EVMFeatures;
import it.unipr.frontend.EVMTypeSystem;
import it.unive.lisa.AnalysisException;
import it.unive.lisa.LiSA;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.AnalyzedCFG;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.checks.semantic.CheckToolWithAnalysisResults;
import it.unive.lisa.checks.semantic.SemanticCheck;
import it.unive.lisa.conf.LiSAConfiguration;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.edge.TrueEdge;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.util.numeric.IntInterval;

/**
 * A semantic checker that aims at solving JUMP and JUMPI destinations by
 * filtering all the possible destinations and adding the missing edges.
 */
public class JumpChecker
implements SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> {

	private static final Logger LOG = LogManager.getLogger(JumpChecker.class);

	private EVMCFG cfgToAnalyze;
	private boolean fixpoint = true;
	private final Set<Statement> solvedJumps = new HashSet<>();

	/**
	 * Getter method for the set of jump statements that have been solved.
	 * 
	 * @return the set of jump statements that have been solved.
	 */
	public Set<Statement> getSolvedJumps() {
		return this.solvedJumps;
	}


	public EVMCFG getComputedCFG() {
		return cfgToAnalyze;
	}

	/**
	 * {@inheritDoc} Checks if analysis has reached fix-point. If not, it runs
	 * another LiSA analysis to solve the remaining jumps and reach fix-point.
	 * 
	 * @param tool the semantic check tool that is running this check.
	 */
	@Override
	public void afterExecution(
			CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
			MonolithicHeap,
			EVMAbstractState, TypeEnvironment<InferredTypes>> tool) {

		if (fixpoint)
			return;
		this.fixpoint = true;

		LiSAConfiguration conf = tool.getConfiguration();
		LiSA lisa = new LiSA(conf);

		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());

		Set<Statement> set = new HashSet<>();
		for (Statement node : cfgToAnalyze.getEntrypoints())
			if (cfgToAnalyze.getIngoingEdges(node).size() > 0)
				set.add(node);

		cfgToAnalyze.getEntrypoints().removeAll(set);

		program.addCodeMember(cfgToAnalyze);

		try {
			lisa.run(program);
		} catch (AnalysisException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * {@inheritDoc} Visits the CFG, focusing only on JUMP and JUMPI statements.
	 * Tries to solve the jump destinations by inspecting the interval at the
	 * top of the symbolic stack.
	 * 
	 * @param tool  the semantic check tool that is running this check.
	 * @param graph the CFG to visit.
	 * @param node  the current node of the CFG.
	 */
	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
			MonolithicHeap,
			EVMAbstractState, TypeEnvironment<InferredTypes>> tool,
			CFG graph, Statement node) {

		// Cast the graph (CFG) to EVMCFG and set it as the actual CFG to
		// analyze.
		this.cfgToAnalyze = (EVMCFG) graph;

		// The method should focus only on JUMP and JUMPI statements.
		if (!(node instanceof Jump) && !(node instanceof Jumpi))
			return true;

		// Retrieve all the jump destinations from the actual CFG.
		Set<Statement> jumpDestinations = this.cfgToAnalyze.getAllJumpdest();

		// Iterate over all the analysis results, in our case there will be only
		// one result.
		for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
				MonolithicHeap,
				EVMAbstractState,
				TypeEnvironment<InferredTypes>> result : tool.getResultOf(this.cfgToAnalyze)) {
			AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>, MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> analysisResult = null;

			try {
				analysisResult = result.getAnalysisStateBefore(node);
			} catch (SemanticException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}


			// Retrieve the symbolic stack from the analysis result
			EVMAbstractState valueState = analysisResult.getState().getValueState();

			// If the abstract stack is top or bottom or it is empty, we do not have enough information
			// to solve the jump.
			if (valueState.isTop() || valueState.isBottom() || valueState.isEmpty()) 
				continue;
			
			IntInterval topStack = valueState.getTop().interval;
			if (!topStack.isFinite())
				continue;

			Set<Statement> filteredDests = jumpDestinations.stream()
					.filter(t -> t.getLocation() instanceof ProgramCounterLocation)
					.filter(pc -> topStack.includes(new IntInterval(((ProgramCounterLocation) pc.getLocation()).getPc(), ((ProgramCounterLocation) pc.getLocation()).getPc())))
					.collect(Collectors.toSet());

			// TODO: Check if printing found JUMPDESTs is useful
			System.err.println(
					filteredDests + " " + valueState.getTop());

			// If there are no JUMPDESTs for this value, skip to the
			// next one.
			if (filteredDests.isEmpty()) {
				continue;
			}

			// For each JUMPDEST, add the missing edge from this node to
			// the JUMPDEST.
			for (Statement jmp : filteredDests) {
				if (node instanceof Jump) { // JUMP
					if (!this.cfgToAnalyze.containsEdge(new SequentialEdge(node, jmp))) {
						this.cfgToAnalyze.addEdge(new SequentialEdge(node, jmp));
						fixpoint = false;
						this.solvedJumps.add(node);
					}
				} else { // JUMPI
					if (!this.cfgToAnalyze.containsEdge(new TrueEdge(node, jmp))) {
						this.cfgToAnalyze.addEdge(new TrueEdge(node, jmp));
						fixpoint = false;
						this.solvedJumps.add(node);
					}
				}
			}
		}

		return true;
	}
}
