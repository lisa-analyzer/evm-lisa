package it.unipr.analysis;

import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.numeric.Interval;
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
import it.unive.lisa.util.numeric.IntInterval;
import it.unive.lisa.util.numeric.MathNumberConversionException;

import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.Objects;
import java.util.function.Predicate;

/**
 * Semantic domain of the execution stack of the contract.
 */
public class SymbolicStack implements ValueDomain<SymbolicStack> {

	private static final SymbolicStack TOP = new SymbolicStack();
	private static final SymbolicStack BOTTOM = new SymbolicStack(null);

	private final ArrayDeque<Interval> stack;
	private final boolean isTop;

	/**
	 * Constructor of the SymbolicStack class.
	 */
	public SymbolicStack() {
		this(true);
	}

	private SymbolicStack(boolean isTop) {
		this.isTop = isTop;
		this.stack = new ArrayDeque<Interval>();
	}

	private SymbolicStack(ArrayDeque<Interval> stack) {
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
		if (this.isBottom() || this.isTop()) { // BOTTOM or TOP propagation
			return this;
		}

		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof PushOperator) { // PUSH
				ArrayDeque<Interval> result = stack.clone();
				
				Integer valueToPush = this.toInteger(un.getExpression());
				
				result.push(new Interval(valueToPush, valueToPush));
				
				return new SymbolicStack(result);
			} else if (op instanceof AddOperator) { // ADD
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				
				Interval sum = new Interval(opnd1.plus(opnd2));

				result.push(sum);

				return new SymbolicStack(result);
			} else if (op instanceof SubOperator) { // SUB
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				
				Interval sub = new Interval(opnd1.diff(opnd2));

				result.push(sub);

				return new SymbolicStack(result);
			} else if (op instanceof MulOperator) { // MUL
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				
				Interval mul = new Interval(opnd1.mul(opnd2));

				result.push(mul);

				return new SymbolicStack(result);
			} else if ((op instanceof DivOperator) || (op instanceof SdivOperator)) { // DIV,
																						// SDIV
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				Interval div;
				
				if (opnd2.equals(Interval.ZERO.interval)) {
					div = Interval.ZERO;
				} else {
					div = new Interval(opnd1.diff(opnd2));
				}

				result.push(div);

				return new SymbolicStack(result);
			} else if ((op instanceof ModOperator) || (op instanceof SmodOperator)) { // MOD,
																						// SMOD
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				Interval mod;
				
				if (opnd2.equals(Interval.ZERO.interval)) {
					mod = Interval.ZERO;
				} else {
					int low, high;
					
					try {
						low = opnd1.getLow().toInt() % opnd2.getLow().toInt();
						high = opnd1.getHigh().toInt() % opnd2.getHigh().toInt();
					} catch (MathNumberConversionException e) {
						return this.bottom();
					}
					
					mod = new Interval(low, high);
				}

				result.push(mod);

				return new SymbolicStack(result);
			} else if (op instanceof AddmodOperator) { // ADDMOD
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				IntInterval opnd3 = result.pop().interval;
				Interval addmod;
				
				if (opnd3.equals(Interval.ZERO.interval)) {
					addmod = Interval.ZERO;
				} else {
					IntInterval sum = opnd1.plus(opnd2);
					
					int low, high;
					
					try {
						low = sum.getLow().toInt() % opnd3.getLow().toInt();
						high = sum.getHigh().toInt() % opnd3.getHigh().toInt();
					} catch (MathNumberConversionException e) {
						return this.bottom();
					}
					
					addmod = new Interval(low, high);
				}

				result.push(addmod);

				return new SymbolicStack(result);
			} else if (op instanceof MulmodOperator) { // MULMOD
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				IntInterval opnd3 = result.pop().interval;
				Interval mulmod;
				
				if (opnd3.equals(Interval.ZERO.interval)) {
					mulmod = Interval.ZERO;
				} else {
					IntInterval mul = opnd1.mul(opnd2);
					int low, high;
					
					try {
						low = mul.getLow().toInt() % opnd3.getLow().toInt();
						high = mul.getHigh().toInt() % opnd3.getHigh().toInt();
					} catch (MathNumberConversionException e) {
						return this.bottom();
					}
					
					mulmod = new Interval(low, high);
				}

				result.push(mulmod);

				return new SymbolicStack(result);
			} else if (op instanceof ExpOperator) { // EXP
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;
				
				int low, high;
				
				try {
					low = (int)Math.pow(opnd1.getLow().toDouble(), opnd1.getLow().toDouble());
					high = (int)Math.pow(opnd2.getHigh().toDouble(), opnd2.getHigh().toDouble());
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}
				
				Interval exp = new Interval(low, high);

				result.push(exp);

				return new SymbolicStack(result);
			} else if (op instanceof SignextendOperator) { // SIGNEXTEND
				ArrayDeque<Interval> result = stack.clone();
				// offset = result.pop().interval;
				result.pop();
				// toExtend = result.pop().interval;
				// result.push(toExtend);

				return new SymbolicStack(result);
			} else if ((op instanceof LtOperator) || (op instanceof SltOperator)) { // LT,
																					// SLT
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;

				result.push(opnd1.compareTo(opnd2) < 0 ? new Interval(1,1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if ((op instanceof GtOperator) || (op instanceof SgtOperator)) { // GT,
																					// SGT
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;

				result.push(opnd1.compareTo(opnd2) > 0 ? new Interval(1,1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof EqOperator) { // EQ
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;

				result.push(opnd1.compareTo(opnd2) == 0 ? new Interval(1,1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof IszeroOperator) { // ISZERO
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;

				result.push(opnd1.compareTo(Interval.ZERO.interval) == 0 ? new Interval(1,1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof AndOperator) { // AND
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;

				int low, high;
				
				try {
					low = opnd1.getLow().toInt() & opnd2.getLow().toInt();
					high = opnd1.getHigh().toInt() & opnd2.getHigh().toInt();
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}
				
				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof OrOperator) { // OR
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;

				int low, high;
				
				try {
					low = opnd1.getLow().toInt() | opnd2.getLow().toInt();
					high = opnd1.getHigh().toInt() | opnd2.getHigh().toInt();
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}
				
				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof XorOperator) { // XOR
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				IntInterval opnd2 = result.pop().interval;

				int low, high;
				
				try {
					low = opnd1.getLow().toInt() ^ opnd2.getLow().toInt();
					high = opnd1.getHigh().toInt() ^ opnd2.getHigh().toInt();
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}
				
				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof NotOperator) { // NOT
				ArrayDeque<Interval> result = stack.clone();
				IntInterval opnd1 = result.pop().interval;
				
				int low, high;
				
				try {
					low = ~opnd1.getLow().toInt();
					high = ~opnd1.getLow().toInt();
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}
				
				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof ByteOperator) { // BYTE+
				/*
				ArrayDeque<Interval> result = stack.clone();
				IntInterval byteToSelect = result.pop().interval;
				IntInterval target = result.pop().interval;
				
				byte[] lowAsByteArray = target.getLow().toByte();
				byte[] highAsByteArray = 

				if ((byteToSelect.compareTo(Interval.ZERO.interval) < 0)
						|| (byteToSelect.compareTo(BigInteger.valueOf(valueAsByteArray.length)) >= 0)) {
					result.push(BigInteger.ZERO);
				} else {
					byte selectedByte = value.toByteArray()[byteToSelect.intValue()];
					byte[] resultByteArray = BigInteger.ZERO.toByteArray();

					resultByteArray[0] = selectedByte;

					result.push(new BigInteger(resultByteArray));
				}

				return new SymbolicStack(result);
				*/
			} else if (op instanceof PopOperator) { // POP
				ArrayDeque<Interval> result = stack.clone();

				result.pop();

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

			} else if (op instanceof JumpOperator) { // JUMP
				ArrayDeque<Interval> result = stack.clone();
				result.pop(); // Interval destination = result.pop();

				return new SymbolicStack(result);
			} else if (op instanceof JumpiOperator) { // JUMPI
				// Implemented in assume()
				return this;
			}
		}

		return top();
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
			return Lattice.bottomRepresentation();
		else if (isTop())
			return Lattice.topRepresentation();
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

	private Integer toInteger(SymbolicExpression expression) {
		Constant c = (Constant) expression;
		String hex = (String) c.getValue();
		String hexadecimal = hex.substring(2);
		Integer intVal = Integer.parseInt(hexadecimal, 16);
		return intVal;
	}

	private ArrayDeque<Interval> dupX(int x, ArrayDeque<Interval> stack) {
		int i = 0;
		Interval target = Interval.ZERO;

		for (Iterator<Interval> iterator = stack.iterator(); iterator.hasNext() && i < x; ++i) {
			target = (Interval) iterator.next();
		}

		stack.push(target);

		return stack;
	}

	private ArrayDeque<Interval> swapX(int x, ArrayDeque<Interval> stack) {
		Interval target1 = stack.pop();
		Interval[] popped = new Interval[x];

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

	@Override
	public SymbolicStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
			throws SemanticException {
		if (this.isBottom() || this.isTop()) {
			return this;
		}/*
		if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof JumpiOperator) { // JUMPI
				ArrayDeque<BigInteger> result = stack.clone();
				result.pop(); // BigInteger destination = result.pop();
				BigInteger condition = result.pop();

				if (condition != BigInteger.ZERO) {
					return new SymbolicStack(result);
				} else {
					return bottom();
				}
			} else if (op instanceof LogicalNegation) {
				// Get the expression wrapped by LogicalNegation

				SymbolicExpression wrappedExpr = un.getExpression();

				if (wrappedExpr instanceof UnaryExpression) {
					UnaryOperator wrappedOperator = ((UnaryExpression) wrappedExpr).getOperator();

					// Check if LogicalNegation is wrapping a JUMPI
					if (wrappedOperator instanceof JumpiOperator) { // !JUMPI
						ArrayDeque<BigInteger> result = stack.clone();
						result.pop(); // BigInteger destination = result.pop();
						BigInteger condition = result.pop();

						if (condition == BigInteger.ZERO) {
							return new SymbolicStack(result);
						} else {
							return bottom();
						}
					}
				}
			}
		}
*/
		return this;
	}

	@Override
	public SymbolicStack forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

}
