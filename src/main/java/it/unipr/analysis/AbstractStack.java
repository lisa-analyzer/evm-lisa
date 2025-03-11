package it.unipr.analysis;

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
import java.util.Arrays;
import java.util.Objects;
import java.util.function.Predicate;

public class AbstractStack implements ValueDomain<AbstractStack>, BaseLattice<AbstractStack> {

	/**
	 * The stack height.
	 */
	private static int STACK_LIMIT = 32;

	/**
	 * The top abstract element of this domain.
	 */
	private static final AbstractStack TOP = new AbstractStack(
			createFilledArray(STACK_LIMIT, StackElement.TOP), STACK_LIMIT);

	/**
	 * The bottom abstract element of this domain.
	 */
	private static final AbstractStack BOTTOM = new AbstractStack(null);

	/**
	 * The abstract stack as an array.
	 */
	private final StackElement[] stack;

	/**
	 * The size of this stack (i.e., the number of elements)
	 */
	private int size;

	/**
	 * Helper method to create and fill an array with a specific element.
	 */
	private static StackElement[] createFilledArray(int size, StackElement element) {
		StackElement[] array = new StackElement[size];
		Arrays.fill(array, element);
		return array;
	}

	/**
	 * Builds an initial symbolic stack.
	 */
	public AbstractStack() {
		this(createFilledArray(STACK_LIMIT, StackElement.BOTTOM), 0);
	}

	/**
	 * Builds a symbolic stack starting from a given stack array.
	 *
	 * @param stack the stack of values
	 */
	public AbstractStack(StackElement[] stack) {
		this.stack = stack;
		if (stack != null) {
			int bottomCounter = 0;
			for (StackElement item : stack) {
				if (item.isBottom()) {
					bottomCounter++;
				}
			}
			this.size = STACK_LIMIT - bottomCounter;
		} else {
			this.size = 0;
		}
	}

	AbstractStack(StackElement[] stack, int size) {
		this.stack = stack;
		this.size = size;
	}

	@Override
	public AbstractStack assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public AbstractStack smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
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
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
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
	public StructuredRepresentation representation() {
		if (isBottom())
			return Lattice.bottomRepresentation();
		else if (isTop())
			return Lattice.topRepresentation();

		return new StringRepresentation(this.toString());
	}

	@Override
	public String toString() {
		if (isBottom())
			return "BOTTOM";
		if (isTop())
			return "TOP";
		return Arrays.toString(this.stack);
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
		return size == 0;
	}

	@Override
	public int hashCode() {
		return Objects.hash(Arrays.hashCode(stack));
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
		return Arrays.equals(stack, other.stack);
	}

