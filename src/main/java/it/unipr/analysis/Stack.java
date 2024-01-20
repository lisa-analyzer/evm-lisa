package it.unipr.analysis;

import it.unipr.analysis.operator.JumpiOperator;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.numeric.Interval;
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
import it.unive.lisa.util.numeric.MathNumber;

import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.function.Predicate;

public class Stack implements ValueDomain<Stack> {
	private static final Stack TOP = new Stack();
	private static final Stack BOTTOM = new Stack(null);
	private final boolean isTop;

	private final ArrayDeque<Interval> stack;

	/**
	 * Builds a top symbolic stack.
	 */
	public Stack() {
		this(true);
	}

	/**
	 * Builds a symbolic stack starting from a given stack.
	 * 
	 * @param stack the stack of values
	 */
	public Stack(ArrayDeque<Interval> stack) {
		this.stack = stack;
		this.isTop = false;
	}

	/**
	 * Builds an empty symbolic stack.
	 * 
	 * @param isTop whether this stack is top.
	 */
	private Stack(boolean isTop) {
		this.isTop = isTop;
		this.stack = new ArrayDeque<Interval>();
	}

	@Override
	public Stack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Stack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Stack forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Stack forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return Satisfiability.UNKNOWN;
	}

	@Override
	public Stack pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Stack popScope(ScopeToken token) throws SemanticException {
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
	public boolean lessOrEqual(Stack other) throws SemanticException {
		if (other == null)
			return false;

		if (this == other || this.isBottom() || other.isTop() || this.equals(other))
			return true;

		if (this.isTop() || other.isBottom())
			return false;

		// If "this" stack is taller (~ has more elements) than "other" stack,
		// lessOrEqual is false
		if (this.stack.size() > other.stack.size()) {
			return false;
		}

		// Get the iterators of the two stacks
		// Order is descending as we start from the bottom of the stack
		Iterator<Interval> thisIterator = this.stack.descendingIterator();
		Iterator<Interval> otherIterator = other.stack.descendingIterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			Interval thisInterval = (Interval) thisIterator.next();
			Interval otherInterval = (Interval) otherIterator.next();

			// If at least one interval ISN'T less than or equal to its
			// counterpart, return false
			if (!thisInterval.lessOrEqual(otherInterval)) {
				return false;
			}
		}

		return true;
	}

	@Override
	public Stack lub(Stack other) throws SemanticException {
		if (other == null || other.isBottom() || this.isTop() || this == other || this.equals(other))
			return this;

		if (this.isBottom() || other.isTop())
			return other;

		if (lessOrEqual(other))
			return other;
		else if (other.lessOrEqual(this))
			return this;

		// Otherwise, let's build a new SymbolicStack
		ArrayDeque<Interval> result = new ArrayDeque<Interval>();

		// Get the iterators of the two stacks
		// Order is descending as we start from the bottom of the stack
		Iterator<Interval> thisIterator = this.stack.descendingIterator();
		Iterator<Interval> otherIterator = other.stack.descendingIterator();

		// Merge the intervals and push them onto the result
		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			Interval thisInterval = (Interval) thisIterator.next();
			Interval otherInterval = (Interval) otherIterator.next();
			result.push(thisInterval.lub(otherInterval));
		}

		// Check if there are still elements in either stack (if any, they are
		// only in one stack) and push them onto the result
		while (thisIterator.hasNext()) {
			Interval thisInterval = (Interval) thisIterator.next();
			result.push(thisInterval);
		}

		while (otherIterator.hasNext()) {
			Interval otherInterval = (Interval) otherIterator.next();
			result.push(otherInterval);
		}

		return new Stack(result);
	}

	@Override
	public Stack widening(Stack other) throws SemanticException {
		if (other == null || other.isBottom() || this.isTop() || this == other || this.equals(other)) {
			return this;
		}

		if (this.isBottom() || other.isTop()) {
			return other;
		}

		if (this.stack.size() < other.stack.size()) {
			ArrayDeque<Interval> widenedStack = new ArrayDeque<>();

			Iterator<Interval> thisIterator = this.stack.descendingIterator();
			Iterator<Interval> otherIterator = other.stack.descendingIterator();

			while (thisIterator.hasNext() && otherIterator.hasNext()) {
				widenedStack.push(thisIterator.next().widening(otherIterator.next()));
			}

			while (otherIterator.hasNext()) {
				widenedStack.push(otherIterator.next());
			}

			return new Stack(widenedStack);
		}

		if (this.stack.size() == other.stack.size()) {
			ArrayDeque<Interval> widenedStack = new ArrayDeque<>();

			Iterator<Interval> thisIterator = this.stack.descendingIterator();
			Iterator<Interval> otherIterator = other.stack.descendingIterator();

			while (thisIterator.hasNext() && otherIterator.hasNext()) {
				Interval widenedInterval = thisIterator.next().widening(otherIterator.next());
				widenedStack.push(widenedInterval);
			}

			return new Stack(widenedStack);
		}

		return this;
	}

	@Override
	public Stack top() {
		return TOP;
	}

	@Override
	public Stack bottom() {
		return BOTTOM;
	}

