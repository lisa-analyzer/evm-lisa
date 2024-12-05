package it.unipr.analysis.taint;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SemanticOracle;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.function.Predicate;

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
		if (isBottom())
			return Lattice.bottomRepresentation();
		else if (isTop())
			return Lattice.topRepresentation();

		return new StringRepresentation(stack.toString());
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
	public TaintAbstractStack top() {
		return TOP;
	}

	@Override
	public TaintAbstractStack bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractStack glbAux(TaintAbstractStack other) throws SemanticException {
		ArrayList<TaintElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<TaintElement> thisIterator = this.stack.iterator();
		Iterator<TaintElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			TaintElement thisElement = thisIterator.next();
			TaintElement otherElement = otherIterator.next();
			result.add(thisElement.glb(otherElement));
		}

		return new TaintAbstractStack(result);
	}

	@Override
	public TaintAbstractStack lubAux(TaintAbstractStack other) throws SemanticException {
		ArrayList<TaintElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<TaintElement> thisIterator = this.stack.iterator();
		Iterator<TaintElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			TaintElement thisElement = thisIterator.next();
			TaintElement otherElement = otherIterator.next();
			result.add(thisElement.lub(otherElement));
		}

		return new TaintAbstractStack(result);
	}

	@Override
	public boolean lessOrEqualAux(TaintAbstractStack other) throws SemanticException {
		Iterator<TaintElement> thisIterator = this.stack.iterator();
		Iterator<TaintElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			if (!thisIterator.next().lessOrEqual(otherIterator.next())) {
				return false;
			}
		}

		return true;
	}

	/**
	 * Pushes the specified element onto the stack.
	 *
	 * @param target the element to be pushed onto the stack.
	 */
	public void push(TaintElement target) {
		stack.remove(0);
		stack.add(target);
	}

	/**
	 * Pops the element from the stack.
	 *
	 * @return the element at the top of the stack.
	 */
	public TaintElement pop() {
		TaintElement result = stack.remove(stack.size() - 1);
		if (stack.get(0).isBottom())
			stack.add(0, TaintElement.BOTTOM);
		else
			stack.add(0, TaintElement.TOP);

		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		TaintAbstractStack other = (TaintAbstractStack) obj;
		return java.util.Objects.equals(stack, other.stack);
	}

	@Override
	public int hashCode() {
		return java.util.Objects.hash(stack);
	}
}
