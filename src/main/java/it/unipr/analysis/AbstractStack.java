package it.unipr.analysis;

import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.function.Predicate;

import it.unipr.analysis.operator.JumpiOperator;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.representation.DomainRepresentation;
import it.unive.lisa.analysis.representation.StringRepresentation;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.SymbolicExpression;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.LogicalNegation;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;

public class AbstractStack implements ValueDomain<AbstractStack> {
	public static final int K = 32;
	private static final AbstractStack TOP = new AbstractStack();
	private static final AbstractStack BOTTOM = new AbstractStack(null);
	private final boolean isTop;

	private final LinkedList<KIntegerSet> stack;

	
	/**
	 * Builds a top symbolic stack.
	 */
	public AbstractStack() {
		this(true);
	}

	/**
	 * Builds a symbolic stack starting from a given stack.
	 * 
	 * @param stack the stack of values
	 */
	public AbstractStack(LinkedList<KIntegerSet> stack) {
		this.stack = stack;
		this.isTop = false;
	}

	/**
	 * Builds an empty symbolic stack.
	 * 
	 * @param isTop whether this stack is top.
	 */
	private AbstractStack(boolean isTop) {
		this.isTop = isTop;
		this.stack = new LinkedList<KIntegerSet>();
		
		for (int i = 0; i < K; i++)
			stack.add(KIntegerSet.BOTTOM);
		
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
		return TOP;
	}

	@Override
	public AbstractStack bottom() {
		return BOTTOM;
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
		// SymbolicStack check
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;

		AbstractStack other = (AbstractStack) obj;
		// isTop check
		if (this.isTop != other.isTop)
			return false;
		// If both are top, there is no need to check the stack
		if (this.isTop)
			return true;

		// Stack check
		if (this.stack == other.stack)
			return true;
		if (this.stack == null || other.stack == null)
			return false;
		if (this.stack.size() != other.stack.size())
			return false;

		return this.stack.equals(other.stack);
	}

	@Override
	public AbstractStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
			throws SemanticException {
		// Ensure BOTTOM and TOP propagation
		if (this.isBottom() || this.isTop()) {
			return this;
		}

		try {
			if (expression instanceof UnaryExpression) {
				UnaryExpression un = (UnaryExpression) expression;
				UnaryOperator op = un.getOperator();

				if (op instanceof JumpiOperator) { // JUMPI
					AbstractStack result = new AbstractStack(clone(stack));
					result.pop(); // Interval destination = result.pop();
					KIntegerSet condition = result.pop();

					if (condition.equals(KIntegerSet.ZERO)) {
						// Condition is surely false (interval [0,0])
						// Return BOTTOM
						return bottom();
					} else if (condition.equals(KIntegerSet.ONE)) {
						// Condition is surely true (interval [1,1])
						// Return the result
						return result;
					} else {
						// Condition could be either true or false
						// Return the result
						return result;
					}

				} else if (op instanceof LogicalNegation) {
					// Get the expression wrapped by LogicalNegation
					SymbolicExpression wrappedExpr = un.getExpression();

					if (wrappedExpr instanceof UnaryExpression) {
						UnaryOperator wrappedOperator = ((UnaryExpression) wrappedExpr).getOperator();

						// Check if LogicalNegation is wrapping a JUMPI
						if (wrappedOperator instanceof JumpiOperator) { // !JUMPI
							AbstractStack result = new AbstractStack(clone(stack));
							result.pop(); // Interval destination =
							// result.pop();
							KIntegerSet condition = result.pop();

							if (condition.equals(KIntegerSet.ZERO)) {
								// Condition is surely false (interval [0,0])
								// Return the result
								return result;
							} else if (condition.equals(KIntegerSet.ONE)) {
								// Condition is surely true (interval [1,1])
								// Return BOTTOM
								return bottom();
							} else {
								// Condition could be either true or false
								// Return the result
								return result;
							}
						}
					}
				}
			}
		} catch (NoSuchElementException e) {
			System.err.println("Operation not performed: " + e);
		}

		return this;
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
			return new AbstractStack(null);
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
		if (stack.get(0).isBottom())
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
		while(it.hasNext() && it.next().isBottom()) 
				bottomCounter++;
			
		return stack.size() - bottomCounter;
	}

	public List<KIntegerSet> getStack() {
		return stack;
	}
}