//	@Override
//	public boolean isBottom() {
//		return stack == null;
//	}
//
//	@Override
//	public boolean isTop() {
//		return isTop;
//	}

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

		Stack other = (Stack) obj;
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

		// Check if each interval in the stack is equal to the corresponding one
		// in the other stack
		Iterator<Interval> thisIterator = this.stack.iterator();
		Iterator<Interval> otherIterator = other.stack.iterator();
		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			Interval thisInterval = (Interval) thisIterator.next();
			Interval otherInterval = (Interval) otherIterator.next();
			if (!thisInterval.equals(otherInterval))
				return false;
		}

		return true;
	}

	@Override
	public Stack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
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
					ArrayDeque<Interval> result = stack.clone();
					result.pop(); // Interval destination = result.pop();
					Interval condition = result.pop();

					if (condition.equals(Interval.ZERO)) {
						// Condition is surely false (interval [0,0])
						// Return BOTTOM
						return bottom();
					} else if (condition.equals(new Interval(1, 1))) {
						// Condition is surely true (interval [1,1])
						// Return the result
						return new Stack(result);
					} else {
						// Condition could be either true or false
						// Return the result
						return new Stack(result);
					}

				} else if (op instanceof LogicalNegation) {
					// Get the expression wrapped by LogicalNegation
					SymbolicExpression wrappedExpr = un.getExpression();

					if (wrappedExpr instanceof UnaryExpression) {
						UnaryOperator wrappedOperator = ((UnaryExpression) wrappedExpr).getOperator();

						// Check if LogicalNegation is wrapping a JUMPI
						if (wrappedOperator instanceof JumpiOperator) { // !JUMPI
							ArrayDeque<Interval> result = stack.clone();
							result.pop(); // Interval destination =
											// result.pop();
							Interval condition = result.pop();

							if (condition.equals(Interval.ZERO)) {
								// Condition is surely false (interval [0,0])
								// Return the result
								return new Stack(result);
							} else if (condition.equals(new Interval(1, 1))) {
								// Condition is surely true (interval [1,1])
								// Return BOTTOM
								return bottom();
							} else {
								// Condition could be either true or false
								// Return the result
								return new Stack(result);
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

	/**
	 * Getter for the Interval at the top of the stack.
	 * 
	 * @return the Interval at the top of the stack.
	 */
	public Interval getTop() {
		return this.stack.getFirst();
	}

	@Override
	public Stack clone() {
		if (isBottom())
			return new Stack(null);
		return new Stack(stack.clone());
	}

	/**
	 * Returns an iterator over the elements in the stack.
	 *
	 * @return an iterator over the elements in the stack.
	 */
	public Iterator<Interval> iterator() {
		return stack.iterator();
	}

	/**
	 * Pushes the specified interval onto the stack.
	 *
	 * @param target the interval to be pushed onto the stack.
	 */
	public void push(Interval target) {
		stack.push(target);
	}

	/**
	 * Pops the interval from the stack.
	 *
	 * @return the interval at the top of the stack.
	 */
	public Interval pop() {
		return stack.pop();
	}

	/**
	 * Returns the number of item in the stack.
	 *
	 * @return the number of item in the stack.
	 */
	public int size() {
		return stack.size();
	}
}