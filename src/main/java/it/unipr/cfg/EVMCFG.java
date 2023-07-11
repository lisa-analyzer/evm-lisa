package it.unipr.cfg;

import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.AnalyzedCFG;
import it.unive.lisa.analysis.OptimizedAnalyzedCFG;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.analysis.heap.HeapDomain;
import it.unive.lisa.analysis.value.TypeDomain;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.conf.FixpointConfiguration;
import it.unive.lisa.conf.LiSAConfiguration.DescendingPhaseType;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.interprocedural.ScopeId;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.fixpoints.CFGFixpoint.CompoundState;
import it.unive.lisa.program.cfg.fixpoints.DescendingGLBFixpoint;
import it.unive.lisa.program.cfg.fixpoints.DescendingNarrowingFixpoint;
import it.unive.lisa.program.cfg.fixpoints.OptimizedFixpoint;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.util.collections.workset.WorkingSet;
import it.unive.lisa.util.datastructures.graph.algorithms.Fixpoint;
import it.unive.lisa.util.datastructures.graph.algorithms.FixpointException;
import it.unive.lisa.util.datastructures.graph.code.NodeList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

public class EVMCFG extends CFG {

	public EVMCFG(CodeMemberDescriptor descriptor, Collection<Statement> entrypoints,
			NodeList<CFG, Statement, Edge> list) {
		super(descriptor, entrypoints, list);
	}

	public EVMCFG(CodeMemberDescriptor cfgDesc) {
		super(cfgDesc);
	}

	/**
	 * Returns a set of all the JUMPDEST statements in the CFG.
	 *
	 * @return a set of all the JUMPDEST statements in the CFG
	 */
	public Set<Statement> getAllJumpdest() {
		NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();
		Set<Statement> jumpdestStatements = new HashSet<>(); // to return

		for (Statement statement : cfgNodeList.getNodes()) {
			if (statement instanceof Jumpdest) {
				jumpdestStatements.add(statement);
			}
		}

		return jumpdestStatements;
	}

	public <A extends AbstractState<A, H, V, T>,
			H extends HeapDomain<H>,
			V extends ValueDomain<V>,
			T extends TypeDomain<T>> AnalyzedCFG<A, H, V, T> fixpoint(
					AnalysisState<A, H, V, T> singleton, Map<Statement, AnalysisState<A, H, V, T>> startingPoints,
					InterproceduralAnalysis<A, H, V, T> interprocedural, WorkingSet<Statement> ws,
					FixpointConfiguration conf,
					ScopeId id) throws FixpointException {
		// we disable optimizations for ascending phases if there is a
		// descending one: the latter will need full results to start applying
		// glbs/narrowings from a post-fixpoint
		boolean isOptimized = conf.optimize && conf.descendingPhaseType == DescendingPhaseType.NONE;
		Fixpoint<CFG, Statement, Edge, CompoundState<A, H, V, T>> fix = isOptimized
				? new OptimizedFixpoint<>(this, false, conf.hotspots)
				: new Fixpoint<>(this, false);
		EVMAscendingFixpoint<A, H, V, T> asc = new EVMAscendingFixpoint<A, H, V, T>(this, interprocedural,
				conf.wideningThreshold);

		Map<Statement, CompoundState<A, H, V, T>> starting = new HashMap<>();
		StatementStore<A, H, V, T> bot = new StatementStore<>(singleton.bottom());
		startingPoints.forEach((st, state) -> starting.put(st, CompoundState.of(state, bot)));
		Map<Statement, CompoundState<A, H, V, T>> ascending = fix.fixpoint(starting, ws, asc);

		if (conf.descendingPhaseType == DescendingPhaseType.NONE)
			return flatten(isOptimized, singleton, startingPoints, interprocedural, id, ascending);

		fix = conf.optimize ? new OptimizedFixpoint<>(this, true, conf.hotspots) : new Fixpoint<>(this, true);
		Map<Statement, CompoundState<A, H, V, T>> descending;
		switch (conf.descendingPhaseType) {
		case GLB:
			DescendingGLBFixpoint<A, H, V, T> dg = new DescendingGLBFixpoint<>(this, conf.glbThreshold,
					interprocedural);
			descending = fix.fixpoint(starting, ws, dg, ascending);
			break;
		case NARROWING:
			DescendingNarrowingFixpoint<A, H, V, T> dn = new DescendingNarrowingFixpoint<>(this, interprocedural);
			descending = fix.fixpoint(starting, ws, dn, ascending);
			break;
		case NONE:
		default:
			// should never happen
			descending = ascending;
			break;
		}

		return flatten(conf.optimize, singleton, startingPoints, interprocedural, id, descending);
	}

	private <V extends ValueDomain<V>,
			T extends TypeDomain<T>,
			A extends AbstractState<A, H, V, T>,
			H extends HeapDomain<H>> AnalyzedCFG<A, H, V, T> flatten(
					boolean isOptimized, AnalysisState<A, H, V, T> singleton,
					Map<Statement, AnalysisState<A, H, V, T>> startingPoints,
					InterproceduralAnalysis<A, H, V, T> interprocedural, ScopeId id,
					Map<Statement, CompoundState<A, H, V, T>> fixpointResults) {
		Map<Statement, AnalysisState<A, H, V, T>> finalResults = new HashMap<>(fixpointResults.size());
		for (Entry<Statement, CompoundState<A, H, V, T>> e : fixpointResults.entrySet()) {
			finalResults.put(e.getKey(), e.getValue().postState);
			for (Entry<Statement, AnalysisState<A, H, V, T>> ee : e.getValue().intermediateStates)
				finalResults.put(ee.getKey(), ee.getValue());
		}

		return isOptimized
				? new OptimizedAnalyzedCFG<A, H, V, T>(this, id, singleton, startingPoints, finalResults,
						interprocedural)
				: new AnalyzedCFG<>(this, id, singleton, startingPoints, finalResults);
	}

}