	@Override
	public AbstractStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest, SemanticOracle oracle)
			throws SemanticException {
		throw new RuntimeException("assume method in abstract stack should never be called.");
	}

	/**
	 * Yields the last element of the stack (i.e., the top of the stack).
	 *
	 * @return the StackElement at the top of the stack.
	 */
	public StackElement getTop() {
		return this.stack[STACK_LIMIT - 1]; // Get the last element
	}

	@Override
	public AbstractStack clone() {
		if (isBottom() || isTop())
			return this;
		return new AbstractStack(Arrays.copyOf(stack, STACK_LIMIT), this.size);
	}

	/**
	 * Pushes the specified element onto the stack.
	 *
	 * @param target the element to be pushed onto the stack.
	 */
	public void push(StackElement target) {
		// Shift all elements one position to the left
		System.arraycopy(stack, 1, stack, 0, STACK_LIMIT - 1);
		stack[STACK_LIMIT - 1] = target;
		this.size++;
	}

	/**
	 * Pops the element from the stack.
	 *
	 * @return the element at the top of the stack.
	 */
	public StackElement pop() {
		StackElement result = stack[STACK_LIMIT - 1];
		// Shift all elements one position to the right
		System.arraycopy(stack, 0, stack, 1, STACK_LIMIT - 1);
		if (!stack[1].isTop()) {
			stack[0] = StackElement.BOTTOM;
			this.size--;
		} else {
			stack[0] = StackElement.TOP;
		}
		return result;
	}

	/**
	 * Returns the number of items in the stack (non-bottom).
	 *
	 * @return the number of items in the stack.
	 */
	public int size() {
		return this.size;
	}

	/**
	 * Yields the stack.
	 *
	 * @return the stack as an array
	 */
	public StackElement[] getStack() {
		return stack;
	}

	@Override
	public AbstractStack lubAux(AbstractStack other) throws SemanticException {
		StackElement[] result = new StackElement[STACK_LIMIT];

		for (int i = 0; i < STACK_LIMIT; i++) {
			result[i] = this.stack[i].lub(other.stack[i]);
		}

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack wideningAux(AbstractStack other) throws SemanticException {
		StackElement[] result = new StackElement[STACK_LIMIT];

		for (int i = 0; i < STACK_LIMIT; i++) {
			result[i] = this.stack[i].widening(other.stack[i]);
		}

		return new AbstractStack(result);
	}

	@Override
	public AbstractStack glbAux(AbstractStack other) throws SemanticException {
		StackElement[] result = new StackElement[STACK_LIMIT];

		for (int i = 0; i < STACK_LIMIT; i++) {
			result[i] = this.stack[i].glb(other.stack[i]);
		}

		return new AbstractStack(result);
	}

	@Override
	public boolean lessOrEqualAux(AbstractStack other) throws SemanticException {
		if (size() > other.size())
			return false;

		// Starting from the top of the stack and moving downward
		for (int i = STACK_LIMIT - 1; i >= 0; i--) {
			if (!this.stack[i].lessOrEqual(other.stack[i])) {
				return false;
			}
		}

		return true;
	}

	/**
	 * Yields the second element of this abstract stack.
	 *
	 * @return the second element of this abstract stack
	 */
	public StackElement getSecondElement() {
		if (isBottom())
			return StackElement.BOTTOM;
		else if (isTop())
			return StackElement.TOP;
		return this.stack[STACK_LIMIT - 2];
	}

	/**
	 * Set the stack limit.
	 *
	 * @param n the new stack limit
	 */
	public static void setStackLimit(int n) {
		if (n > 0)
			STACK_LIMIT = n;
		else
			throw new RuntimeException("Stack height cannot be non-positive");
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
	 * bottom.
	 *
	 * @param x the position
	 *
	 * @return {@code true} if between 0 and x-positions of the stack an element
	 *             is bottom, {@code false} otherwise.
	 */
	public boolean hasBottomUntil(int x) {
		for (int i = 0; i < x; i++)
			if (this.stack[(STACK_LIMIT - 1) - i].isBottom())
				return true;
		return false;
	}

	@Override
	public boolean knowsIdentifier(Identifier id) {
		return true;
	}

	/**
	 * Duplicates the x-th element from the top of the stack and returns the
	 * modified stack.
	 *
	 * @param x The position of the element to duplicate from the top of the
	 *              stack.
	 *
	 * @return A new stack with the specified element duplicated at the top.
	 */
	public AbstractStack dupX(int x) {
		if (hasBottomUntil(x))
			return bottom();

		AbstractStack clonedStack = clone();
		StackElement[] stackArray = clonedStack.getStack();

		int topIndex = STACK_LIMIT - 1;
		int targetIndex = topIndex - x + 1;
		StackElement elementToDuplicate = stackArray[targetIndex];

		StackElement[] resultArray = new StackElement[STACK_LIMIT];

		System.arraycopy(stackArray, 1, resultArray, 0, STACK_LIMIT - 1);

		resultArray[topIndex] = elementToDuplicate;

		return new AbstractStack(resultArray, size() + 1);
	}

	/**
	 * Swaps the 1st with the (x + 1)-th element from the top of the stack and
	 * returns the modified stack.
	 *
	 * @param x The position of the element to swap with the top of the stack.
	 * 
	 * @return A new stack with the specified elements swapped.
	 */
	public AbstractStack swapX(int x) {
		if (hasBottomUntil(x + 1))
			return bottom();

		int topIndex = STACK_LIMIT - 1;
		int swapIndex = topIndex - x;

		StackElement[] newStack = Arrays.copyOf(stack, STACK_LIMIT);

		StackElement temp = newStack[topIndex];
		newStack[topIndex] = newStack[swapIndex];
		newStack[swapIndex] = temp;

		return new AbstractStack(newStack, size());
	}
}