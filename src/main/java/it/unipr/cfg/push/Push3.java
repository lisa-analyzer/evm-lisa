package it.unipr.cfg.push;

import it.unipr.cfg.HexDecimalLiteral;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.analysis.heap.HeapDomain;
import it.unive.lisa.analysis.value.TypeDomain;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeLocation;
import it.unive.lisa.program.cfg.statement.UnaryStatement;

public class Push3 extends UnaryStatement {

	public Push3(CFG cfg, CodeLocation location, HexDecimalLiteral expression) {
		super(cfg, location, expression);
		// TODO Auto-generated constructor stub
	}

	@Override
	public String toString() {
		return "PUSH3 " + getExpression();
	}

	@Override
	public <A extends AbstractState<A, H, V, T>, H extends HeapDomain<H>, V extends ValueDomain<V>, T extends TypeDomain<T>> AnalysisState<A, H, V, T> semantics(
			AnalysisState<A, H, V, T> entryState, InterproceduralAnalysis<A, H, V, T> interprocedural,
			StatementStore<A, H, V, T> expressions) throws SemanticException {
		// TODO Auto-generated method stub
		return null;
	}

}