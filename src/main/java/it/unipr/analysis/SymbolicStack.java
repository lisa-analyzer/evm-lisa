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
import it.unive.lisa.symbolic.value.operator.binary.ComparisonEq;
import it.unive.lisa.symbolic.value.operator.binary.ComparisonGt;
import it.unive.lisa.symbolic.value.operator.binary.ComparisonLt;
import it.unive.lisa.symbolic.value.operator.binary.Numeric32BitAdd;
import it.unive.lisa.symbolic.value.operator.binary.Numeric32BitDiv;
import it.unive.lisa.symbolic.value.operator.binary.Numeric32BitMod;
import it.unive.lisa.symbolic.value.operator.binary.Numeric32BitMul;
import it.unive.lisa.symbolic.value.operator.binary.Numeric32BitSub;
import it.unive.lisa.symbolic.value.operator.unary.LogicalNegation;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.util.numeric.MathNumber;
import it.unive.lisa.util.numeric.MathNumberConversionException;
import java.math.BigDecimal;
import java.math.BigInteger;
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
		if (this.isBottom()) { // BOTTOM propagation
			return SymbolicStack.BOTTOM;
		}

		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof PushOperator) { // PUSH
				ArrayDeque<Interval> result = stack.clone();

				// Integer valueToPush = this.toInteger(un.getExpression());
				BigDecimal valueToPush = this.toBigDecimal(un.getExpression());

				result.push(new Interval(new MathNumber(valueToPush), new MathNumber(valueToPush)));

				return new SymbolicStack(result);
			} else if (op instanceof AddOperator) { // ADD
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				// Using Numeric32BitAdd as it implements AdditionOperator
				Interval sum = opnd1.evalBinaryExpression(Numeric32BitAdd.INSTANCE, opnd1, opnd2, pp);

				result.push(sum);

				return new SymbolicStack(result);
			} else if (op instanceof SubOperator) { // SUB
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				Interval sub = opnd1.evalBinaryExpression(Numeric32BitSub.INSTANCE, opnd1, opnd2, pp);

				result.push(sub);

				return new SymbolicStack(result);
			} else if (op instanceof MulOperator) { // MUL
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				Interval mul = opnd1.evalBinaryExpression(Numeric32BitMul.INSTANCE, opnd1, opnd2, pp);

				result.push(mul);

				return new SymbolicStack(result);
			} else if ((op instanceof DivOperator) || (op instanceof SdivOperator)) { // DIV,
																						// SDIV
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();
				Interval div;

				if (opnd2.equals(Interval.ZERO)) {
					div = Interval.ZERO;
				} else {
					div = opnd1.evalBinaryExpression(Numeric32BitDiv.INSTANCE, opnd1, opnd2, pp);
				}

				System.out.println(opnd1);
				System.out.println(opnd2);
				System.out.println(div);

				result.push(div);

				return new SymbolicStack(result);
			} else if ((op instanceof ModOperator) || (op instanceof SmodOperator)) { // MOD,
																						// SMOD
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();
				Interval mod;

				if (opnd2.equals(Interval.ZERO)) {
					mod = Interval.ZERO;
				} else {
					mod = opnd1.evalBinaryExpression(Numeric32BitMod.INSTANCE, opnd1, opnd2, pp);
				}

				result.push(mod);

				return new SymbolicStack(result);
			} else if (op instanceof AddmodOperator) { // ADDMOD
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();
				Interval opnd3 = result.pop();
				Interval addmod;

				if (opnd3.equals(Interval.ZERO)) {
					addmod = Interval.ZERO;
				} else {
					Interval sum = opnd1.evalBinaryExpression(Numeric32BitAdd.INSTANCE, opnd1, opnd2, pp);
					addmod = sum.evalBinaryExpression(Numeric32BitMod.INSTANCE, sum, opnd3, pp);
				}

				result.push(addmod);

				return new SymbolicStack(result);
			} else if (op instanceof MulmodOperator) { // MULMOD
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();
				Interval opnd3 = result.pop();
				Interval mulmod;

				if (opnd3.equals(Interval.ZERO)) {
					mulmod = Interval.ZERO;
				} else {
					Interval mul = opnd1.evalBinaryExpression(Numeric32BitMul.INSTANCE, opnd1, opnd2, pp);
					mulmod = mul.evalBinaryExpression(Numeric32BitMod.INSTANCE, mul, opnd3, pp);
				}

				result.push(mulmod);

				return new SymbolicStack(result);
			} else if (op instanceof ExpOperator) { // EXP
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				// EXP is not handled in Interval, so we work with low() and
				// high()
				MathNumber low, high;
				Interval exp = null;
				try {
					low = new MathNumber(
							Math.pow(opnd1.interval.getLow().toDouble(), opnd2.interval.getLow().toDouble()));
					high = new MathNumber(
							Math.pow(opnd1.interval.getLow().toDouble(), opnd2.interval.getLow().toDouble()));

					exp = new Interval(low, high);

					result.push(exp);
				} catch (MathNumberConversionException e) {
					e.printStackTrace();
				}

				System.out.println(opnd1);
				System.out.println(opnd2);
				System.out.println(exp);

				return new SymbolicStack(result);
			} else if (op instanceof SignextendOperator) { // SIGNEXTEND
				ArrayDeque<Interval> result = stack.clone();
				// offset = result.pop();
				result.pop();
				// toExtend = result.pop();
				// result.push(toExtend);

				return new SymbolicStack(result);
			} else if ((op instanceof LtOperator) || (op instanceof SltOperator)) { // LT,
																					// SLT
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				Satisfiability lt = opnd1.satisfiesBinaryExpression(ComparisonLt.INSTANCE, opnd1, opnd2, pp);

				result.push(lt.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if ((op instanceof GtOperator) || (op instanceof SgtOperator)) { // GT,
																					// SGT
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				Satisfiability gt = opnd1.satisfiesBinaryExpression(ComparisonGt.INSTANCE, opnd1, opnd2, pp);

				result.push(gt.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof EqOperator) { // EQ
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				Satisfiability eq = opnd1.satisfiesBinaryExpression(ComparisonEq.INSTANCE, opnd1, opnd2, pp);

				result.push(eq.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof IszeroOperator) { // ISZERO
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();

				Satisfiability iszero = opnd1.satisfiesBinaryExpression(ComparisonEq.INSTANCE, opnd1, Interval.ZERO,
						pp);

				result.push(iszero.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

				return new SymbolicStack(result);
			} else if (op instanceof AndOperator) { // AND
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				// AND is not handled in Interval, so we work with low() and
				// high()
				MathNumber low, high;

				try {
					low = new MathNumber(opnd1.interval.getLow().toByte() & opnd2.interval.getLow().toByte());
					high = new MathNumber(opnd1.interval.getHigh().toByte() & opnd2.interval.getHigh().toByte());
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}

				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof OrOperator) { // OR
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				// OR is not handled in Interval, so we work with low() and
				// high()
				MathNumber low, high;

				try {
					low = new MathNumber(opnd1.interval.getLow().toByte() | opnd2.interval.getLow().toByte());
					high = new MathNumber(opnd1.interval.getHigh().toByte() | opnd2.interval.getHigh().toByte());
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}

				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof XorOperator) { // XOR
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();
				Interval opnd2 = result.pop();

				// XOR is not handled in Interval, so we work with low() and
				// high()
				MathNumber low, high;

				try {
					low = new MathNumber(opnd1.interval.getLow().toByte() ^ opnd2.interval.getLow().toByte());
					high = new MathNumber(opnd1.interval.getHigh().toByte() ^ opnd2.interval.getHigh().toByte());
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}

				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof NotOperator) { // NOT
				ArrayDeque<Interval> result = stack.clone();
				Interval opnd1 = result.pop();

				// NOT is not handled in Interval, so we work with low() and
				// high()
				MathNumber low, high;

				try {
					low = new MathNumber(~opnd1.interval.getLow().toByte());
					high = new MathNumber(~opnd1.interval.getHigh().toByte());
				} catch (MathNumberConversionException e) {
					return this.bottom();
				}

				result.push(new Interval(low, high));

				return new SymbolicStack(result);
			} else if (op instanceof ByteOperator) { // BYTE
				ArrayDeque<Interval> result = stack.clone();
				Interval indexOfByte = result.pop();
				Interval target = result.pop();

				Interval resultInterval = new Interval().bottom(); // Accumulates
																	// retrieved
																	// bytes

				// Loop through all targets (each value of the target interval)
				for (Long value : target.interval) {
					byte[] valueAsByteArray = BigInteger.valueOf(value).toByteArray();

					// Loop through all possible indexes of byte to select
					for (Long index : indexOfByte.interval) {
						int intIndex = index.intValue();

						// Check if index is valid (>= 0 and <
						// valueAsByteArray.length)
						if (intIndex <= 0 || intIndex >= valueAsByteArray.length) {
							resultInterval.lub(Interval.ZERO);
						} else {
							int selectedByteAsInt = valueAsByteArray[intIndex];
							resultInterval.lub(new Interval(selectedByteAsInt, selectedByteAsInt));
						}
					}
				}

				result.push(resultInterval);

				return new SymbolicStack(result);
			} else if (op instanceof JumpOperator) { // JUMP
				ArrayDeque<Interval> result = stack.clone();
				result.pop(); // Interval destination = result.pop();

				return new SymbolicStack(result);
			} else if (op instanceof JumpiOperator) { // JUMPI
				// Implemented in assume()
				return this;
			}

			// from here on, top is propagated
			if (isTop())
				return this;

			if (op instanceof PopOperator) { // POP
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

			}
		}

		return top();
	}

	/*
	 * Duplicates the x-th element from the top of the stack
	 */
	private ArrayDeque<Interval> dupX(int x, ArrayDeque<Interval> stack) {
		int i = 0;
		Interval target = Interval.ZERO;

		for (Iterator<Interval> iterator = stack.iterator(); iterator.hasNext() && i < x; ++i) {
			target = (Interval) iterator.next();
		}

		stack.push(target);

		return stack;
	}

	/*
	 * Swaps the top element with the x-th element from the top of the stack
	 */
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
		if (other == null || other.isBottom() || this.isTop()) {
			return this;
		}

		if (this.isBottom() || this.isTop()) {
			return other;
		}

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

		return new SymbolicStack(result);
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
		if (other == null) {
			return false;
		}

		// If both stacks are TOP or BOTTOM, lessOrEqual is true
		if ((this.isBottom() && other.isBottom()) || (this.isTop() && other.isTop())) {
			return true;
		}

		if (this.isTop() && other.isBottom()) {
			return false; // TOP <= BOTTOM is false
		}

		if (this.isBottom() && other.isTop()) {
			return true; // BOTTOM <= TOP is true
		}

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

	private BigDecimal toBigDecimal(SymbolicExpression expression) {
		Constant c = (Constant) expression;
		String hex = (String) c.getValue();
		String hexadecimal = hex.substring(2);
		BigInteger bigIntVal = new BigInteger(hexadecimal, 16);
		BigDecimal bigDecimalVal = new BigDecimal(bigIntVal);
		return bigDecimalVal;
	}

	@Override
	public SymbolicStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
			throws SemanticException {
		if (this.isBottom() || this.isTop()) { // BOTTOM and TOP propagation
			return this;
		}

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
					return new SymbolicStack(result);
				} else {
					// Condition could be either true or false
					// Return the result
					return new SymbolicStack(result);
				}

			} else if (op instanceof LogicalNegation) {
				// Get the expression wrapped by LogicalNegation
				SymbolicExpression wrappedExpr = un.getExpression();

				if (wrappedExpr instanceof UnaryExpression) {
					UnaryOperator wrappedOperator = ((UnaryExpression) wrappedExpr).getOperator();

					// Check if LogicalNegation is wrapping a JUMPI
					if (wrappedOperator instanceof JumpiOperator) { // !JUMPI
						ArrayDeque<Interval> result = stack.clone();
						result.pop(); // Interval destination = result.pop();
						Interval condition = result.pop();

						if (condition.equals(Interval.ZERO)) {
							// Condition is surely false (interval [0,0])
							// Return the result
							return new SymbolicStack(result);
						} else if (condition.equals(new Interval(1, 1))) {
							// Condition is surely true (interval [1,1])
							// Return BOTTOM
							return bottom();
						} else {
							// Condition could be either true or false
							// Return the result
							return new SymbolicStack(result);
						}
					}
				}
			}
		}

		return this;
	}

	@Override
	public SymbolicStack forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

}
