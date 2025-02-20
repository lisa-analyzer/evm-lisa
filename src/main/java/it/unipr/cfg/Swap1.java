package it.unipr.cfg;

import it.unipr.analysis.operator.Swap1Operator;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.type.Untyped;

/**
 * Swap1 opcode of the program to analyze.
 */
public class Swap1 extends Swap {

	/**
	 * Builds a Swap1 opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	public Swap1(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public String toString() {
		return "SWAP1";
	}

	@Override
	public <A extends AbstractState<A>> AnalysisState<A> forwardSemantics(AnalysisState<A> entryState,
			InterproceduralAnalysis<A> interprocedural, StatementStore<A> expressions) throws SemanticException {

		return entryState.smallStepSemantics(
				new it.unive.lisa.symbolic.value.UnaryExpression(Untyped.INSTANCE, DummyConstant.INSTANCE,
						Swap1Operator.INSTANCE, getLocation()),
				this);
	}
}