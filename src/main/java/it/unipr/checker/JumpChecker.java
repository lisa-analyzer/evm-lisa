package it.unipr.checker;

import it.unipr.analysis.EVMAbsDomain;
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
import it.unive.lisa.util.numeric.InfiniteIterationException;
import java.util.HashSet;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.stream.Collectors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * A semantic checker that aims at solving JUMP and JUMPI destinations by
 * filtering all the possible destinations and adding the missing edges.
 */
public class JumpChecker
		implements SemanticCheck<SimpleAbstractState<MonolithicHeap, EVMAbsDomain, TypeEnvironment<InferredTypes>>,
				MonolithicHeap, EVMAbsDomain, TypeEnvironment<InferredTypes>> {

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

	/**
	 * {@inheritDoc} Checks if analysis has reached fix-point. If not, it runs
	 * another LiSA analysis to solve the remaining jumps and reach fix-point.
	 * 
	 * @param tool the semantic check tool that is running this check.
	 */
	@Override
	public void afterExecution(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, EVMAbsDomain, TypeEnvironment<InferredTypes>>, MonolithicHeap,
					EVMAbsDomain, TypeEnvironment<InferredTypes>> tool) {

		if (fixpoint)
			return;
		this.fixpoint = true;

		LOG.info("Jump resolved: " + solvedJumps.size() + "/" + cfgToAnalyze.getAllJumps().size());
		LiSAConfiguration conf = tool.getConfiguration();
		LiSA lisa = new LiSA(conf);

		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
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
					SimpleAbstractState<MonolithicHeap, EVMAbsDomain, TypeEnvironment<InferredTypes>>, MonolithicHeap,
					EVMAbsDomain, TypeEnvironment<InferredTypes>> tool,
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
		for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, EVMAbsDomain, TypeEnvironment<InferredTypes>>,
				MonolithicHeap,
				EVMAbsDomain,
				TypeEnvironment<InferredTypes>> result : tool.getResultOf(this.cfgToAnalyze)) {
			AnalysisState<SimpleAbstractState<MonolithicHeap, EVMAbsDomain, TypeEnvironment<InferredTypes>>,
					MonolithicHeap, EVMAbsDomain,
					TypeEnvironment<InferredTypes>> analysisResult = result.getAnalysisStateAfter(node);

			// Retrieve the symbolic stack from the analysis result
			EVMAbsDomain evmAbsDomain = analysisResult.getState().getValueState();

			// If the symbolic stack is TOP or BOTTOM, we don't have useful info
			// to solve the jump.
			if (evmAbsDomain.isTop() || evmAbsDomain.isBottom()) {
				continue;
			}

			// TODO: Check if exceptions are correctly handled
			try {
				// Iterate over the values of the interval at the top of the
				// symbolic stack.
				for (Long i : evmAbsDomain.getTop().interval) {

					// Filter the jump destinations to find the ones that match
					// the current value of the interval.
					Set<Statement> filteredDests = jumpDestinations.stream()
							.filter(t -> t.getLocation() instanceof ProgramCounterLocation)
							.filter(pc -> ((ProgramCounterLocation) pc.getLocation()).getPc() == i)
							.collect(Collectors.toSet());

					// TODO: Check if printing found JUMPDESTs is useful
					System.err.println(
							filteredDests + " " + evmAbsDomain.getTop() + " " + evmAbsDomain.representation());

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
			} catch (InfiniteIterationException e) {
				System.err.println("Infinite iteration detected in checker visit()");
			} catch (NoSuchElementException e) {
				System.err.println("NoSuchElementException during visit()");
			}
		}

		return true;
	}
}
