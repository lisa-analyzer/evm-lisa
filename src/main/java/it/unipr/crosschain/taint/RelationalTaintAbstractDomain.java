package it.unipr.crosschain.taint;

import it.unipr.cfg.ProgramCounterLocation;
import it.unive.lisa.analysis.*;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.*;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.util.Arrays;
import java.util.Objects;
import java.util.Set;
import java.util.function.Predicate;

/**
 * An abstract domain for taint analysis of EVM smart contracts.
 * <p>
 * This abstract class provides the framework to track and propagate taint
 * information along the symbolic execution of EVM bytecode. It models a
 * circular stack of {@link RelationalTaintElement} objects and an associated
 * memory element. Concrete implementations should define how to determine
 * whether a statement is tainted and provide a set of sanitizing opcodes, as
 * well as instantiate new instances of the domain.
 * </p>
 *
 * @see RelationalTaintElement
 * @see ValueDomain
 * @see BaseLattice
 */
public abstract class RelationalTaintAbstractDomain
		implements ValueDomain<RelationalTaintAbstractDomain>, BaseLattice<RelationalTaintAbstractDomain> {

	/**
	 * The stack limit.
	 */
	protected static int STACK_LIMIT = 32;

	/**
	 * The abstract stack as a circular array.
	 */
	private final RelationalTaintElement[] stack;

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
	private final RelationalTaintElement memory;

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint. Builds a taint abstract stack starting from a
	 * given stack and a memory element.
	 *
	 * @param stack  the stack of values
	 * @param memory the memory element
	 */
	protected RelationalTaintAbstractDomain(RelationalTaintElement[] stack, RelationalTaintElement memory) {
		this(stack, 0, 0, memory);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack, a list of
	 * elements that push taint, the head and the tail of the given stack.
	 * Builds a taint abstract stack starting from a given stack and a memory
	 * element.
	 *
	 * @param stack  the stack of values
	 * @param memory the memory element
	 * @param head   the head index of the circular stack
	 * @param tail   the tail index of the circular stack
	 */
	protected RelationalTaintAbstractDomain(RelationalTaintElement[] stack, int head, int tail,
			RelationalTaintElement memory) {
		this.stack = stack;
		this.memory = memory;
		this.head = head;
		this.tail = tail;
	}

	@Override
	public RelationalTaintAbstractDomain assign(Identifier id, ValueExpression expression, ProgramPoint pp,
			SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@SuppressWarnings("unused")
	@Override
	public RelationalTaintAbstractDomain smallStepSemantics(ValueExpression expression, ProgramPoint pp,
			SemanticOracle oracle)
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
					RelationalTaintAbstractDomain resultStack = clone();
					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack.push(RelationalTaintElement.CLEAN);
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

					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement opnd1 = resultStack.pop();

					return resultStack;
				}

				case "TstoreOperator":
				case "JumpiOperator": {
					if (hasBottomUntil(2))
						return bottom();

					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(2);

					return resultStack;
				}

				case "TloadOperator": {
					if (hasBottomUntil(2))
						return bottom();

					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement key = resultStack.pop();
					resultStack.push(RelationalTaintElement.TOP);

					return resultStack;
				}
				case "CalldatacopyOperator": {
					if (hasBottomUntil(3))
						return bottom();

					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(3);

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						return mk(resultStack.stack, resultStack.head, resultStack.tail, RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));

					return resultStack;
				}

				case "BlobHashOperator":
				case "BalanceOperator":
				case "BlockhashOperator":
				case "NotOperator":
				case "SloadOperator":
				case "IszeroOperator":
				case "CalldataloadOperator": { // pop 1, push 1
					if (hasBottomUntil(1))
						return bottom();

					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement opnd1 = resultStack.pop();

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack.push(RelationalTaintElement.semantics(opnd1));
					return resultStack;
				}

				case "MloadOperator": { // pop 1, push 1
					if (hasBottomUntil(1))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.pop();
					if (memory.isTaint())
						resultStack.push(RelationalTaintElement.newRelationalTaintedElement(memory.getProgramPoints()));
					else if (memory.isClean())
						resultStack.push(RelationalTaintElement.CLEAN);

					return resultStack;
				}

				case "MstoreOperator":
				case "Mstore8Operator": { // pops 2
					if (hasBottomUntil(2))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement offset = resultStack.pop();
					RelationalTaintElement value = resultStack.pop();

					if (offset.isClean() && value.isClean())
						return resultStack;

					return mk(resultStack.stack, resultStack.head, resultStack.tail,
							RelationalTaintElement.semantics(offset, value, memory));
				}
				case "McopyOperator": { // pops 3
					if (hasBottomUntil(3))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();

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

					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement opnd1 = resultStack.pop();
					RelationalTaintElement opnd2 = resultStack.pop();

					resultStack.push(RelationalTaintElement.semantics(opnd1, opnd2));
					return resultStack;
				}

				case "MulmodOperator":
				case "AddmodOperator": { // pops 3, push 1
					if (hasBottomUntil(3))
						return bottom();

					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement opnd1 = resultStack.pop();
					RelationalTaintElement opnd2 = resultStack.pop();
					RelationalTaintElement opnd3 = resultStack.pop();

					resultStack.push(RelationalTaintElement.semantics(opnd1, opnd2, opnd3));
					return resultStack;
				}

				case "PopOperator": { // POP
					if (hasBottomUntil(1))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.pop();
					return resultStack;
				}

				case "SstoreOperator": { // pops 2
					if (hasBottomUntil(2))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
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
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(2);

					return resultStack;
				}
				case "Log1Operator": { // LOG1
					if (hasBottomUntil(3))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(3);

					return resultStack;
				}
				case "Log2Operator": { // LOG2
					if (hasBottomUntil(4))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(4);

					return resultStack;
				}
				case "Log3Operator": { // LOG3
					if (hasBottomUntil(5))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(5);

					return resultStack;
				}
				case "Log4Operator": { // LOG4
					if (hasBottomUntil(6))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(6);

					return resultStack;
				}
				case "CreateOperator": { // CREATE
					if (hasBottomUntil(3))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement value = resultStack.pop();
					RelationalTaintElement offset = resultStack.pop();
					RelationalTaintElement length = resultStack.pop();

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack.push(RelationalTaintElement.semantics(value, offset, length));
					return resultStack;
				}
				case "Create2Operator": { // CREATE2
					if (hasBottomUntil(4))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement value = resultStack.pop();
					RelationalTaintElement offset = resultStack.pop();
					RelationalTaintElement length = resultStack.pop();
					RelationalTaintElement salt = resultStack.pop();

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack.push(RelationalTaintElement.semantics(value, offset, length, salt));
					return resultStack;
				}
				case "CallOperator":
				case "CallcodeOperator": { // pops 7, push 1
					if (hasBottomUntil(7))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement gas = resultStack.pop();
					RelationalTaintElement to = resultStack.pop();
					RelationalTaintElement value = resultStack.pop();
					RelationalTaintElement inOffset = resultStack.pop();
					RelationalTaintElement inLength = resultStack.pop();
					RelationalTaintElement outOffset = resultStack.pop();
					RelationalTaintElement outLength = resultStack.pop();

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack
								.push(RelationalTaintElement.semantics(gas, to, value, inOffset, inLength, outOffset,
										outLength));
					return resultStack;
				}
				case "ReturnOperator": { // RETURN
					if (hasBottomUntil(2))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement offset = resultStack.pop();
					RelationalTaintElement length = resultStack.pop();

					return resultStack;
				}
				case "DelegatecallOperator":
				case "StaticcallOperator": { // pops 6, push 1
					if (hasBottomUntil(6))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement gas = resultStack.pop();
					RelationalTaintElement to = resultStack.pop();
					RelationalTaintElement inOffset = resultStack.pop();
					RelationalTaintElement inLength = resultStack.pop();
					RelationalTaintElement outOffset = resultStack.pop();
					RelationalTaintElement outLength = resultStack.pop();

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack.push(
								RelationalTaintElement.semantics(gas, to, inOffset, inLength, outOffset, outLength));
					return resultStack;
				}
				case "RevertOperator": { // REVERT
					if (hasBottomUntil(2))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(2);

					return resultStack;
				}
				case "InvalidOperator": { // INVALID
					return this;
				}
				case "SelfdestructOperator": { // SELFDESTRUCT
					if (hasBottomUntil(1))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement recipient = resultStack.pop();

					return resultStack;
				}
				case "CodecopyOperator": { // CODECOPY
					if (hasBottomUntil(3))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(3);

					return resultStack;
				}
				case "ExtcodesizeOperator": { // EXTCODESIZE
					if (hasBottomUntil(1))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement address = resultStack.pop();

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack.push(RelationalTaintElement.semantics(address));
					return resultStack;
				}
				case "ExtcodecopyOperator": { // EXTCODECOPY
					if (hasBottomUntil(4))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(4);

					return resultStack;
				}
				case "ReturndatacopyOperator": { // RETURNDATACOPY
					if (hasBottomUntil(3))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					resultStack.popX(3);

					return resultStack;
				}
				case "ExtcodehashOperator": { // EXTCODEHASH
					if (hasBottomUntil(1))
						return bottom();
					RelationalTaintAbstractDomain resultStack = clone();
					RelationalTaintElement address = resultStack.pop();

					Statement stmt = (Statement) pp;
					if (this.isTainted(stmt))
						resultStack.push(RelationalTaintElement
								.newRelationalTaintedElement(((ProgramCounterLocation) stmt.getLocation()).getPc()));
					else
						resultStack.push(RelationalTaintElement.semantics(address));
					return resultStack;
				}
				}
			}
		}

		throw new SemanticException("Unrecognized opcode: " + pp);
	}

	private RelationalTaintAbstractDomain dupXoperator(int x, RelationalTaintAbstractDomain other) {
		if (other.isEmpty() || other.hasBottomUntil(x))
			return bottom();
		return other.dupX(x);
	}

	private RelationalTaintAbstractDomain swapXoperator(int x, RelationalTaintAbstractDomain stack) {
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
	public RelationalTaintAbstractDomain swapX(int x) {
		if (hasBottomUntil(x + 1))
			return bottom();
		x++;
		int posX = (tail - x + STACK_LIMIT) % STACK_LIMIT;
		int topIndex = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;
		RelationalTaintAbstractDomain copy = this.clone();
		RelationalTaintElement tmp = copy.stack[posX];
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
	public RelationalTaintAbstractDomain dupX(int x) {
		if (hasBottomUntil(x))
			return bottom();
		int posX = (tail - x + STACK_LIMIT) % STACK_LIMIT;
		RelationalTaintAbstractDomain copy = this.clone();
		copy.push(stack[posX]);
		return copy;
	}

	@Override
	public RelationalTaintAbstractDomain assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest,
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
	public RelationalTaintAbstractDomain forgetIdentifier(Identifier id) {
		// nothing to do here
		return this;
	}

	@Override
	public RelationalTaintAbstractDomain forgetIdentifiersIf(Predicate<Identifier> test) {
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

		return new StringRepresentation(toString());
	}

	@Override
	public String toString() {
		if (isBottom())
			return Lattice.BOTTOM_STRING;
		if (isTop())
			return Lattice.TOP_STRING;

		StringBuilder sb = new StringBuilder("stack: [");
		for (int i = 0; i < STACK_LIMIT; i++) {
			int pos = (head + i) % STACK_LIMIT;
			sb.append(stack[pos]);
			if (i < STACK_LIMIT - 1)
				sb.append(", ");
		}
		sb.append("]");
		sb.append(", memory: ").append(memory).append(" }");
		return sb.toString();
	}

	@Override
	public RelationalTaintAbstractDomain pushScope(ScopeToken token) {
		// nothing to do here
		return this;
	}

	@Override
	public RelationalTaintAbstractDomain popScope(ScopeToken token) {
		// nothing to do here
		return this;
	}

	protected static RelationalTaintElement[] createFilledArray(int size, RelationalTaintElement element) {
		RelationalTaintElement[] array = new RelationalTaintElement[size];
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
	public RelationalTaintAbstractDomain glbAux(RelationalTaintAbstractDomain other) throws SemanticException {
		RelationalTaintElement[] result = new RelationalTaintElement[STACK_LIMIT];
		for (int i = 0; i < STACK_LIMIT; i++) {
			result[i] = this.get(i).glb(other.get(i));
		}
		return mk(result, head, tail, this.memory.glb(other.memory));
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
	public RelationalTaintAbstractDomain lubAux(RelationalTaintAbstractDomain other) throws SemanticException {
		RelationalTaintElement[] result = new RelationalTaintElement[STACK_LIMIT];
		for (int i = 0; i < STACK_LIMIT; i++) {
			result[i] = this.get(i).lub(other.get(i));
		}
		return mk(result, head, tail, this.memory.lub(other.memory));
	}

	/**
	 * Get a specific element of the stack.
	 *
	 * @param index the index of the element
	 *
	 * @return the StackElement at the given index, or BOTTOM if out of bounds
	 */
	public RelationalTaintElement get(int index) {
		if (index < 0 || index >= STACK_LIMIT)
			return RelationalTaintElement.BOTTOM;
		return stack[(head + index) % STACK_LIMIT];
	}

	@Override
	public boolean lessOrEqualAux(RelationalTaintAbstractDomain other) throws SemanticException {
		for (int i = 0; i < STACK_LIMIT; i++)
			if (!this.get(i).lessOrEqual(other.get(i)))
				return false;

		return true;
	}

	/**
	 * Pushes the specified element onto the stack.
	 * <p>
	 * This method inserts the given {@link RelationalTaintElement} at the tail
	 * of the circular array, effectively updating the top of the stack. The
	 * head of the stack is also updated to maintain the circular nature of the
	 * structure.
	 *
	 * @param target the element to be pushed onto the stack
	 */
	public void push(RelationalTaintElement target) {
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
	 * next element is {@link RelationalTaintElement#TOP}, the bottom is set to
	 * TOP, otherwise, it is set to {@link RelationalTaintElement#BOTTOM}.
	 *
	 * @return the element at the top of the stack before popping
	 */
	public RelationalTaintElement pop() {
		int topIndex = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;
		RelationalTaintElement popped = stack[topIndex];

		head = (head - 1 + STACK_LIMIT) % STACK_LIMIT;
		int bottomIndex = head;
		int nextIndex = (head + 1) % STACK_LIMIT;

		if (stack[nextIndex].isTop())
			stack[bottomIndex] = RelationalTaintElement.TOP;
		else
			stack[bottomIndex] = RelationalTaintElement.BOTTOM;
		tail = (tail - 1 + STACK_LIMIT) % STACK_LIMIT;
		stack[topIndex] = RelationalTaintElement.BOTTOM;

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
	public RelationalTaintAbstractDomain clone() {
		RelationalTaintElement[] newArray = stack.clone();
		RelationalTaintAbstractDomain copy = mk(newArray, head, tail, memory);
		copy.head = this.head;
		copy.tail = this.tail;
		return copy;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (!(obj instanceof RelationalTaintAbstractDomain))
			return false;
		RelationalTaintAbstractDomain other = (RelationalTaintAbstractDomain) obj;

		if (isBottom() || other.isBottom())
			return isBottom() == other.isBottom();

		if (!memory.equals(other.memory))
			return false;

		return Arrays.equals(this.stack, other.stack);
	}

	@Override
	public int hashCode() {
		return Objects.hash(stack, memory);
	}

	/**
	 * Yields the second element of this abstract stack.
	 *
	 * @return the second element of this abstract stack
	 */
	public RelationalTaintElement getSecondElement() {
		return getElementAtPosition(2);
	}

	/**
	 * Yields the first element of this abstract stack.
	 *
	 * @return the first element of this abstract stack
	 */
	public RelationalTaintElement getFirstElement() {
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
	 * {@code RelationalTaintElement.BOTTOM} is returned. If the stack state is
	 * {@code TOP}, {@code RelationalTaintElement.TOP} is returned.
	 *
	 * @param position the position of the element to retrieve from the stack
	 *
	 * @return the element at the specified position in the stack
	 */
	public RelationalTaintElement getElementAtPosition(int position) {
		if (position < 1 || position > STACK_LIMIT)
			throw new IllegalArgumentException("Invalid position: " + position);
		if (isBottom())
			return RelationalTaintElement.BOTTOM;
		else if (isTop())
			return RelationalTaintElement.TOP;
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
	 * Utility for creating a concrete instance of
	 * {@link RelationalTaintAbstractDomain} given the stack and the memory.
	 *
	 * @param stack  the stack
	 * @param memory the memory
	 *
	 * @return a new concrete instance of {@link RelationalTaintAbstractDomain}
	 */
	public abstract RelationalTaintAbstractDomain mk(RelationalTaintElement[] stack, int head, int tail,
			RelationalTaintElement memory);
}