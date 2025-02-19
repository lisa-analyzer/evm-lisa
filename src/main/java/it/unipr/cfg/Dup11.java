package it.unipr.cfg;

import it.unipr.analysis.operator.Dup11Operator;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.type.Untyped;

/**
 * Dup11 opcode of the program to analyze.
 */
public class Dup11 extends Dup {

	/**
	 * Builds a Dup11 opcode happening at the given source location.
	 * 
	 * @param cfg      the cfg that this statement belongs to
	 * @param location the location where this statement is defined within the
	 *                     program
	 */
	public Dup11(CFG cfg, CodeLocation location) {
		super(cfg, location);
	}

	@Override
	public String toString() {
		return "DUP11";
	}

	public <A extends AbstractState<A>> AnalysisState<A> forwardSemantics(AnalysisState<A> entryState,
			InterproceduralAnalysis<A> interprocedural, StatementStore<A> expressions) throws SemanticException {

		return entryState.smallStepSemantics(
				new it.unive.lisa.symbolic.value.UnaryExpression(Untyped.INSTANCE, DummyConstant.INSTANCE,
						Dup11Operator.INSTANCE, getLocation()),
				this);
	}
}