package it.unipr.checker;

import java.util.HashSet;
import java.util.NoSuchElementException;
import java.util.Set;
import java.util.stream.Collectors;

import it.unipr.analysis.SymbolicStack;
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

public class JumpChecker
implements SemanticCheck<SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>,
MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>> {


	private EVMCFG cfgToAnalyze;
	private boolean fixpoint = true;
	private Set<Statement> solvedJumps = new HashSet<>();

	public Set<Statement> getSolvedJumps() {
		return this.solvedJumps;
	}

	@Override
	public void afterExecution(
			CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>, MonolithicHeap,
			SymbolicStack, TypeEnvironment<InferredTypes>> tool) {

		if (fixpoint)
			return;
		this.fixpoint = true;

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

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
			SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>, MonolithicHeap,
			SymbolicStack, TypeEnvironment<InferredTypes>> tool,
			CFG graph, Statement node) {
		EVMCFG cfg = cfgToAnalyze = (EVMCFG) graph;

		if (!(node instanceof Jump) && !(node instanceof Jumpi))
			return true;

		Set<Statement> jumpDestinations = cfg.getAllJumpdest();

		for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>,
				MonolithicHeap,
				SymbolicStack,
				TypeEnvironment<InferredTypes>> result : tool.getResultOf(cfg)) {
			AnalysisState<SimpleAbstractState<MonolithicHeap, SymbolicStack, TypeEnvironment<InferredTypes>>,
			MonolithicHeap, SymbolicStack,
			TypeEnvironment<InferredTypes>> analysisResult = result.getAnalysisStateAfter(node);

			SymbolicStack symbolicStack = analysisResult.getState().getValueState();

			if (symbolicStack.isTop() || symbolicStack.isBottom()) {
				continue;
			}

			try {
				for (Long i : symbolicStack.getTop().interval) {
					Set<Statement> jmps = jumpDestinations.stream()
							.filter(t -> t.getLocation() instanceof ProgramCounterLocation)
							.filter(pc -> ((ProgramCounterLocation) pc.getLocation()).getPc() == i)
							.collect(Collectors.toSet());

					System.err.println(jmps + " " + symbolicStack.getTop() + " " + symbolicStack.representation());

					if (jmps.isEmpty()) {
						continue;
					}

					for (Statement jmp : jmps) {	
						if (node instanceof Jump) { // JUMP
							if (!cfg.containsEdge(new SequentialEdge(node, jmp))) {
								cfg.addEdge(new SequentialEdge(node, jmp));
								fixpoint = false;
								this.solvedJumps.add(node);
							}
						} else { // JUMPI
							if (!cfg.containsEdge(new TrueEdge(node, jmp))) {
								cfg.addEdge(new TrueEdge(node, jmp));
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
