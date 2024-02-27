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

import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Objects;
import java.util.function.Predicate;

public class AbstractStack implements ValueDomain<AbstractStack>, BaseLattice<AbstractStack> {

	private static int STACK_LIMIT = 128;
	private static final AbstractStack BOTTOM = new AbstractStack(null);

	private final LinkedList<KIntegerSet> stack;

	/**
	 * Builds a initial symbolic stack.
	 */
	public AbstractStack() {
		this.stack = new LinkedList<KIntegerSet>(Collections.nCopies(STACK_LIMIT, KIntegerSet.BOTTOM));

		//		for (int i = 0; i < STACK_LIMIT; i++)
		//			stack.add(KIntegerSet.BOTTOM);
	}

	/**
	 * Builds a symbolic stack starting from a given stack.
	 * 
	 * @param stack the stack of values
	 */
	public AbstractStack(LinkedList<KIntegerSet> stack) {
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
		String result = "{";

		for (int i = STACK_LIMIT - size(); i < STACK_LIMIT; i++) {
			if (stack.get(i).isBottom())
				result += Lattice.bottomRepresentation();
			else if (stack.get(i).isBottom())
				result += Lattice.topRepresentation();
			else
				result += stack.get(i);

			if ((i + 1) != STACK_LIMIT)
				result += ", ";
		}

		result += "}";
		return result;
	}

	@Override
	public AbstractStack glbAux(AbstractStack other) throws SemanticException {
		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < STACK_LIMIT; i++)
			result.addLast(this.stack.get(i).glb(other.stack.get(i)));

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack wideningAux(AbstractStack other) throws SemanticException {
		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < STACK_LIMIT; i++)
			result.addLast(this.stack.get(i).widening(other.stack.get(i)));

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack top() {
		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < STACK_LIMIT; i++)
			result.addLast(KIntegerSet.TOP);
		//		LinkedList<KIntegerSet> result = new LinkedList<KIntegerSet>(Collections.nCopies(STACK_LIMIT, KIntegerSet.TOP));

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isTop() {
		if (isBottom())
			return false;
		else if (this.stack.stream()
				.anyMatch(element -> !element.isTop())) 
			return false;
		else return true;	
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
	 * Getter for the Interval at the top of the stack.
	 * 
	 * @return the Interval at the top of the stack.
	 */
	public KIntegerSet getTop() {
		return this.stack.getLast();
	}

	@Override
	public AbstractStack clone() {
		if (isBottom())
			return BOTTOM;
		else if (isTop())
			return top();
		return new AbstractStack(clone(stack));
	}

	private static LinkedList<KIntegerSet> clone(LinkedList<KIntegerSet> list) {
		LinkedList<KIntegerSet> result = new LinkedList<>();
		for (KIntegerSet item : list) 
			result.add(item.copy());

		return result;
	}

	/**
	 * Pushes the specified interval onto the stack.
	 *
	 * @param target the interval to be pushed onto the stack.
	 */
	public void push(KIntegerSet target) {
		stack.addLast(target);
		stack.removeFirst();
	}

	/**
	 * Pops the interval from the stack.
	 *
	 * @return the interval at the top of the stack.
	 */
	public KIntegerSet pop() {
		KIntegerSet result = stack.removeLast();
		if (!stack.getFirst().isTop())
			stack.addFirst(KIntegerSet.BOTTOM);
		else
			stack.addFirst(KIntegerSet.TOP);
		return result;

	}

	/**
	 * Returns the number of item in the stack.
	 *
	 * @return the number of item in the stack.
	 */
	public int size() {
		int bottomCounter = 0;
		Iterator<KIntegerSet> it = stack.iterator();
		while (it.hasNext() && it.next().isBottom())
			bottomCounter++;

		return stack.size() - bottomCounter;
	}

	public List<KIntegerSet> getStack() {
		return stack;
	}

	@Override
	public AbstractStack lubAux(AbstractStack other) throws SemanticException {
		LinkedList<KIntegerSet> result = new LinkedList<>();

		Iterator<KIntegerSet> thisIterator = this.stack.iterator();
		Iterator<KIntegerSet> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			KIntegerSet thisElement = thisIterator.next();
			KIntegerSet otherElement = otherIterator.next();
			result.addLast(thisElement.lub(otherElement));
		}

		return new AbstractStack(result);
	}

	@Override
	public boolean lessOrEqualAux(AbstractStack other) throws SemanticException {
		Iterator<KIntegerSet> thisIterator = this.stack.iterator();
		Iterator<KIntegerSet> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			if (!thisIterator.next().lessOrEqual(otherIterator.next())) {
				return false;
			}
		}

		return true;
	}

	public KIntegerSet getSecondElement() {
		if (isBottom())
			return KIntegerSet.BOTTOM;
		else if (isTop())
			return KIntegerSet.TOP;
		return this.stack.get(STACK_LIMIT - 2);
	}

	/**
	 * Set the stack limit
	 * 
	 * @param n the new stack limit
	 */
	public static void setStackLimit(int n) {
		if (n > 0)
			STACK_LIMIT = n;
	}

	/**
	 * Yields the stack limit
	 * 
	 * @return the stack limit
	 */
	public static int getStackLimit() {
		return STACK_LIMIT;
	}
}