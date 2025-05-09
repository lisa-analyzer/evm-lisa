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
import java.util.function.Predicate;

public class AbstractStack implements ValueDomain<AbstractStack>, BaseLattice<AbstractStack> {

	/**
	 * The stack height.
	 */
	private static int STACK_LIMIT = 32;

	/**
	 * The top abstract element of this domain.
	 */

	private static final AbstractStack TOP = new AbstractStack(createFilledArray(STACK_LIMIT, StackElement.TOP));
	
	/**
	 * The bottom abstract element of this domain.
	 */
	private static final AbstractStack BOTTOM = new AbstractStack(null);

	/**
	 * The abstract stack as a circular array.
	 */
	private final StackElement[] circularArray;

	/**
	 * The index representing the beginning of the logical stack in the circular
	 * array.
	 * <p>
	 * This pointer indicates the position in the array that corresponds to the
	 * bottom of the stack. Tracks the index of the oldest element in the
	 * circular array.
	 */
	private int head;

	/**
	 * The index representing the next insertion point in the circular array.
	 * <p>
	 * This pointer is used to identify the top of the stack, where the next
	 * element will be pushed.
	 */
	private int tail;

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
		this(createFilledArray(STACK_LIMIT, StackElement.BOTTOM));
		this.head = 0;
		this.tail = 0;
	}

	/**
	 * Builds a symbolic stack starting from a given stack array.
	 *
	 * @param stack the stack of values
	 */
	public AbstractStack(StackElement[] stack) {
		this.circularArray = stack;
		this.head = 0;
		this.tail = 0;
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

		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < STACK_LIMIT; i++) {
			int pos = (head + i) % STACK_LIMIT;
			sb.append(circularArray[pos]);
			if (i < STACK_LIMIT - 1)
				sb.append(", ");
		}
		sb.append("]");
		return sb.toString();
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
		for (StackElement element : this.circularArray)
			if (!element.isTop())
				return false;
		return true;
	}

	@Override
	public boolean isBottom() {
		return circularArray == null;
	}

	@Override
	public int hashCode() {
		if (isBottom())
			return 0;
		if (isTop())
			return 1;
		return Arrays.hashCode(toLogicalArray());
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
		if (isBottom() || other.isBottom())
			return isBottom() == other.isBottom();
		if (isTop() || other.isTop())
			return isTop() == other.isTop();
		
		return Arrays.equals(this.toLogicalArray(), other.toLogicalArray());
	}

	/**
	 * Get a specific element of the stack.
	 *
	 * @param index the index of the element
	 * 
	 * @return the StackElement at the given index, or BOTTOM if out of bounds
	 */
	public StackElement get(int index) {
		if (index < 0 || index >= STACK_LIMIT) // not valid index
			return StackElement.BOTTOM;
		return circularArray[(head + index) % STACK_LIMIT];
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
		return circularArray[(tail - 1 + STACK_LIMIT) % STACK_LIMIT];
	}

	@Override
	public AbstractStack clone() {
		if (isBottom() || isTop())
			return this;
		AbstractStack clone = new AbstractStack(circularArray.clone());
		clone.head = this.head;
		clone.tail = this.tail;
		return clone;
	}

	/**
	 * Pushes the specified element onto the stack.
	 * <p>
	 * This method inserts the given {@link StackElement} at the tail of the
	 * circular array, effectively updating the top of the stack. The head of
	 * the stack is also updated to maintain the circular nature of the
	 * structure.
	 *
	 * @param element the element to be pushed onto the stack
	 */
	public void push(StackElement element) {
		circularArray[tail] = element;
		tail = (tail + 1) % STACK_LIMIT;
		head = (head + 1) % STACK_LIMIT;
	}

	/**
	 * Pops the element from the stack.
	 * <p>
	 * This method removes and returns the topmost element of the stack. After
	 * popping, the stack structure is adjusted by shifting the head, and the
	 * previous bottommost element is updated based on the next element. If the
	 * next element is {@link StackElement#TOP}, the bottom is set to TOP,
	 * otherwise, it is set to {@link StackElement#BOTTOM}.
	 *
	 * @return the element at the top of the stack before popping
	 */
	public StackElement pop() {

		int topIndex = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;
		StackElement popped = circularArray[topIndex];

		// Shift
		head = (head - 1 + STACK_LIMIT) % STACK_LIMIT;
		int bottomIndex = head;
		int secondLogicalIndex = (head + 1) % STACK_LIMIT;

		if (circularArray[secondLogicalIndex].isTop())
			circularArray[bottomIndex] = StackElement.TOP;
		else
			circularArray[bottomIndex] = StackElement.BOTTOM;

		tail = (head + STACK_LIMIT) % STACK_LIMIT;
		circularArray[topIndex] = StackElement.BOTTOM;

		return popped;
	}

	/**
	 * Performs {@code pos} consecutive {@code pop()} operations on the stack.
	 *
	 * @param pos the number of elements to pop from the stack
	 */
	public void popX(int pos) {
		for (int i = 0; i < pos; i++)
			pop();
	}

	@Override
	public AbstractStack lubAux(AbstractStack other) throws SemanticException {
		throw new RuntimeException("lub on abstract stack should be never called");
	}

	@Override
	public AbstractStack wideningAux(AbstractStack other) throws SemanticException {
		throw new RuntimeException("widening on abstract stack should be never called");
	}

	@Override
	public AbstractStack glbAux(AbstractStack other) throws SemanticException {
		throw new RuntimeException("glb on abstract stack should be never called");
	}

	@Override
	public boolean lessOrEqualAux(AbstractStack other) throws SemanticException {
		for (int i = 0; i < STACK_LIMIT; i++) {
			int thisIndex = (tail - 1 - i + STACK_LIMIT) % STACK_LIMIT;
			int otherIndex = (other.tail - 1 - i + STACK_LIMIT) % STACK_LIMIT;
			if (!this.circularArray[thisIndex].lessOrEqual(other.circularArray[otherIndex]))
				return false;
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
		if (isTop())
			return StackElement.TOP;

		int secondElementPos = (tail - 2 + STACK_LIMIT) % STACK_LIMIT;
		return circularArray[secondElementPos];
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
		for (int i = 0; i < x; i++) {
			int pos = (tail - 1 - i + STACK_LIMIT) % STACK_LIMIT;
			if (circularArray[pos].isBottom())
				return true;
		}
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
		int posX = (tail - x + STACK_LIMIT) % STACK_LIMIT;
		AbstractStack clone = clone();
		clone.push(circularArray[posX]);
		return clone;
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
		x++;
		int posX = (tail - x + STACK_LIMIT) % STACK_LIMIT; // Index of the
		// element to swap
		// with
		int topIndex = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;

		AbstractStack clone = clone();
		StackElement temp = clone.circularArray[posX];
		clone.circularArray[posX] = clone.circularArray[topIndex];
		clone.circularArray[topIndex] = temp;
		return clone;
	}
	
	private StackElement[] toLogicalArray() {
		StackElement[] logical = new StackElement[STACK_LIMIT];
		for (int i = 0; i < STACK_LIMIT; i++)
			logical[i] = circularArray[(head + i) % STACK_LIMIT];
		return logical;
	}

}