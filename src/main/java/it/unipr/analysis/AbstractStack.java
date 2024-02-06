package it.unipr.analysis;

import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Objects;
import java.util.function.Predicate;

import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.representation.DomainRepresentation;
import it.unive.lisa.analysis.representation.StringRepresentation;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.ValueExpression;

public class AbstractStack implements ValueDomain<AbstractStack> {
	public static final int K = 100;
	private static final AbstractStack BOTTOM = new AbstractStack(null);

	private final LinkedList<KIntegerSet> stack;

	/**
	 * Builds a initial symbolic stack.
	 */
	public AbstractStack() {
		this.stack = new LinkedList<KIntegerSet>();

		for (int i = 0; i < K; i++)
			stack.add(KIntegerSet.BOTTOM);
	}

	/**
	 * Builds a symbolic stack starting from a given stack.
	 * 
	 * @param stack the stack of values
	 */
	public AbstractStack(LinkedList<KIntegerSet> stack) {
		this.stack = stack;
	}
	
	public AbstractStack(LinkedList<KIntegerSet> stack, boolean isTop) {
		this.stack = stack;
	}

	@Override
	public AbstractStack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractStack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return null;
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

		return new StringRepresentation(stack);
	}

	@Override
	public String toString() {
		return stack.toString();
	}

	@Override
	public boolean lessOrEqual(AbstractStack other) throws SemanticException {
		if (other == null)
			return false;

		if (this == other || this.isBottom() || other.isTop() || this.equals(other))
			return true;

		if (this.isTop() || other.isBottom())
			return false;

		for (int i = 0; i < K; i++)
			if (!this.stack.get(i).lessOrEqual(other.stack.get(i)))
				return false;
	
		return true;
	}

	@Override
	public AbstractStack lub(AbstractStack other) throws SemanticException {
		if (other == null || other.isBottom() || this.isTop() || this == other || this.equals(other))
			return this;

		if (this.isBottom() || other.isTop())
			return other;

		if (lessOrEqual(other))
			return other;
		else if (other.lessOrEqual(this))
			return this;

		// Otherwise, let's build a new SymbolicStack
		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < K; i++)
			result.addLast(this.stack.get(i).lub(other.stack.get(i)));

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack glb(AbstractStack other) throws SemanticException {
		if (other == null || this.isBottom() || other.isTop() || this == other || this.equals(other))
			return this;

		if (other.isBottom() || this.isTop())
			return other;

		if (lessOrEqual(other))
			return this;
		else if (other.lessOrEqual(this))
			return other;

		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < K; i++)
			result.addLast(this.stack.get(i).glb(other.stack.get(i)));

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack widening(AbstractStack other) throws SemanticException {
		if (other == null || other.isBottom() || this.isTop() || this == other || this.equals(other)) {
			return this;
		}

		if (this.isBottom() || other.isTop()) {
			return other;
		}

		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < K; i++)
			result.addLast(this.stack.get(i).widening(other.stack.get(i)));

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack top() {
		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < K; i++)
			result.addLast(KIntegerSet.TOP);

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack bottom() {
		return BOTTOM;
	}
	
	@Override
	public boolean isTop() {
		if (stack == null)
			return false;
		for (int i = 0; i < K; i++)
			if (!this.stack.get(0).isTop())
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

	public static LinkedList<KIntegerSet> clone(LinkedList<KIntegerSet> originalList) {
		LinkedList<KIntegerSet> clonedList = new LinkedList<>();
		for (int i = 0; i < originalList.size(); i++)
			clonedList.add(originalList.get(i));

		return clonedList;
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
		return new AbstractStack(clone(stack));
	}

	/**
	 * Returns an iterator over the elements in the stack.
	 *
	 * @return an iterator over the elements in the stack.
	 */
	public Iterator<KIntegerSet> iterator() {
		return stack.iterator();
	}

	/**
	 * Pushes the specified interval onto the stack.
	 *
	 * @param target the interval to be pushed onto the stack.
	 */
	public void push(KIntegerSet target) {
		stack.addLast(target);
		stack.remove(0);
	}

	/**
	 * Pops the interval from the stack.
	 *
	 * @return the interval at the top of the stack.
	 */
	public KIntegerSet pop() {
		KIntegerSet result = stack.removeLast();
		if (stack.getFirst().isBottom())
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
}