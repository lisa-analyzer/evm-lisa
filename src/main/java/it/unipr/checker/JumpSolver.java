package it.unipr.checker;

import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.KIntegerSet;
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
import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * A semantic checker that aims at solving JUMP and JUMPI destinations by
 * filtering all the possible destinations and adding the missing edges.
 */
public class JumpSolver
		implements SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
				MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> {

	/**
	 * The CFG to be analyzed.
	 */
	private EVMCFG cfgToAnalyze;

	/**
	 * Yields if the fixpoint has been reached.
	 */
	private boolean fixpoint = true;

	/**
	 * The set of jump destinations.
	 */
	private Set<Statement> jumpDestinations;

	private Set<Statement> unreachableJumps;

	/**
	 * Yields the computed CFG.
	 * 
	 * @return the computed CFG
	 */
	public EVMCFG getComputedCFG() {
		return cfgToAnalyze;
	}

	public Set<Statement> getUnreachableJumps() {
		return unreachableJumps;
	}

	@Override
	public void beforeExecution(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
					MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> tool) {
		// resets the unreachable jumps set
		this.unreachableJumps = new HashSet<>();
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
		program.addCodeMember(cfgToAnalyze);

		// We initialize the set of unreachable jumps, if not already
		// initialized
		this.unreachableJumps = new HashSet<>();

		try {
			lisa.run(program);
		} catch (AnalysisException e) {
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

		this.cfgToAnalyze = (EVMCFG) graph;

		// We compute the set of jump destination, if not already computed
		if (this.jumpDestinations == null)
			this.jumpDestinations = this.cfgToAnalyze.getAllJumpdest();

		// The method should focus only on JUMP and JUMPI statements.
		if (!(node instanceof Jump) && !(node instanceof Jumpi))
			return true;

		// If the jump has been already solved, we skip it
		if (node instanceof Jump && cfgToAnalyze.getOutgoingEdges(node).size() >= 1)
			return true;

		if (node instanceof Jumpi && cfgToAnalyze.getOutgoingEdges(node).size() >= 2)
			return true;

		// Iterate over all the analysis results, in our case there will be only
		// one result.
		for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
				MonolithicHeap,
				EVMAbstractState,
				TypeEnvironment<InferredTypes>> result : tool.getResultOf(this.cfgToAnalyze)) {
			AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
					MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> analysisResult = null;

			try {
				analysisResult = result.getAnalysisStateBefore(node);
			} catch (SemanticException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}

			// Retrieve the symbolic stack from the analysis result
			EVMAbstractState valueState = analysisResult.getState().getValueState();

			// If the abstract stack is top or bottom or it is empty, we do not
			// have enough information
			// to solve the jump.
			if (valueState.isBottom()) {
				this.unreachableJumps.add(node);
				continue;
			} else if (valueState.isTop()) {
				System.err.println(((ProgramCounterLocation) node.getLocation()).getSourceCodeLine() + " "
						+ valueState.representation());
				continue;
			}

			KIntegerSet topStack = valueState.getTop();
			if (topStack.isTop() || topStack.isBottom()) {
				System.err.println(((ProgramCounterLocation) node.getLocation()).getSourceCodeLine() + " "
						+ valueState.getStack());
				continue;
			}

			Set<Statement> filteredDests;
			filteredDests = this.jumpDestinations.stream()
					.filter(t -> t.getLocation() instanceof ProgramCounterLocation)
					.filter(pc -> topStack
							.contains(new BigDecimal(((ProgramCounterLocation) pc.getLocation()).getPc())))
					.collect(Collectors.toSet());

			// If there are no JUMPDESTs for this value, skip to the
			// next one.
			if (filteredDests.isEmpty()) {
				this.unreachableJumps.add(node);
				continue;
			}

			// For each JUMPDEST, add the missing edge from this node to
			// the JUMPDEST.
			for (Statement jmp : filteredDests) {
				if (node instanceof Jump) { // JUMP
					if (!this.cfgToAnalyze.containsEdge(new SequentialEdge(node, jmp))) {
						this.cfgToAnalyze.addEdge(new SequentialEdge(node, jmp));
						fixpoint = false;
					}
				} else { // JUMPI
					if (!this.cfgToAnalyze.containsEdge(new TrueEdge(node, jmp))) {
						this.cfgToAnalyze.addEdge(new TrueEdge(node, jmp));
						fixpoint = false;
					}
				}
			}
		}

		return true;
	}
}
