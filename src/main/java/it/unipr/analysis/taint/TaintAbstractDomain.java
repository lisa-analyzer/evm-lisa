package it.unipr.analysis.taint;

import it.unipr.cfg.EVMCFG;
import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SemanticOracle;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.Operator;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.util.Arrays;
import java.util.Objects;
import java.util.Set;
import java.util.function.Predicate;

public abstract class TaintAbstractDomain
		implements ValueDomain<TaintAbstractDomain>, BaseLattice<TaintAbstractDomain> {

	/**
	 * The stack limit.
	 */
	protected static int STACK_LIMIT = 32;

	/**
	 * The abstract stack as a circular array.
	 */
	private final TaintElement[] stack;

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
	 * The local memory, tracking if it is clean or tainted.
	 */
	private final TaintElement memory;

	private final EVMCFG cfg;

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 */
	protected TaintAbstractDomain(TaintElement[] stack, TaintElement memory) {
		this(stack, memory, null);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint. Builds a taint abstract stack starting from a
	 * given stack and a memory element.
	 *
	 * @param stack  the stack of values
	 * @param memory the memory element
	 */
	protected TaintAbstractDomain(TaintElement[] stack, TaintElement memory, EVMCFG cfg) {
		this.stack = stack;
		this.memory = memory;
		this.cfg = cfg;
		this.head = 0;
		this.tail = 0;
	}

	@Override
	public TaintAbstractDomain assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@SuppressWarnings("unused")
	@Override
	public TaintAbstractDomain smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// bottom state is propagated
		if (this.isBottom())
			return this;

		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op != null) {
				switch (op.getClass().getSimpleName()) {
				case "TimestampOperator":
				case "OriginOperator":
				case "CodesizeOperator":
				case "GaspriceOperator":
				case "ReturndatasizeOperator":
				case "CoinbaseOperator":
				case "NumberOperator":
				case "DifficultyOperator":
				case "GaslimitOperator":
				case "ChainidOperator":
				case "SelfbalanceOperator":
				case "PcOperator":
				case "GasOperator":
				case "MsizeOperator":
				case "BlobBaseFeeOperator":
				case "BasefeeOperator":
				case "CalldatasizeOperator":
				case "CallvalueOperator":
				case "CallerOperator":
				case "AddressOperator":
				case "PushOperator":
				case "Push0Operator": {
					TaintAbstractDomain resultStack = clone();
					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.CLEAN);
					return resultStack;
				}

				case "JumpdestOperator": { // JUMPDEST
					return this;
				}

				// Above, operators that do not perform pop()
				// Below, operators that perform pop operation on the stack

				case "JumpOperator": { // JUMP
					if (hasBottomUntil(1))
						return bottom();

					TaintAbstractDomain resultStack = clone();
					TaintElement opnd1 = resultStack.pop();

					return resultStack;
				}

				case "TstoreOperator":
				case "JumpiOperator": {
					if (hasBottomUntil(2))
						return bottom();

					TaintAbstractDomain resultStack = clone();
					resultStack.popX(2);

					return resultStack;
				}

				case "TloadOperator": {
					if (hasBottomUntil(2))
						return bottom();

					TaintAbstractDomain resultStack = clone();
					TaintElement key = resultStack.pop();
					resultStack.push(TaintElement.TOP);

					return resultStack;
				}

				case "BlobHashOperator":
				case "BalanceOperator":
				case "BlockhashOperator":
				case "NotOperator":
				case "CalldataloadOperator":
				case "CalldatacopyOperator":
				case "SloadOperator":
				case "IszeroOperator": { // pop 1, push 1
					if (hasBottomUntil(1))
						return bottom();

					TaintAbstractDomain resultStack = clone();
					TaintElement opnd1 = resultStack.pop();
					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(opnd1));
					return resultStack;
				}

				case "MloadOperator": { // pop 1, push 1
					if (hasBottomUntil(1))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.pop();
					if (memory.isTaint())
						resultStack.push(TaintElement.TAINT);
					else if (memory.isClean())
						resultStack.push(TaintElement.CLEAN);

					return resultStack;
				}

				case "MstoreOperator":
				case "Mstore8Operator": { // pops 2
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement value = resultStack.pop();

					if (value.isTaint())
						return mk(resultStack.stack, TaintElement.TAINT, resultStack.cfg);
					else if (value.isClean())
						return resultStack;
				}
				case "McopyOperator": { // pops 3
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();

					resultStack.popX(3);
					return resultStack;
				}

				case "ByteOperator":
				case "ShlOperator":
				case "ShrOperator":
				case "SarOperator":
				case "Sha3Operator":
				case "AndOperator":
				case "OrOperator":
				case "XorOperator":
				case "ExpOperator":
				case "SignextendOperator":
				case "LtOperator":
				case "SltOperator":
				case "GtOperator":
				case "SgtOperator":
				case "EqOperator":
				case "SmodOperator":
				case "ModOperator":
				case "SdivOperator":
				case "DivOperator":
				case "MulOperator":
				case "SubOperator":
				case "AddOperator": { // pops 2, push 1
					if (hasBottomUntil(2))
						return bottom();

					TaintAbstractDomain resultStack = clone();
					TaintElement opnd1 = resultStack.pop();
					TaintElement opnd2 = resultStack.pop();

					resultStack.push(TaintElement.semantics(opnd1, opnd2));
					return resultStack;
				}

				case "MulmodOperator":
				case "AddmodOperator": { // pops 3, push 1
					if (hasBottomUntil(3))
						return bottom();

					TaintAbstractDomain resultStack = clone();
					TaintElement opnd1 = resultStack.pop();
					TaintElement opnd2 = resultStack.pop();
					TaintElement opnd3 = resultStack.pop();

					resultStack.push(TaintElement.semantics(opnd1, opnd2, opnd3));
					return resultStack;
				}

				case "PopOperator": { // POP
					if (hasBottomUntil(1))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.pop();
					return resultStack;
				}

				case "SstoreOperator": { // pops 2
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(2);

					return resultStack;
				}

				case "Dup1Operator": { // DUP1
					return dupXoperator(1, this);
				}
				case "Dup2Operator": { // DUP2
					return dupXoperator(2, this);
				}
				case "Dup3Operator": { // DUP3
					return dupXoperator(3, this);
				}
				case "Dup4Operator": { // DUP4
					return dupXoperator(4, this);
				}
				case "Dup5Operator": { // DUP5
					return dupXoperator(5, this);
				}
				case "Dup6Operator": { // DUP6
					return dupXoperator(6, this);
				}
				case "Dup7Operator": { // DUP7
					return dupXoperator(7, this);
				}
				case "Dup8Operator": { // DUP8
					return dupXoperator(8, this);
				}
				case "Dup9Operator": { // DUP9
					return dupXoperator(9, this);
				}
				case "Dup10Operator": { // DUP10
					return dupXoperator(10, this);
				}
				case "Dup11Operator": { // DUP11
					return dupXoperator(11, this);
				}
				case "Dup12Operator": { // DUP12
					return dupXoperator(12, this);
				}
				case "Dup13Operator": { // DUP13
					return dupXoperator(13, this);
				}
				case "Dup14Operator": { // DUP14
					return dupXoperator(14, this);
				}
				case "Dup15Operator": { // DUP15
					return dupXoperator(15, this);
				}
				case "Dup16Operator": { // DUP16
					return dupXoperator(16, this);
				}
				case "Swap1Operator": { // SWAP1
					return swapXoperator(1, this);
				}
				case "Swap2Operator": { // SWAP2
					return swapXoperator(2, this);
				}
				case "Swap3Operator": { // SWAP3
					return swapXoperator(3, this);
				}
				case "Swap4Operator": { // SWAP4
					return swapXoperator(4, this);
				}
				case "Swap5Operator": { // SWAP5
					return swapXoperator(5, this);
				}
				case "Swap6Operator": { // SWAP6
					return swapXoperator(6, this);
				}
				case "Swap7Operator": { // SWAP7
					return swapXoperator(7, this);
				}
				case "Swap8Operator": { // SWAP8
					return swapXoperator(8, this);
				}
				case "Swap9Operator": { // SWAP9
					return swapXoperator(9, this);
				}
				case "Swap10Operator": { // SWAP10
					return swapXoperator(10, this);
				}
				case "Swap11Operator": { // SWAP11
					return swapXoperator(11, this);
				}
				case "Swap12Operator": { // SWAP12
					return swapXoperator(12, this);
				}
				case "Swap13Operator": { // SWAP13
					return swapXoperator(13, this);
				}
				case "Swap14Operator": { // SWAP14
					return swapXoperator(14, this);
				}
				case "Swap15Operator": { // SWAP15
					return swapXoperator(15, this);
				}
				case "Swap16Operator": { // SWAP16
					return swapXoperator(16, this);
				}
				case "Log0Operator": { // LOG0
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(2);

					return resultStack;
				}
				case "Log1Operator": { // LOG1
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(3);

					return resultStack;
				}
				case "Log2Operator": { // LOG2
					if (hasBottomUntil(4))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(4);

					return resultStack;
				}
				case "Log3Operator": { // LOG3
					if (hasBottomUntil(5))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(5);

					return resultStack;
				}
				case "Log4Operator": { // LOG4
					if (hasBottomUntil(6))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(6);

					return resultStack;
				}
				case "CreateOperator": { // CREATE
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement value = resultStack.pop();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(value, offset, length));
					return resultStack;
				}
				case "Create2Operator": { // CREATE2
					if (hasBottomUntil(4))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement value = resultStack.pop();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					TaintElement salt = resultStack.pop();

					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(value, offset, length, salt));
					return resultStack;
				}
				case "CallOperator":
				case "CallcodeOperator": { // pops 7, push 1
					if (hasBottomUntil(7))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement gas = resultStack.pop();
					TaintElement to = resultStack.pop();
					TaintElement value = resultStack.pop();
					TaintElement inOffset = resultStack.pop();
					TaintElement inLength = resultStack.pop();
					TaintElement outOffset = resultStack.pop();
					TaintElement outLength = resultStack.pop();

					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack
								.push(TaintElement.semantics(gas, to, value, inOffset, inLength, outOffset, outLength));
					return resultStack;
				}
				case "ReturnOperator": { // RETURN
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					return resultStack;
				}
				case "DelegatecallOperator":
				case "StaticcallOperator": { // pops 6, push 1
					if (hasBottomUntil(6))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement gas = resultStack.pop();
					TaintElement to = resultStack.pop();
					TaintElement inOffset = resultStack.pop();
					TaintElement inLength = resultStack.pop();
					TaintElement outOffset = resultStack.pop();
					TaintElement outLength = resultStack.pop();

					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(gas, to, inOffset, inLength, outOffset, outLength));
					return resultStack;
				}
				case "RevertOperator": { // REVERT
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(2);

					return resultStack;
				}
				case "InvalidOperator": { // INVALID
					return this;
				}
				case "SelfdestructOperator": { // SELFDESTRUCT
					if (hasBottomUntil(1))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement recipient = resultStack.pop();

					return resultStack;
				}
				case "CodecopyOperator": { // CODECOPY
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(3);

					return resultStack;
				}
				case "ExtcodesizeOperator": { // EXTCODESIZE
					if (hasBottomUntil(1))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement address = resultStack.pop();

					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(address));
					return resultStack;
				}
				case "ExtcodecopyOperator": { // EXTCODECOPY
					if (hasBottomUntil(4))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(4);

					return resultStack;
				}
				case "ReturndatacopyOperator": { // RETURNDATACOPY
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.popX(3);

					return resultStack;
				}
				case "ExtcodehashOperator": { // EXTCODEHASH
					if (hasBottomUntil(1))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement address = resultStack.pop();

					if (this.isTainted((Statement) pp))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(address));
					return resultStack;
				}
				}
			}
		}

		throw new SemanticException("Unrecognized opcode: " + pp);
	}

	private TaintAbstractDomain dupXoperator(int x, TaintAbstractDomain other) {
		if (other.isEmpty() || other.hasBottomUntil(x))
			return bottom();
		return other.dupX(x);
	}

	private TaintAbstractDomain swapXoperator(int x, TaintAbstractDomain stack) {
		if (stack.isEmpty() || stack.hasBottomUntil(x + 1))
			return bottom();
		return stack.swapX(x);
	}

	/**
	 * Checks whether the stack is empty.
	 *
	 * @return {@code true} if the first element is bottom, {@code false}
	 *             otherwise.
	 */
	public boolean isEmpty() {
		return getFirstElement().isBottom();
	}

	/**
	 * Swaps the 1st with the (x + 1)-th element from the top of the stack and
	 * returns the modified stack.
	 *
	 * @param x The position of the element to swap with the top of the stack.
	 *
	 * @return A new stack with the specified elements swapped.
	 */
	public TaintAbstractDomain swapX(int x) {
		if (hasBottomUntil(x + 1))
			return bottom();
		x++;
		int posX = (tail - x + STACK_LIMIT) % STACK_LIMIT;
		int topIndex = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;
		TaintAbstractDomain copy = this.clone();
		TaintElement tmp = copy.stack[posX];
		copy.stack[posX] = copy.stack[topIndex];
		copy.stack[topIndex] = tmp;
		return copy;
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
	public TaintAbstractDomain dupX(int x) {
		if (hasBottomUntil(x))
			return bottom();
		int posX = (tail - x + STACK_LIMIT) % STACK_LIMIT;
		TaintAbstractDomain copy = this.clone();
		copy.push(stack[posX]);
		return copy;
	}

	@Override
	public TaintAbstractDomain assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest,
			SemanticOracle oracle) {
		// nothing to do here
		return this;
	}

	@Override
	public boolean knowsIdentifier(Identifier id) {
		// nothing to do here
		return false;
	}

	@Override
	public TaintAbstractDomain forgetIdentifier(Identifier id) {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractDomain forgetIdentifiersIf(Predicate<Identifier> test) {
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

		return new StringRepresentation(this.toString());
	}

	@Override
	public String toString() {
		if (isBottom())
			return Lattice.BOTTOM_STRING;
		if (isTop())
			return Lattice.TOP_STRING;
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < STACK_LIMIT; i++) {
			int pos = (head + i) % STACK_LIMIT;
			sb.append(stack[pos]);
			if (i < STACK_LIMIT - 1)
				sb.append(", ");
		}
		sb.append("]");
		return sb.toString();
	}

	@Override
	public TaintAbstractDomain pushScope(ScopeToken token) {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractDomain popScope(ScopeToken token) {
		// nothing to do here
		return this;
	}

	protected static TaintElement[] createFilledArray(int size, TaintElement element) {
		TaintElement[] array = new TaintElement[size];
		Arrays.fill(array, element);
		return array;
	}

	/**
	 * Computes the greatest lower bound (GLB) between this abstract domain and
	 * another.
	 *
	 * @param other the other domain
	 *
	 * @return a new domain representing the greatest lower bound of the two
	 *             domains
	 */
	@Override
	public TaintAbstractDomain glbAux(TaintAbstractDomain other) throws SemanticException {
		TaintElement[] result = new TaintElement[STACK_LIMIT];
		for (int i = 0; i < STACK_LIMIT; i++) {
			result[i] = this.get(i).glb(other.get(i));
		}
		return mk(result, this.memory.glb(other.memory), this.cfg);
	}

	/**
	 * Computes the least upper bound (LUB) between this abstract domain and
	 * another.
	 *
	 * @param other the other domain
	 *
	 * @return a new domain representing the least upper bound of the two
	 *             domains
	 */
	@Override
	public TaintAbstractDomain lubAux(TaintAbstractDomain other) throws SemanticException {
		TaintElement[] result = new TaintElement[STACK_LIMIT];
		for (int i = 0; i < STACK_LIMIT; i++) {
			result[i] = this.get(i).lub(other.get(i));
		}
		return mk(result, this.memory.lub(other.memory), this.cfg);
	}

	/**
	 * Get a specific element of the stack.
	 *
	 * @param index the index of the element
	 *
	 * @return the StackElement at the given index, or BOTTOM if out of bounds
	 */
	public TaintElement get(int index) {
		if (index < 0 || index >= STACK_LIMIT)
			return TaintElement.BOTTOM;
		return stack[(head + index) % STACK_LIMIT];
	}

	@Override
	public boolean lessOrEqualAux(TaintAbstractDomain other) throws SemanticException {
		for (int i = 0; i < STACK_LIMIT; i++)
			if (!this.get(i).lessOrEqual(other.get(i)))
				return false;

		return true;
	}

	/**
	 * Pushes the specified element onto the stack.
	 * <p>
	 * This method inserts the given {@link TaintElement} at the tail of the
	 * circular array, effectively updating the top of the stack. The head of
	 * the stack is also updated to maintain the circular nature of the
	 * structure.
	 *
	 * @param target the element to be pushed onto the stack
	 */
	public void push(TaintElement target) {
		stack[tail] = target;
		tail = (tail + 1) % STACK_LIMIT;
		head = (head + 1) % STACK_LIMIT;
	}

	/**
	 * Pops the element from the stack.
	 * <p>
	 * This method removes and returns the topmost element of the stack. After
	 * popping, the stack structure is adjusted by shifting the head, and the
	 * previous bottommost element is updated based on the next element. If the
	 * next element is {@link TaintElement#TOP}, the bottom is set to TOP,
	 * otherwise, it is set to {@link TaintElement#BOTTOM}.
	 *
	 * @return the element at the top of the stack before popping
	 */
	public TaintElement pop() {
		int topIndex = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;
		TaintElement popped = stack[topIndex];

		head = (head - 1 + STACK_LIMIT) % STACK_LIMIT;
		int bottomIndex = head;
		int nextIndex = (head + 1) % STACK_LIMIT;

		if (stack[nextIndex].isTop())
			stack[bottomIndex] = TaintElement.TOP;
		else
			stack[bottomIndex] = TaintElement.BOTTOM;
		tail = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;
		stack[topIndex] = TaintElement.BOTTOM;

		return popped;
	}

	/**
	 * Checks whether between 0 and x-positions of the stack an element is
	 * bottom. Checks whether between 0 and x-positions of the stack an element
	 * is bottom.
	 *
	 * @param x the position
	 *
	 * @return {@code true} if between 0 and x-positions of the stack an element
	 *             is bottom, {@code false} otherwise.
	 */
	public boolean hasBottomUntil(int x) {
		for (int i = 0; i < x; i++) {
			int index = (tail - 1 - i + STACK_LIMIT) % STACK_LIMIT;
			if (stack[index].isBottom())
				return true;
		}
		return false;
	}

	@Override
	public TaintAbstractDomain clone() {
		TaintElement[] newArray = stack.clone();
		TaintAbstractDomain copy = mk(newArray, memory, this.cfg);
		copy.head = this.head;
		copy.tail = this.tail;
		return copy;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (!(obj instanceof TaintAbstractDomain))
			return false;
		TaintAbstractDomain other = (TaintAbstractDomain) obj;

		if (isBottom() || other.isBottom())
			return isBottom() == other.isBottom();

		if (!memory.equals(other.memory))
			return false;

		return Arrays.equals(this.stack, other.stack);
	}

	@Override
	public int hashCode() {
		return Objects.hash(stack, memory, cfg);
	}

	/**
	 * Yields the second element of this abstract stack.
	 *
	 * @return the second element of this abstract stack
	 */
	public TaintElement getSecondElement() {
		return getElementAtPosition(2);
	}

	/**
	 * Yields the first element of this abstract stack.
	 *
	 * @return the first element of this abstract stack
	 */
	public TaintElement getFirstElement() {
		return getElementAtPosition(1);
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

	/**
	 * Retrieves the element from the stack at the specified position. The
	 * position is calculated from the top of the stack, where the top is at
	 * position 1. If the stack state is {@code BOTTOM},
	 * {@code TaintElement.BOTTOM} is returned. If the stack state is
	 * {@code TOP}, {@code TaintElement.TOP} is returned.
	 *
	 * @param position the position of the element to retrieve from the stack
	 *
	 * @return the element at the specified position in the stack
	 */
	public TaintElement getElementAtPosition(int position) {
		if (position < 1 || position > STACK_LIMIT)
			throw new IllegalArgumentException("Invalid position: " + position);
		if (isBottom())
			return TaintElement.BOTTOM;
		else if (isTop())
			return TaintElement.TOP;
		return stack[(tail - position + STACK_LIMIT) % STACK_LIMIT];
	}

	/**
	 * Determines whether the given statement is tainted.
	 *
	 * @param stmt the statement to check
	 *
	 * @return {@code true} if the statement is tainted, {@code false}
	 *             otherwise.
	 */
	public abstract boolean isTainted(Statement stmt);

	/**
	 * Yields the set of opcodes that sanitize the state.
	 *
	 * @return the set of opcodes that sanitize the state
	 */
	public abstract Set<Operator> getSanitizedOpcode();

	/**
	 * Utility for creating a concrete instance of {@link TaintAbstractDomain}
	 * given the stack and the memory.
	 *
	 * @param stack  the stack
	 * @param memory the memory
	 *
	 * @return a new concrete instance of {@link TaintAbstractDomain}
	 */
	public abstract TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory);

	/**
	 * Utility for creating a concrete instance of {@link TaintAbstractDomain}
	 * given the stack, the memory and the CFG.
	 *
	 * @param stack  the stack
	 * @param memory the memory
	 * @param cfg    the CFG
	 *
	 * @return a new concrete instance of {@link TaintAbstractDomain}
	 */
	public abstract TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory, EVMCFG cfg);
}