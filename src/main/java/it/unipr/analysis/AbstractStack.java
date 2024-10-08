package it.unipr.analysis;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.representation.DomainRepresentation;
import it.unive.lisa.analysis.representation.StringRepresentation;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.ValueExpression;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import java.util.function.Predicate;

public class AbstractStack implements ValueDomain<AbstractStack>, BaseLattice<AbstractStack> {

	private static int STACK_LIMIT = 32;
	private static final AbstractStack TOP = new AbstractStack(
			new ArrayList<>(Collections.nCopies(STACK_LIMIT, StackElement.NUMERIC_TOP)));
	private static final AbstractStack BOTTOM = new AbstractStack(null);

	private final ArrayList<StackElement> stack;

	/**
	 * Builds an initial symbolic stack.
	 */
	public AbstractStack() {
		this.stack = new ArrayList<>(Collections.nCopies(STACK_LIMIT, StackElement.BOTTOM));
	}

	/**
	 * Builds a symbolic stack starting from a given stack.
	 *
	 * @param stack the stack of values
	 */
	public AbstractStack(ArrayList<StackElement> stack) {
		this.stack = stack;
	}

	@Override
	public AbstractStack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractStack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractStack forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractStack forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return Satisfiability.UNKNOWN;
	}

	@Override
	public AbstractStack pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractStack popScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public DomainRepresentation representation() {
		if (isBottom())
			return Lattice.bottomRepresentation();
		else if (isTop())
			return Lattice.topRepresentation();

		return new StringRepresentation(this.toString());
	}

	@Override
	public String toString() {
		return this.stack.toString();
	}

	@Override
	public AbstractStack top() {
		return TOP;
	}

	@Override
	public AbstractStack bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isTop() {
		if (isBottom())
			return false;
		for (StackElement element : this.stack)
			if (!element.isTop())
				return false;
		return true;
	}

	@Override
	public boolean isBottom() {
		return stack == null;
	}

	public boolean isEmpty() {
		return stack.isEmpty();
	}

	@Override
	public int hashCode() {
		return Objects.hash(stack);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		AbstractStack other = (AbstractStack) obj;
		return Objects.equals(stack, other.stack);
	}

	@Override
	public AbstractStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
			throws SemanticException {
		throw new RuntimeException("assume method in abstract stack should never be called.");
	}

	/**
	 * Getter for the StackElement at the top of the stack.
	 *
	 * @return the StackElement at the top of the stack.
	 */
	public StackElement getTop() {
		return this.stack.get(stack.size() - 1); // Get the last element
	}

	@Override
	public AbstractStack clone() {
		if (isBottom() || isTop())
			return this;
		return new AbstractStack(new ArrayList<>(stack));
	}

	/**
	 * Pushes the specified element onto the stack.
	 *
	 * @param target the element to be pushed onto the stack.
	 */
	public void push(StackElement target) {
		stack.remove(0);
		stack.add(target);
	}

	/**
	 * Pops the element from the stack.
	 *
	 * @return the element at the top of the stack.
	 */
	public StackElement pop() {
		StackElement result = stack.remove(stack.size() - 1);
		if (!stack.get(0).isTop())
			stack.add(0, StackElement.BOTTOM);
		else
			stack.add(0, StackElement.NUMERIC_TOP);
		return result;
	}

	/**
	 * Returns the number of items in the stack (non-bottom).
	 *
	 * @return the number of items in the stack.
	 */
	public int size() {
		int bottomCounter = 0;
		for (StackElement item : stack) {
			if (item.isBottom()) {
				bottomCounter++;
			}
		}
		return stack.size() - bottomCounter;
	}

	public List<StackElement> getStack() {
		return stack;
	}

	@Override
	public AbstractStack lubAux(AbstractStack other) throws SemanticException {
		ArrayList<StackElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<StackElement> thisIterator = this.stack.iterator();
		Iterator<StackElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			StackElement thisElement = thisIterator.next();
			StackElement otherElement = otherIterator.next();
			result.add(thisElement.lub(otherElement));
		}

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack wideningAux(AbstractStack other) throws SemanticException {
		ArrayList<StackElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<StackElement> thisIterator = this.stack.iterator();
		Iterator<StackElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			StackElement thisElement = thisIterator.next();
			StackElement otherElement = otherIterator.next();
			result.add(thisElement.widening(otherElement));
		}

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack glbAux(AbstractStack other) throws SemanticException {
		ArrayList<StackElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<StackElement> thisIterator = this.stack.iterator();
		Iterator<StackElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			StackElement thisElement = thisIterator.next();
			StackElement otherElement = otherIterator.next();
			result.add(thisElement.glb(otherElement));
		}

		return new AbstractStack(result);
	}

	@Override
	public boolean lessOrEqualAux(AbstractStack other) throws SemanticException {
		Iterator<StackElement> thisIterator = this.stack.iterator();
		Iterator<StackElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			if (!thisIterator.next().lessOrEqual(otherIterator.next())) {
				return false;
			}
		}

		return true;
	}

	public StackElement getSecondElement() {
		if (isBottom())
			return StackElement.BOTTOM;
		else if (isTop())
			return StackElement.NUMERIC_TOP;
		return this.stack.get(STACK_LIMIT - 2);
	}

	/**
	 * Set the stack limit.
	 *
	 * @param n the new stack limit
	 */
	public static void setStackLimit(int n) {
		if (n > 0)
			STACK_LIMIT = n;
	}

	/**
	 * Yields the stack limit.
	 *
	 * @return the stack limit
	 */
	public static int getStackLimit() {
		return STACK_LIMIT;
	}

	/**
	 * Checks whether between 0 and x-positions of the stack an element is
	 * bottom. /** Checks whether between 0 and x-positions of the stack an
	 * element is bottom.
	 * 
	 * @param x the position
	 * 
	 * @return {@code true} if between 0 and x-positions of the stack an element
	 *             is bottom, {@code false} otherwise.
	 */
	public boolean hasBottomUntil(int x) {
		for (int i = 0; i < x; i++)
			if (this.stack.get((STACK_LIMIT - 1) - i).isBottom())
				return true;
		return false;
	}
}