package it.unipr.analysis;

import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.representation.DomainRepresentation;
import it.unive.lisa.analysis.representation.StringRepresentation;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.SymbolicExpression;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import java.math.BigInteger;
import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.Objects;

/**
 * Semantic domain of the execution stack of the contract.
 */
public class SymbolicStack implements ValueDomain<SymbolicStack> {

	private static final SymbolicStack TOP = new SymbolicStack();
	private static final SymbolicStack BOTTOM = new SymbolicStack(null);

	private final ArrayDeque<BigInteger> stack;
	private final boolean isTop;

	/**
	 * Constructor of the SymbolicStack class.
	 */
	public SymbolicStack() {
		this(true);
	}

	private SymbolicStack(boolean isTop) {
		this.isTop = isTop;
		this.stack = new ArrayDeque<BigInteger>();
	}

	private SymbolicStack(ArrayDeque<BigInteger> stack) {
		this.stack = stack;
		this.isTop = false;
	}

	@Override
	public SymbolicStack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public SymbolicStack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof PushOperator) { // PUSH
				ArrayDeque<BigInteger> result = stack.clone();

				result.push(toBigInteger(un.getExpression()));

				return new SymbolicStack(result);
			} else if (op instanceof AddOperator) { // ADD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.add(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof SubOperator) { // SUB
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.subtract(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof MulOperator) { // MUL
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.multiply(opnd2));

				return new SymbolicStack(result);
			} else if ((op instanceof DivOperator) || (op instanceof SdivOperator)) { // DIV,
																						// SDIV
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				if (opnd2.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push(opnd1.divide(opnd2));
				}

				return new SymbolicStack(result);
			} else if ((op instanceof ModOperator) || (op instanceof SmodOperator)) { // MOD,
																						// SMOD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				if (opnd2.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push(opnd1.mod(opnd2));
				}

				return new SymbolicStack(result);
			} else if (op instanceof AddmodOperator) { // ADDMOD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();
				BigInteger opnd3 = result.pop();

				if (opnd3.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push((opnd1.add(opnd2)).mod(opnd3));
				}

				return new SymbolicStack(result);
			} else if (op instanceof MulmodOperator) { // MULMOD
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();
				BigInteger opnd3 = result.pop();

				if (opnd3.equals(BigInteger.ZERO)) {
					result.push(BigInteger.ZERO);
				} else {
					result.push((opnd1.multiply(opnd2)).mod(opnd3));
				}

				return new SymbolicStack(result);
			} else if (op instanceof ExpOperator) { // EXP
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.pow(opnd2.intValue()));

				return new SymbolicStack(result);
			} else if (op instanceof SignextendOperator) { // SIGNEXTEND
				ArrayDeque<BigInteger> result = stack.clone();
				// BigInteger offset = result.pop();
				result.pop();
				// BigInteger toExtend = result.pop();

				// result.push(toExtend);

				return new SymbolicStack(result);
			} else if ((op instanceof LtOperator) || (op instanceof SltOperator)) { // LT,
																					// SLT
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.compareTo(opnd2) < 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if ((op instanceof GtOperator) || (op instanceof SgtOperator)) { // GT,
																					// SGT
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.compareTo(opnd2) > 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof EqOperator) { // EQ
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.compareTo(opnd2) == 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof IszeroOperator) { // ISZERO
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();

				result.push(opnd1.compareTo(BigInteger.ZERO) == 0 ? BigInteger.ONE : BigInteger.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof AndOperator) { // AND
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.and(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof OrOperator) { // OR
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.or(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof XorOperator) { // XOR
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();
				BigInteger opnd2 = result.pop();

				result.push(opnd1.xor(opnd2));

				return new SymbolicStack(result);
			} else if (op instanceof NotOperator) { // NOT
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger opnd1 = result.pop();

				opnd1.toByteArray();

				result.push(opnd1.not());

				return new SymbolicStack(result);
			} else if (op instanceof ByteOperator) { // BYTE
				ArrayDeque<BigInteger> result = stack.clone();
				BigInteger byteToSelect = result.pop();
				BigInteger value = result.pop();
				byte[] valueAsByteArray = value.toByteArray();

				if ((byteToSelect.compareTo(BigInteger.valueOf(0)) < 0)
						|| (byteToSelect.compareTo(BigInteger.valueOf(valueAsByteArray.length)) >= 0)) {
					result.push(BigInteger.ZERO);
				} else {
					byte selectedByte = value.toByteArray()[byteToSelect.intValue()];
					byte[] resultByteArray = BigInteger.ZERO.toByteArray();

					resultByteArray[0] = selectedByte;

					result.push(new BigInteger(resultByteArray));
				}

				return new SymbolicStack(result);
			} else if (op instanceof Dup1Operator) { // DUP1

				return new SymbolicStack(dupX(1, stack.clone()));

			} else if (op instanceof Dup2Operator) { // DUP2

				return new SymbolicStack(dupX(2, stack.clone()));

			} else if (op instanceof Dup3Operator) { // DUP3

				return new SymbolicStack(dupX(3, stack.clone()));

			} else if (op instanceof Dup4Operator) { // DUP4

				return new SymbolicStack(dupX(4, stack.clone()));

			} else if (op instanceof Dup5Operator) { // DUP5

				return new SymbolicStack(dupX(5, stack.clone()));

			} else if (op instanceof Dup6Operator) { // DUP6

				return new SymbolicStack(dupX(6, stack.clone()));

			} else if (op instanceof Dup7Operator) { // DUP7

				return new SymbolicStack(dupX(7, stack.clone()));

			} else if (op instanceof Dup8Operator) { // DUP8

				return new SymbolicStack(dupX(8, stack.clone()));

			} else if (op instanceof Dup9Operator) { // DUP9

				return new SymbolicStack(dupX(9, stack.clone()));

			} else if (op instanceof Dup10Operator) { // DUP10

				return new SymbolicStack(dupX(10, stack.clone()));

			} else if (op instanceof Dup11Operator) { // DUP11

				return new SymbolicStack(dupX(11, stack.clone()));

			} else if (op instanceof Dup12Operator) { // DUP12

				return new SymbolicStack(dupX(12, stack.clone()));

			} else if (op instanceof Dup13Operator) { // DUP13

				return new SymbolicStack(dupX(13, stack.clone()));

			} else if (op instanceof Dup14Operator) { // DUP14

				return new SymbolicStack(dupX(14, stack.clone()));

			} else if (op instanceof Dup15Operator) { // DUP15

				return new SymbolicStack(dupX(15, stack.clone()));

			} else if (op instanceof Dup16Operator) { // DUP16

				return new SymbolicStack(dupX(16, stack.clone()));

			} else if (op instanceof Swap1Operator) { // SWAP1

				return new SymbolicStack(swapX(1, stack.clone()));

			} else if (op instanceof Swap2Operator) { // SWAP2

				return new SymbolicStack(swapX(2, stack.clone()));

			} else if (op instanceof Swap3Operator) { // SWAP3

				return new SymbolicStack(swapX(3, stack.clone()));

			} else if (op instanceof Swap4Operator) { // SWAP4

				return new SymbolicStack(swapX(4, stack.clone()));

			} else if (op instanceof Swap5Operator) { // SWAP5

				return new SymbolicStack(swapX(5, stack.clone()));

			} else if (op instanceof Swap6Operator) { // SWAP6

				return new SymbolicStack(swapX(6, stack.clone()));

			} else if (op instanceof Swap7Operator) { // SWAP7

				return new SymbolicStack(swapX(7, stack.clone()));

			} else if (op instanceof Swap8Operator) { // SWAP8

				return new SymbolicStack(swapX(8, stack.clone()));

			} else if (op instanceof Swap9Operator) { // SWAP9

				return new SymbolicStack(swapX(9, stack.clone()));

			} else if (op instanceof Swap10Operator) { // SWAP10

				return new SymbolicStack(swapX(10, stack.clone()));

			} else if (op instanceof Swap11Operator) { // SWAP11

				return new SymbolicStack(swapX(11, stack.clone()));

			} else if (op instanceof Swap12Operator) { // SWAP12

				return new SymbolicStack(swapX(12, stack.clone()));

			} else if (op instanceof Swap13Operator) { // SWAP13

				return new SymbolicStack(swapX(13, stack.clone()));

			} else if (op instanceof Swap14Operator) { // SWAP14

				return new SymbolicStack(swapX(14, stack.clone()));

			} else if (op instanceof Swap15Operator) { // SWAP15

				return new SymbolicStack(swapX(15, stack.clone()));

			} else if (op instanceof Swap16Operator) { // SWAP16

				return new SymbolicStack(swapX(16, stack.clone()));

			}
		}

		return top();
	}

	@Override
	public SymbolicStack assume(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack forgetIdentifier(Identifier id) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return Satisfiability.UNKNOWN;
	}

	@Override
	public SymbolicStack pushScope(ScopeToken token) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack popScope(ScopeToken token) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public DomainRepresentation representation() {
		if (isBottom())
			return Lattice.BOTTOM_REPR;
		else if (isTop())
			return Lattice.TOP_REPR;
		return new StringRepresentation(stack);
	}

	@Override
	public SymbolicStack lub(SymbolicStack other) throws SemanticException {
		if (isBottom())
			return other;
		if (other.isBottom())
			return this;

		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack widening(SymbolicStack other) throws SemanticException {
		if (isBottom())
			return other;
		if (other.isBottom())
			return this;

		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public boolean lessOrEqual(SymbolicStack other) throws SemanticException {
		// TODO Auto-generated method stub
		return true;
	}

	@Override
	public SymbolicStack top() {
		return TOP;
	}

	@Override
	public SymbolicStack bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isBottom() {
		return stack == null;
	}

	@Override
	public boolean isTop() {
		return isTop;
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
		SymbolicStack other = (SymbolicStack) obj;
		return Objects.equals(stack, other.stack);
	}

	private BigInteger toBigInteger(SymbolicExpression expression) {
		Constant c = (Constant) expression;
		String hex = (String) c.getValue();
		String hexadecimal = hex.substring(2);
		Integer intVal = Integer.parseInt(hexadecimal, 16);
		return new BigInteger(intVal.toString());
	}

	private ArrayDeque<BigInteger> dupX(int x, ArrayDeque<BigInteger> stack) {
		int i = 0;
		BigInteger target = BigInteger.ZERO;

		for (Iterator<BigInteger> iterator = stack.iterator(); iterator.hasNext() && i < x; ++i) {
			target = (BigInteger) iterator.next();
		}

		stack.push(target);

		return stack;
	}

	private ArrayDeque<BigInteger> swapX(int x, ArrayDeque<BigInteger> stack) {
		BigInteger target1 = stack.pop();
		BigInteger[] popped = new BigInteger[x];

		// Swap target1 with popped[x - 1]

		for (int i = 0; i < x; ++i) {
			popped[i] = stack.pop();
		}

		stack.push(target1);

		for (int i = x - 2; i >= 0; --i) {
			stack.push(popped[i]);
		}

		stack.push(popped[x - 1]);

		return stack;
	}

}