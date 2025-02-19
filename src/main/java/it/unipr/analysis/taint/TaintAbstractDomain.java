package it.unipr.analysis.taint;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.function.Predicate;

import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SemanticOracle;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.Operator;
import it.unive.lisa.symbolic.value.Skip;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;

public abstract class TaintAbstractDomain
implements ValueDomain<TaintAbstractDomain>, BaseLattice<TaintAbstractDomain> {

	static int STACK_LIMIT = 32;

	/**
	 * The abstract stack domain
	 */
	private final ArrayList<TaintElement> stack;

	
	/**
	 * The local memory, tracking if it is clean or tainted.
	 */
	private final TaintElement memory;
	
	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected TaintAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory) {
		this.stack = stack;
		this.memory = memory;
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
				case "BasefeeOperator":
				case "CalldatasizeOperator":
				case "CallvalueOperator":
				case "CallerOperator":
				case "AddressOperator":
				case "PushOperator":
				case "Push0Operator": {
					TaintAbstractDomain resultStack = clone();
					if (this.getTaintedOpcode().contains(op))
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
				case "JumpiOperator": { // JUMPI
					if (hasBottomUntil(2))
						return bottom();

					TaintAbstractDomain resultStack = clone();
					TaintElement opnd1 = resultStack.pop();
					TaintElement opnd2 = resultStack.pop();

					return resultStack;
				}

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
					if (this.getTaintedOpcode().contains(op))
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
						return mk(resultStack.stack, TaintElement.TAINT);
					else if (value.isClean())
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

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}

				case "SstoreOperator": { // pops 2
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}

				case "Dup1Operator": { // DUP1
					return dupXoperator(1, clone());
				}
				case "Dup2Operator": { // DUP2
					return dupXoperator(2, clone());
				}
				case "Dup3Operator": { // DUP3
					return dupXoperator(3, clone());
				}
				case "Dup4Operator": { // DUP4
					return dupXoperator(4, clone());
				}
				case "Dup5Operator": { // DUP5
					return dupXoperator(5, clone());
				}
				case "Dup6Operator": { // DUP6
					return dupXoperator(6, clone());
				}
				case "Dup7Operator": { // DUP7
					return dupXoperator(7, clone());
				}
				case "Dup8Operator": { // DUP8
					return dupXoperator(8, clone());
				}
				case "Dup9Operator": { // DUP9
					return dupXoperator(9, clone());
				}
				case "Dup10Operator": { // DUP10
					return dupXoperator(10, clone());
				}
				case "Dup11Operator": { // DUP11
					return dupXoperator(11, clone());
				}
				case "Dup12Operator": { // DUP12
					return dupXoperator(12, clone());
				}
				case "Dup13Operator": { // DUP13
					return dupXoperator(13, clone());
				}
				case "Dup14Operator": { // DUP14
					return dupXoperator(14, clone());
				}
				case "Dup15Operator": { // DUP15
					return dupXoperator(15, clone());
				}
				case "Dup16Operator": { // DUP16
					return dupXoperator(16, clone());
				}
				case "Swap1Operator": { // SWAP1
					return swapXoperator(1, clone());
				}
				case "Swap2Operator": { // SWAP2
					return swapXoperator(2, clone());
				}
				case "Swap3Operator": { // SWAP3
					return swapXoperator(3, clone());
				}
				case "Swap4Operator": { // SWAP4
					return swapXoperator(4, clone());
				}
				case "Swap5Operator": { // SWAP5
					return swapXoperator(5, clone());
				}
				case "Swap6Operator": { // SWAP6
					return swapXoperator(6, clone());
				}
				case "Swap7Operator": { // SWAP7
					return swapXoperator(7, clone());
				}
				case "Swap8Operator": { // SWAP8
					return swapXoperator(8, clone());
				}
				case "Swap9Operator": { // SWAP9
					return swapXoperator(9, clone());
				}
				case "Swap10Operator": { // SWAP10
					return swapXoperator(10, clone());
				}
				case "Swap11Operator": { // SWAP11
					return swapXoperator(11, clone());
				}
				case "Swap12Operator": { // SWAP12
					return swapXoperator(12, clone());
				}
				case "Swap13Operator": { // SWAP13
					return swapXoperator(13, clone());
				}
				case "Swap14Operator": { // SWAP14
					return swapXoperator(14, clone());
				}
				case "Swap15Operator": { // SWAP15
					return swapXoperator(15, clone());
				}
				case "Swap16Operator": { // SWAP16
					return swapXoperator(16, clone());
				}
				case "Log0Operator": { // LOG0
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "Log1Operator": { // LOG1
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "Log2Operator": { // LOG2
					if (hasBottomUntil(4))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "Log3Operator": { // LOG3
					if (hasBottomUntil(5))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();
					resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "Log4Operator": { // LOG4
					if (hasBottomUntil(6))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();
					resultStack.pop();
					resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "CreateOperator": { // CREATE
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement value = resultStack.pop();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (this.getTaintedOpcode().contains(op))
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

					if (this.getTaintedOpcode().contains(op))
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

					if (this.getTaintedOpcode().contains(op))
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

					if (resultStack.isEmpty())
						return bottom();
					else
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

					if (this.getTaintedOpcode().contains(op))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(gas, to, inOffset, inLength, outOffset, outLength));
					return resultStack;
				}
				case "RevertOperator": { // REVERT
					if (hasBottomUntil(2))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
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

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "CodecopyOperator": { // CODECOPY
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement memOffset = resultStack.pop();
					TaintElement dataOffset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "ExtcodesizeOperator": { // EXTCODESIZE
					if (hasBottomUntil(1))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement address = resultStack.pop();

					if (this.getTaintedOpcode().contains(op))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(address));
					return resultStack;
				}
				case "ExtcodecopyOperator": { // EXTCODECOPY
					if (hasBottomUntil(4))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement address = resultStack.pop();
					TaintElement memOffset = resultStack.pop();
					TaintElement dataOffset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "ReturndatacopyOperator": { // RETURNDATACOPY
					if (hasBottomUntil(3))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement memOffset = resultStack.pop();
					TaintElement dataOffset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return bottom();
					else
						return resultStack;
				}
				case "ExtcodehashOperator": { // EXTCODEHASH
					if (hasBottomUntil(1))
						return bottom();
					TaintAbstractDomain resultStack = clone();
					TaintElement address = resultStack.pop();

					if (this.getTaintedOpcode().contains(op))
						resultStack.push(TaintElement.TAINT);
					else
						resultStack.push(TaintElement.semantics(address));
					return resultStack;
				}
				}
			}
		}

		if (!(expression instanceof Skip))
			throw new SemanticException("Reachable just with the skip node");

		return top();
	}

	private TaintAbstractDomain dupXoperator(int x, TaintAbstractDomain stack) {
		if (stack.isEmpty() || stack.hasBottomUntil(x))
			return bottom();
		return dupX(x, stack.clone());
	}

	private TaintAbstractDomain swapXoperator(int x, TaintAbstractDomain stack) {
		if (stack.isEmpty() || stack.hasBottomUntil(x))
			return bottom();
		return swapX(x, stack.clone());
	}

	private TaintAbstractDomain swapX(int x, TaintAbstractDomain stack) {
		List<TaintElement> clone = stack.clone().getStack();

		if (stack.size() < x + 1 || x < 1)
			return stack.bottom();

		Object[] obj = clone.toArray();
		int first;

		if (stack.size() < STACK_LIMIT)
			first = STACK_LIMIT - 1;
		else
			first = clone.size() - 1;

		Object tmp = obj[first];
		obj[first] = obj[first - x];
		obj[first - x] = tmp;

		ArrayList<TaintElement> result = new ArrayList<>();

		for (int i = 0; i < clone.size(); i++)
			result.add((TaintElement) obj[i]);

		return mk(result, stack.memory);
	}

	private TaintAbstractDomain dupX(int x, TaintAbstractDomain stack) {
		List<TaintElement> clone = stack.clone().getStack();

		if (stack.size() < x || x < 1)
			return stack.bottom();

		Object[] obj = clone.toArray();

		int first;
		if (stack.size() < STACK_LIMIT)
			first = STACK_LIMIT;
		else
			first = clone.size();

		TaintElement tmp = (TaintElement) obj[first - x];

		ArrayList<TaintElement> result = new ArrayList<>();

		for (int i = 0; i < clone.size(); i++)
			result.add((TaintElement) obj[i]);

		result.add(tmp);
		result.remove(0);

		return mk(result, stack.memory);
	}

	private ArrayList<TaintElement> getStack() {
		return stack;
	}

	private int size() {
		int bottomCounter = 0;
		for (TaintElement item : stack) {
			if (item.isBottom()) {
				bottomCounter++;
			}
		}
		return stack.size() - bottomCounter;
	}

	private boolean isEmpty() {
		if (!stack.isEmpty())
			return false;
		else
			return true;
	}

	@Override
	public TaintAbstractDomain assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest,
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
	public TaintAbstractDomain forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractDomain forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
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
	public String toString() {
		if (isBottom())
			return Lattice.BOTTOM_STRING;
		else if (isTop())
			return Lattice.TOP_STRING;

		return stack.toString();
	}

	@Override
	public TaintAbstractDomain pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractDomain popScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractDomain glbAux(TaintAbstractDomain other) throws SemanticException {
		ArrayList<TaintElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<TaintElement> thisIterator = this.stack.iterator();
		Iterator<TaintElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			TaintElement thisElement = thisIterator.next();
			TaintElement otherElement = otherIterator.next();
			result.add(thisElement.glb(otherElement));
		}

		return mk(result, this.memory.glb(other.memory));
	}

	@Override
	public TaintAbstractDomain lubAux(TaintAbstractDomain other) throws SemanticException {
		ArrayList<TaintElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<TaintElement> thisIterator = this.stack.iterator();
		Iterator<TaintElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			TaintElement thisElement = thisIterator.next();
			TaintElement otherElement = otherIterator.next();
			result.add(thisElement.lub(otherElement));
		}

		return mk(result, this.memory.lub(other.memory));
	}

	@Override
	public boolean lessOrEqualAux(TaintAbstractDomain other) throws SemanticException {
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

	@Override
	public TaintAbstractDomain clone() {
		if (isBottom())
			return this;
		return mk(new ArrayList<>(stack), this.memory);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		TaintAbstractDomain other = (TaintAbstractDomain) obj;
		return Objects.equals(memory, other.memory) && Objects.equals(stack, other.stack);
	}

	@Override
	public int hashCode() {
		return Objects.hash(memory, stack);
	}

	public TaintElement getSecondElement() {
		if (isBottom())
			return TaintElement.BOTTOM;
		else if (isTop())
			return TaintElement.TOP;
		return this.stack.get(STACK_LIMIT - 2);
	}

	public TaintElement getFirstElement() {
		if (isBottom())
			return TaintElement.BOTTOM;
		else if (isTop())
			return TaintElement.TOP;
		return this.stack.get(STACK_LIMIT - 1);
	}

	public abstract Set<Operator> getTaintedOpcode();

	public abstract TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory);

}