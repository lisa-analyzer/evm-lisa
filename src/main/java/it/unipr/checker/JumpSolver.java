package it.unipr.checker;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.AbstractStackSet;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.StackElement;
import it.unipr.cfg.EVMCFG;
import it.unipr.frontend.EVMLiSAFeatures;
import it.unipr.frontend.EVMLiSATypeSystem;
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
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * A semantic checker that aims at solving JUMP and JUMPI destinations by
 * filtering all the possible destinations and adding the missing edges.
 */
public class JumpSolver implements
		SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(JumpSolver.class);

	/**
	 * The CFG to be analyzed.
	 */
	private EVMCFG cfgToAnalyze;

	/**
	 * Yields if the fixpoint has been reached.
	 */
	private boolean fixpoint = true;

	/**
	 * The set of unreachable jumps (i.e., their state is bottom)
	 */
	private Set<Statement> unreachableJumps;

	/**
	 * The set of maybe unsound jumps (i.e., jumps reached by the top abstract
	 * state)
	 */
	private Set<Statement> maybeUnsoundJumps;

	private Set<Statement> unsoundJumps;

	/**
	 * Map of top stack values per jump
	 */
	private Map<Statement, Set<StackElement>> topStackValuesPerJump = new HashMap<>();

	/**
	 * Yields the computed CFG.
	 * 
	 * @return the computed CFG
	 */
	public EVMCFG getComputedCFG() {
		return cfgToAnalyze;
	}

	/**
	 * Yields the jumps where the whole value state is bottom (i.e., the jump is
	 * unreachable).
	 * 
	 * @return the set of unreachable jumps
	 */
	public Set<Statement> getUnreachableJumps() {
		return unreachableJumps;
	}

	/**
	 * Yields the jumps where the whole value state is top (i.e., the jump is
	 * maybe unsound).
	 * 
	 * @return the set of maybe unsound jumps
	 */
	public Set<Statement> getMaybeUnsoundJumps() {
		return maybeUnsoundJumps;
	}

	/**
	 * Yields the jumps where at least one of the top stack values is top (i.e.,
	 * the jump is unsound).
	 * 
	 * @return the set of unsound jumps
	 */
	public Set<Statement> getUnsoundJumps() {
		return unsoundJumps;
	}

	/**
	 * The set of top stack values per jump. This only exists for jumps that are
	 * not in {@link #getMaybeUnsoundJumps()} and
	 * {@link #getUnreachableJumps()}.
	 */
	public Set<StackElement> getTopStackValuesPerJump(Statement node) {
		return topStackValuesPerJump.get(node);
	}

	private static boolean LINK_UNSOUND_JUMPS_TO_ALL_JUMPDEST = false;

	static public void setLinkUnsoundJumpsToAllJumpdest() {
		LINK_UNSOUND_JUMPS_TO_ALL_JUMPDEST = true;
	}

	static public boolean getLinkUnsoundJumpsToAllJumpdest() {
		return LINK_UNSOUND_JUMPS_TO_ALL_JUMPDEST;
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
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool) {

		if (fixpoint) {
			this.unreachableJumps = new HashSet<>();
			this.maybeUnsoundJumps = new HashSet<>();
			this.unsoundJumps = new HashSet<>();

			for (Statement node : this.cfgToAnalyze.getAllJumps()) {
				if (cfgToAnalyze.getAllPushedJumps().contains(node))
					continue;

				for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
						TypeEnvironment<InferredTypes>>> result : tool.getResultOf(this.cfgToAnalyze)) {
					AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbstractState,
							TypeEnvironment<InferredTypes>>> analysisResult = null;

					try {
						analysisResult = result.getAnalysisStateBefore(node);
					} catch (SemanticException e1) {
						log.error("(JumpSolver): {}", e1.getMessage());
					}

					// Retrieve the symbolic stack from the analysis result
					EVMAbstractState valueState = analysisResult.getState().getValueState();

					if (valueState.isBottom()) {
						// If the value state is bottom, the jump is definitely
						// unreachable
						this.unreachableJumps.add(node);
						continue;
					}

					if (valueState.isTop()) {
						// If the value state is top, the jump is maybe unsound
						// (i.e., we should re-run the analysis with different
						// parameter)
						this.maybeUnsoundJumps.add(node);
						continue;
					}

					Set<StackElement> stacksTop = new HashSet<>();
					AbstractStackSet stacks = valueState.getStacks();
					for (AbstractStack stack : stacks) {
						StackElement topStack = stack.getTop();
						stacksTop.add(topStack);
						if (topStack.isTop())
							unsoundJumps.add(node);
					}

					topStackValuesPerJump.put(node, stacksTop);
				}
			}

			return;
		}

		this.fixpoint = true;

		LiSAConfiguration conf = tool.getConfiguration();
		LiSA lisa = new LiSA(conf);

		Program program = new Program(new EVMLiSAFeatures(), new EVMLiSATypeSystem());
		program.addCodeMember(cfgToAnalyze);

		try {
			lisa.run(program);
		} catch (AnalysisException e) {
			log.error("(JumpSolver): {}", e.getMessage());
		}
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbstractState, TypeEnvironment<InferredTypes>>> tool,
			CFG graph) {
		this.cfgToAnalyze = (EVMCFG) graph;
		return false;
	}
}
