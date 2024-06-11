package it.unipr.checker;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.AbstractStackSet;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.KIntegerSet;
import it.unipr.analysis.Number;
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

	/**
	 * The set of unreachable jumps (i.e., their state is bottom)
	 */
	private Set<Statement> unreachableJumps;

	/**
	 * The set of maybe unsound jumps (i.e., jumps reached by the top abstract
	 * state)
	 */
	private Set<Statement> maybeUnsoundJumps;

	/**
	 * Map of top stack values per jump
	 */
	private Map<Statement, Set<KIntegerSet>> topStackValuesPerJump = new HashMap<>();

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

	public Set<Statement> getMaybeUnsoundJumps() {
		return maybeUnsoundJumps;
	}

	public Set<KIntegerSet> getTopStackValuesPerJump(Statement node) {
		return topStackValuesPerJump.get(node);
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

		if (fixpoint) {
			this.unreachableJumps = new HashSet<>();
			this.maybeUnsoundJumps = new HashSet<>();

			for (Statement node : this.cfgToAnalyze.getAllJumps()) {
				if (cfgToAnalyze.getAllPushedJumps().contains(node))
					continue;

				for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
						MonolithicHeap,
						EVMAbstractState,
						TypeEnvironment<InferredTypes>> result : tool.getResultOf(this.cfgToAnalyze)) {
					AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>,
					MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>> analysisResult = null;

					try {
						analysisResult = result.getAnalysisStateBefore(node);
					} catch (SemanticException e1) {
						e1.printStackTrace();
					}

					// Retrieve the symbolic stack from the analysis result
					EVMAbstractState valueState = analysisResult.getState().getValueState();
					
					// If the value state is bottom, the jump is definitely unreachable
					if (valueState.isBottom()) 
						this.unreachableJumps.add(node);
					// If the value state is top, the jump is maybe unsound
					// (i.e., we should re-run the analysis with different parameter)
					else if (valueState.isTop())
						this.maybeUnsoundJumps.add(node);
					else {
						Set<KIntegerSet> stacksTop = new HashSet<>();
						AbstractStackSet stacks = valueState.getStacks();
						for (AbstractStack stack : stacks) {
							KIntegerSet topStack = stack.getTop();
							stacksTop.add(topStack);
						}

						topStackValuesPerJump.put(node, stacksTop);
					}
				}
			}

			return;
		}

		this.fixpoint = true;

		LiSAConfiguration conf = tool.getConfiguration();
		LiSA lisa = new LiSA(conf);

		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		program.addCodeMember(cfgToAnalyze);

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
		else if (cfgToAnalyze.getAllPushedJumps().contains(node))
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
				e1.printStackTrace();
			}

			// Retrieve the symbolic stack from the analysis result
			EVMAbstractState valueState = analysisResult.getState().getValueState();

			// If the abstract stack is top or bottom or it is empty, we do not
			// have enough information
			// to solve the jump.
			if (valueState.isBottom()) {
				continue;
			} else if (valueState.isTop()) {
				System.err.println("Not solved jump (state is top): " + node + "["
						+ ((ProgramCounterLocation) node.getLocation()).getPc() + "]");
				continue;
			}

			for (KIntegerSet topStack : valueState.getTop()) {
				if (topStack.isBottom()) {
					continue;
				} else if (topStack.isTop()) {
					System.err.println("Not solved jump (top of the stack is top): " + node + "["
							+ ((ProgramCounterLocation) node.getLocation()).getPc() + "]");
					continue;
				}

				Set<Statement> filteredDests = this.jumpDestinations.stream()
						.filter(pc -> topStack
								.contains(new Number(((ProgramCounterLocation) pc.getLocation()).getPc())))
						.collect(Collectors.toSet());

				// For each JUMPDEST, add the missing edge from this node to
				// the JUMPDEST.
				if (node instanceof Jump) { // JUMP
					for (Statement jmp : filteredDests) {
						SequentialEdge edge = new SequentialEdge(node, jmp);
						if (!this.cfgToAnalyze.containsEdge(edge)) {
							this.cfgToAnalyze.addEdge(edge);
							fixpoint = false;
						}
					}
				} else { // JUMPI
					for (Statement jmp : filteredDests) {
						TrueEdge edge = new TrueEdge(node, jmp);
						if (!this.cfgToAnalyze.containsEdge(edge)) {
							this.cfgToAnalyze.addEdge(edge);
							fixpoint = false;
						}
					}
				}
			}
		}

		return true;
	}
}
