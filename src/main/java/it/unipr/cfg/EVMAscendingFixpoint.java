package it.unipr.cfg;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.heap.HeapDomain;
import it.unive.lisa.analysis.value.TypeDomain;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.fixpoints.CFGFixpoint;
import it.unive.lisa.program.cfg.statement.Statement;

public class EVMAscendingFixpoint<A extends AbstractState<A, H, V, T>,
H extends HeapDomain<H>,
V extends ValueDomain<V>,
T extends TypeDomain<T>> extends CFGFixpoint<A, H, V, T> {

	private final int widenAfter;
	private final Map<Statement, Integer> lubs;
	private final Collection<Statement> wideningPoints;
	
	/**
	 * Builds the fixpoint implementation.
	 * 
	 * @param target          the target of the implementation
	 * @param widenAfter      the widening threshold
	 * @param interprocedural the {@link InterproceduralAnalysis} to use for
	 *                            semantics computations
	 */
	public EVMAscendingFixpoint(CFG graph, InterproceduralAnalysis<A, H, V, T> interprocedural, int widenAfter) {
		super(graph, interprocedural);
		this.widenAfter = widenAfter;
		this.lubs = new HashMap<>(graph.getNodesCount());
		this.wideningPoints = graph.getCycleEntries();
	}

	@Override
	public CompoundState<A, H, V, T> operation(Statement node,
			CompoundState<A, H, V, T> approx,
			CompoundState<A, H, V, T> old) throws SemanticException {
		// optimization: never apply widening on normal instructions,
		// save time and precision and only apply to widening points
		if (widenAfter < 0)
			return old.lub(approx);

		int lub = lubs.computeIfAbsent(node, st -> widenAfter);
		if (lub == 0)
			return CompoundState.of(
					old.postState.widening(approx.postState),
					// no need to widen the intermediate expressions as
					// well: we force convergence on the final post state
					// only, to recover as much precision as possible
					old.intermediateStates.lub(approx.intermediateStates));

		lubs.put(node, --lub);
		return old.lub(approx);
	}

	@Override
	public boolean equality(Statement node, CompoundState<A, H, V, T> approx,
			CompoundState<A, H, V, T> old) throws SemanticException {
		return approx.lessOrEqual(old);
	}
}
