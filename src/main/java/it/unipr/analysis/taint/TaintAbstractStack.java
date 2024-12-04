package it.unipr.analysis.taint;

import java.util.ArrayList;
import java.util.Collections;
import java.util.function.Predicate;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SemanticOracle;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.util.representation.StructuredRepresentation;

public class TaintAbstractStack implements ValueDomain<TaintAbstractStack>, BaseLattice<TaintAbstractStack> {

	private static int STACK_LIMIT = 32;
	private static final TaintAbstractStack TOP = new TaintAbstractStack(
			new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.TOP)));
	private static final TaintAbstractStack BOTTOM = new TaintAbstractStack(null);

	private final ArrayList<TaintElement> stack;
	
	/**
	 * Builds a taint abstract stack starting from a given stack.
	 *
	 * @param stack the stack of values
	 */
	public TaintAbstractStack(ArrayList<TaintElement> stack) {
		this.stack = stack;
	}
	
	@Override
	public TaintAbstractStack assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest,
			SemanticOracle oracle) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public boolean knowsIdentifier(Identifier id) {
		// nothing to do here
		return false;
	}

	@Override
	public TaintAbstractStack forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return Satisfiability.UNKNOWN;
	}

	@Override
	public StructuredRepresentation representation() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public TaintAbstractStack pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack popScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public boolean lessOrEqual(TaintAbstractStack other) throws SemanticException {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public TaintAbstractStack lub(TaintAbstractStack other) throws SemanticException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public TaintAbstractStack top() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public TaintAbstractStack bottom() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public TaintAbstractStack lubAux(TaintAbstractStack other) throws SemanticException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public boolean lessOrEqualAux(TaintAbstractStack other) throws SemanticException {
		// TODO Auto-generated method stub
		return false;
	}


}
