package it.unipr.analysis;

import it.unipr.analysis.operator.*;
import it.unive.lisa.analysis.BaseLattice;
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
import java.math.RoundingMode;
import java.util.Iterator;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.function.Predicate;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class EVMAbsDomain implements ValueDomain<EVMAbsDomain>, BaseLattice<EVMAbsDomain> {
	private static final Logger LOG = LogManager.getLogger(EVMAbsDomain.class);
	
	private static final EVMAbsDomain TOP = new EVMAbsDomain();
	private static final EVMAbsDomain BOTTOM = new EVMAbsDomain(null, null, null);
	private final boolean isTop;
	
	private static final BigDecimal MAX = new BigDecimal(Math.pow(2, 256));
	
	/**
	 * The stack memory.
	 */
	private final Stack stack;

	/**
	 * The volatile memory.
	 */
	private final Memory memory;

	private final Interval mu_i; // TODO Give a better name

	/**
	 * Builds the abstract domain.
	 */
	public EVMAbsDomain() {
		this(true);
	}

	/**
	 * Builds the abstract domain.
	 * 
	 * @param isTop whether the abstract value is top.
	 */
	private EVMAbsDomain(boolean isTop) {
		this.isTop = isTop;
		this.stack = new Stack();
		this.memory = new Memory();
		this.mu_i = new Interval(0, 0);
	}

	/**
	 * Builds a EVMAbsDomain with the given stack, memory and mu_i. The built
	 * EVMAbsDomain is not TOP.
	 * 
	 * @param stack  the stack to be used.
	 * @param memory the memory to be used.
	 * @param mu_i   the mu_i to be used.
	 */
	public EVMAbsDomain(Stack stack, Memory memory, Interval mu_i) {
		this.isTop = false;
		this.stack = stack;
		this.memory = memory;
		this.mu_i = mu_i;
	}

	/**
	 * Returns a cloned copy of the stack.
	 *
	 * @return A cloned copy of the stack or null if the original stack is null.
	 */
	public Stack getStack() {
//		if (stack == null)
//			return null;
		return stack.clone();
	}

	/**
	 * Returns a cloned copy of the memory.
	 *
	 * @return A cloned copy of the memory or null if the original memory is
	 *             null.
	 */
	public Memory getMemory() {
//		if (memory == null)
//			return null;
		return memory.clone();
	}

	/**
	 * Returns a cloned copy of the interval mu_i.
	 *
	 * @return A cloned copy of the interval mu_i or null if the original mu_i
	 *             is null.
	 */
	public Interval getMu_i() {
//		if (mu_i == null)
//			return null;
		return new Interval(mu_i.interval);
	}

	@Override
	public EVMAbsDomain assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@SuppressWarnings("unused")
	@Override
	public EVMAbsDomain smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// Ensure BOTTOM propagation
		if (this.isBottom()) {
//			LOG.warn("smallStepSemantics of " + expression + " at " + ((ProgramCounterLocation) expression.getCodeLocation()).getSourceCodeLine());
			return EVMAbsDomain.BOTTOM;
		}

		try {
//			LOG.info("smallStepSemantics of " + expression + " at " + ((ProgramCounterLocation) expression.getCodeLocation()).getSourceCodeLine());
			if (expression instanceof Constant) {
				return this;
			} else if (expression instanceof UnaryExpression) {
				UnaryExpression un = (UnaryExpression) expression;
				UnaryOperator op = un.getOperator();

				if (op instanceof PushOperator) { // PUSH
					Stack result = stack.clone();

					// Integer valueToPush = this.toInteger(un.getExpression());
					BigDecimal valueToPush = this.toBigDecimal(un.getExpression());

					result.push(new Interval(new MathNumber(valueToPush), new MathNumber(valueToPush)));
					
					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof AddressOperator) { // ADDRESS
					Stack result = stack.clone();

					// At the moment, we do not handle ADDRESS
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof OriginOperator) { // ORIGIN
					Stack result = stack.clone();

					// At the moment, we do not handle ORIGIN
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CallerOperator) { // CALLER
					Stack result = stack.clone();

					// At the moment, we do not handle CALLER
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CallvalueOperator) { // CALLVALUE
					Stack result = stack.clone();

					// At the moment, we do not handle CALLVALUE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CalldatasizeOperator) { // CALLDATASIZE
					Stack result = stack.clone();

					// At the moment, we do not handle CALLDATASIZE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CodesizeOperator) { // CODESIZE
					Stack result = stack.clone();

					// At the moment, we do not handle CODESIZE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof GaspriceOperator) { // GASPRICE
					Stack result = stack.clone();

					// At the moment, we do not handle GASPRICE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ReturndatasizeOperator) { // RETURNDATASIZE
					Stack result = stack.clone();

					// At the moment, we do not handle RETURNDATASIZE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CoinbaseOperator) { // COINBASE
					Stack result = stack.clone();

					// At the moment, we do not handle COINBASE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof TimestampOperator) { // TIMESTAMP
					Stack result = stack.clone();

					// At the moment, we do not handle TIMESTAMP
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof NumberOperator) { // NUMBER
					Stack result = stack.clone();

					// At the moment, we do not handle NUMBER
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof DifficultyOperator) { // DIFFICULTY
					Stack result = stack.clone();

					// At the moment, we do not handle DIFFICULTY
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof GaslimitOperator) { // GASLIMIT
					Stack result = stack.clone();

					// At the moment, we do not handle GASLIMIT
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ChainidOperator) { // CHAINID
					Stack result = stack.clone();

					// At the moment, we do not handle CHAINID
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof SelfbalanceOperator) { // SELFBALANCE
					Stack result = stack.clone();

					// At the moment, we do not handle SELFBALANCE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof PcOperator) { // PC
					Stack result = stack.clone();

					// At the moment, we do not handle PC
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof GasOperator) { // GAS
					Stack result = stack.clone();

					// At the moment, we do not handle GAS
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof JumpOperator) { // JUMP
					if ((Integer) ((Constant) un.getExpression()).getValue() > 0) {
						Stack result = stack.clone();
						result.pop();
						return new EVMAbsDomain(result, memory, mu_i);
					} else
						return this;
				} else if (op instanceof JumpiOperator) { // JUMPI
					return this;
				} else if (op instanceof MsizeOperator) { // MSIZE
					Stack result = stack.clone();

					// At the moment, we do not handle MSIZE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof JumpdestOperator) { // JUMPDEST
					return this;
				}

				// Above, operators that do not perform pop()

				// from here on, top is propagated
				if (isTop())
					return this;

				// Below, operators that perform pop()

				if (op instanceof AddOperator) { // ADD
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// Using Numeric32BitAdd as it implements AdditionOperator
					Interval sum = opnd1.evalBinaryExpression(Numeric32BitAdd.INSTANCE, opnd1, opnd2, pp);

					result.push(sum);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof SubOperator) { // SUB
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Interval sub = opnd1.evalBinaryExpression(Numeric32BitSub.INSTANCE, opnd1, opnd2, pp);

					result.push(sub);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof MulOperator) { // MUL
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Interval mul = opnd1.evalBinaryExpression(Numeric32BitMul.INSTANCE, opnd1, opnd2, pp);

					result.push(mul);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if ((op instanceof DivOperator) || (op instanceof SdivOperator)) { // DIV,
					// SDIV
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();
					Interval div;

					if (opnd2.equals(Interval.ZERO)) {
						div = Interval.ZERO;
					} else {
						div = opnd1.evalBinaryExpression(Numeric32BitDiv.INSTANCE, opnd1, opnd2, pp);
					}

					result.push(div);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if ((op instanceof ModOperator) || (op instanceof SmodOperator)) { // MOD,
					// SMOD
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();
					Interval mod;

					if (opnd2.equals(Interval.ZERO)) {
						mod = Interval.ZERO;
					} else {
						mod = opnd1.evalBinaryExpression(Numeric32BitMod.INSTANCE, opnd1, opnd2, pp);
					}

					result.push(mod);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof AddmodOperator) { // ADDMOD
					Stack result = stack.clone();
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

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof MulmodOperator) { // MULMOD
					Stack result = stack.clone();
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

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ExpOperator) { // EXP
					Stack result = stack.clone();
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
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof SignextendOperator) { // SIGNEXTEND
					Stack result = stack.clone();
					result.pop();
					result.pop();

					// At the moment, we do not handle SIGNEXTEND
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if ((op instanceof LtOperator) || (op instanceof SltOperator)) { // LT,
					// SLT
					Stack result = stack.clone();
					
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();
					
					
					Satisfiability lt = opnd1.satisfiesBinaryExpression(ComparisonLt.INSTANCE, opnd1, opnd2, pp);

					result.push(lt.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);
					
					return new EVMAbsDomain(result, memory, mu_i);
				} else if ((op instanceof GtOperator) || (op instanceof SgtOperator)) { // GT,
					// SGT
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Satisfiability gt = opnd1.satisfiesBinaryExpression(ComparisonGt.INSTANCE, opnd1, opnd2, pp);

					result.push(gt.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof EqOperator) { // EQ
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Satisfiability eq = opnd1.satisfiesBinaryExpression(ComparisonEq.INSTANCE, opnd1, opnd2, pp);

					result.push(eq.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof IszeroOperator) { // ISZERO
					Stack result = stack.clone();
					Interval opnd1 = result.pop();

					Satisfiability iszero = opnd1.satisfiesBinaryExpression(ComparisonEq.INSTANCE, opnd1, Interval.ZERO,
							pp);

					result.push(iszero.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof AndOperator) { // AND
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();
					
					if(opnd1 == Interval.TOP || opnd2 == Interval.TOP) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					// AND is not handled in Interval, so we work with low() and
					// high()
					MathNumber low, high;

					try {
						low = new MathNumber(opnd1.interval.getLow().toLong() & opnd2.interval.getLow().toLong());
						high = new MathNumber(opnd1.interval.getHigh().toLong() & opnd2.interval.getHigh().toLong());
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof OrOperator) { // OR
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					if(opnd1 == Interval.TOP || opnd2 == Interval.TOP) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}
					
					// OR is not handled in Interval, so we work with low() and
					// high()
					MathNumber low, high;

					try {
						low = new MathNumber(opnd1.interval.getLow().toLong() | opnd2.interval.getLow().toLong());
						high = new MathNumber(opnd1.interval.getHigh().toLong() | opnd2.interval.getHigh().toLong());
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof XorOperator) { // XOR
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();
					
					if(opnd1 == Interval.TOP || opnd2 == Interval.TOP) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					// XOR is not handled in Interval, so we work with low() and
					// high()
					MathNumber low, high;

					try {
						low = new MathNumber(opnd1.interval.getLow().toLong() ^ opnd2.interval.getLow().toLong());
						high = new MathNumber(opnd1.interval.getHigh().toLong() ^ opnd2.interval.getHigh().toLong());
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof NotOperator) { // NOT
					Stack result = stack.clone();
					Interval opnd1 = result.pop();

					if(opnd1 == Interval.TOP) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}
					
					// NOT is not handled in Interval, so we work with low() and
					// high()
					MathNumber low, high;
					
					try {						
						if(opnd1.interval.getLow().toLong() >= 0)
							low = new MathNumber(MAX.subtract(new BigDecimal(opnd1.interval.getLow().toLong() + 1)));
						else 
							low = new MathNumber(~opnd1.interval.getLow().toLong());
						
						if(opnd1.interval.getHigh().toLong() >= 0)
							high = new MathNumber(MAX.subtract(new BigDecimal(opnd1.interval.getHigh().toLong() + 1)));
						else 
							high = new MathNumber(~opnd1.interval.getHigh().toLong());
						
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ByteOperator) { // BYTE
					Stack result = stack.clone();
					Interval indexOfByte = result.pop();
					Interval target = result.pop();

					Interval resultInterval = new Interval().bottom(); // Accumulates
					// retrieved
					// bytes

					if (target.equals(Interval.TOP)) {
						result.push(Interval.TOP);
					} else {

						// Loop through all targets (each value of the target
						// interval)
						for (Long value : target.interval) {
							byte[] valueAsByteArray = BigInteger.valueOf(value).toByteArray();

							// Loop through all possible indexes of byte to
							// select
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
					}

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ShlOperator) { // SHL
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// SHL is not handled in Interval, so we work with low() and
					// high()

					if(opnd1 == Interval.TOP || opnd2 == Interval.TOP) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}
					
					try {
						String op2LowString = opnd2.interval.getLow().toString();
						String op2HighString = opnd2.interval.getHigh().toString();
						
						BigInteger op2LowBigInteger = new BigInteger(op2LowString);
						byte[] op2LowBytes = op2LowBigInteger.toByteArray();
						byte[] resultShiftLeftLow = shiftLeft(op2LowBytes, opnd1.interval.getLow().toInt());
						
						BigInteger op2HighBigInteger = new BigInteger(op2HighString);
						byte[] op2HighBytes = op2HighBigInteger.toByteArray();
						byte[] resultShiftLeftHigh = shiftLeft(op2HighBytes, opnd1.interval.getHigh().toInt());
						
						result.push(new Interval(new MathNumber(new BigDecimal(new BigInteger(resultShiftLeftLow))), 
												 new MathNumber(new BigDecimal(new BigInteger(resultShiftLeftHigh)))));
						
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ShrOperator) { // SHR
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// SHR is not handled in Interval, so we work with low() and
					// high()
					
					if(opnd1 == Interval.TOP || opnd2 == Interval.TOP) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					try {
						String op2LowString = opnd2.interval.getLow().toString();
						String op2HighString = opnd2.interval.getHigh().toString();
						
						BigInteger op2LowBigInteger = new BigInteger(op2LowString);
						byte[] op2LowBytes = op2LowBigInteger.toByteArray();
						byte[] resultShiftRightLow = shiftRight(op2LowBytes, opnd1.interval.getLow().toInt());
						
						BigInteger op2HighBigInteger = new BigInteger(op2HighString);
						byte[] op2HighBytes = op2HighBigInteger.toByteArray();
						byte[] resultShiftRightHigh = shiftRight(op2HighBytes, opnd1.interval.getHigh().toInt());
						
						result.push(new Interval(new MathNumber(new BigDecimal(new BigInteger(resultShiftRightLow))), 
												 new MathNumber(new BigDecimal(new BigInteger(resultShiftRightHigh)))));
						
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					return new EVMAbsDomain(result, memory, mu_i);

				} else if (op instanceof SarOperator) { // SAR
					Stack result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// SAR is not handled in Interval, so we work with low() and
					// high()

					if(opnd1 == Interval.TOP || opnd2 == Interval.TOP) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}
					
					try {
						String op2LowString = opnd2.interval.getLow().toString();
						String op2HighString = opnd2.interval.getHigh().toString();
						
						BigInteger op2LowBigInteger = new BigInteger(op2LowString);
						byte[] op2LowBytes = op2LowBigInteger.toByteArray();
						byte[] resultShiftRightLow = shiftArithmeticRight(op2LowBytes, opnd1.interval.getLow().toInt());
						
						BigInteger op2HighBigInteger = new BigInteger(op2HighString);
						byte[] op2HighBytes = op2HighBigInteger.toByteArray();
						byte[] resultShiftRightHigh = shiftArithmeticRight(op2HighBytes, opnd1.interval.getHigh().toInt());
						
						result.push(new Interval(new MathNumber(new BigDecimal(new BigInteger(resultShiftRightLow))), 
												 new MathNumber(new BigDecimal(new BigInteger(resultShiftRightHigh)))));
						
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new EVMAbsDomain(result, memory, mu_i);
					}

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof Sha3Operator) { // SHA3
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle SHA3
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof BalanceOperator) { // BALANCE
					Stack result = stack.clone();
					Interval address = result.pop();

					// At the moment, we do not handle BALANCE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CalldataloadOperator) { // CALLDATALOAD
					Stack result = stack.clone();
					Interval offset = result.pop();

					// At the moment, we do not handle CALLDATALOAD
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CalldatacopyOperator) { // CALLDATACOPY
					Stack result = stack.clone();
					Interval memOffset = result.pop();
					Interval dataOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle CALLDATACOPY

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CodecopyOperator) { // CODECOPY
					Stack result = stack.clone();
					Interval memOffset = result.pop();
					Interval codeOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle CODECOPY

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ExtcodesizeOperator) { // EXTCODESIZE
					Stack result = stack.clone();
					Interval address = result.pop();

					// At the moment, we do not handle EXTCODESIZE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ExtcodecopyOperator) { // EXTCODECOPY
					Stack result = stack.clone();
					Interval address = result.pop();
					Interval memOffset = result.pop();
					Interval codeOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle EXTCODECOPY

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ReturndatacopyOperator) { // RETURNDATACOPY
					Stack result = stack.clone();
					Interval memOffset = result.pop();
					Interval retOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle RETURNDATACOPY

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ExtcodehashOperator) { // EXTCODEHASH
					Stack result = stack.clone();
					Interval address = result.pop();

					// At the moment, we do not handle EXTCODEHASH
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof BlockhashOperator) { // BLOCKHASH
					Stack result = stack.clone();
					Interval blockNumber = result.pop();

					// At the moment, we do not handle BLOCKHASH
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof PopOperator) { // POP
					Stack result = stack.clone();

					result.pop();

					return new EVMAbsDomain(result, memory, mu_i);

				} else if (op instanceof MloadOperator) { // MLOAD
					Stack result = stack.clone();
					Interval new_mu_i = null;

					Interval offset = result.pop();

					if (mu_i.compareTo(new Interval(1, 1)) == -1) {
						// This is an error. We cannot read from memory if there
						// is no active words saved
						// TODO to handle this error
					}
					
					if(memory == null) {
						LOG.warn("[MLOAD] memory == null");
					}

					if (offset.interval.isSingleton()) {
						BigDecimal offsetBigDecimal = offset.interval.getHigh().getNumber();
						BigDecimal thirtyTwo = new BigDecimal(32);
						BigDecimal current_mu_i = offsetBigDecimal.add(thirtyTwo)
								.divide(thirtyTwo)
								.setScale(0, RoundingMode.UP);

						Interval state = memory.getState(offsetBigDecimal);
						
//						System.out.println("[MLOAD] Memory: " + memory);
//						System.out.println("[MLOAD] Offset: " + offsetBigDecimal);
//						System.out.println("[MLOAD] State: " + state);
						
						if(state == Interval.BOTTOM) {
							result.push(Interval.TOP);
							LOG.warn("[MLOAD] state == Interval.BOTTOM");
						}
							
						else
							result.push(state);

						// We create a new Interval singleton with the newly
						// calculated `current_mu_i`
//						Interval intervalCurrent_mu_i = new Interval(current_mu_i.intValueExact(),
//								current_mu_i.intValueExact());
//
//						// Then we compare the 2 mu_i and update the new value
//						if (mu_i.compareTo(intervalCurrent_mu_i) == -1)
//							new_mu_i = intervalCurrent_mu_i;
//						else
							new_mu_i = mu_i;

					} else {
						// TODO to handle else-condition
						result.push(Interval.TOP);
						new_mu_i = mu_i;
					}

					return new EVMAbsDomain(result, memory, new_mu_i);

				} else if (op instanceof MstoreOperator) { // MSTORE
					Stack stackResult = stack.clone();
					Memory memoryResult = null;
					Interval new_mu_i = null;

					Interval offset = stackResult.pop();
					Interval value = stackResult.pop();
					
//					System.out.println("[MSTORE] Offset: " + offset);
					if (offset.interval.isSingleton()) {
						BigDecimal offsetBigDecimal = offset.interval.getHigh().getNumber();
						BigDecimal thirtyTwo = new BigDecimal(32);
						BigDecimal current_mu_i = offsetBigDecimal.add(thirtyTwo)
								.divide(thirtyTwo)
								.setScale(0, RoundingMode.UP); // setScale() =
						// Ceiling
						// function

//						System.out.println("[MSTORE] Memory: " + memory);
//						System.out.println("[MSTORE] Offset: " + offsetBigDecimal);
//						System.out.println("[MSTORE] Value: " + value);
						
						memoryResult = memory.putState(offsetBigDecimal, value);
						

						// We create a new Interval singleton with the newly
						// calculated `current_mu_i`
						Interval intervalCurrent_mu_i = new Interval(current_mu_i.intValueExact(),
								current_mu_i.intValueExact());

						// Then we compare the 2 mu_i and update the new value
						if (mu_i.compareTo(intervalCurrent_mu_i) == -1)
							new_mu_i = intervalCurrent_mu_i;
						else
							new_mu_i = mu_i;

					} else {
						new_mu_i = mu_i;
//						LOG.warn("[MSTORE] !offset.interval.isSingleton() - offset: " + offset);
						memoryResult = memory;
					}

					return new EVMAbsDomain(stackResult, memoryResult, new_mu_i);

				} else if (op instanceof Mstore8Operator) { // MSTORE8
					Stack result = stack.clone();
					Memory memoryResult = null;
					Interval new_mu_i = null;

					Interval offset = result.pop();
					Interval value = result.pop();

					if (offset.interval.isSingleton()) {
						BigDecimal one = new BigDecimal(1);
						BigDecimal thirtyTwo = new BigDecimal(32);

						BigDecimal offsetBigDecimal = offset.interval.getHigh().getNumber();
						BigDecimal current_mu_i = offsetBigDecimal.add(one)
								.divide(thirtyTwo)
								.setScale(0, RoundingMode.UP); // setScale() =
						// Ceiling
						// function

						if (value.interval.isSingleton()) {
							BigDecimal valueBigDecimal = offset.interval.getHigh().getNumber();
							BigDecimal valueByteBigDecimal = valueBigDecimal.remainder(new BigDecimal(256));

							Interval valueInByte = new Interval(valueByteBigDecimal.intValueExact(),
									valueByteBigDecimal.intValueExact());

							memoryResult = memory.putState(offsetBigDecimal, valueInByte);
						} else {
							// TODO to handle else-condition
							// If value is not singleton, how would we handle
							// the `mod 256` operation?
							memoryResult = memory.putState(offsetBigDecimal, Interval.TOP);
						}

						// We create a new Interval singleton with the newly
						// calculated `current_mu_i`
						Interval intervalCurrent_mu_i = new Interval(current_mu_i.intValueExact(),
								current_mu_i.intValueExact());

						if (mu_i.compareTo(intervalCurrent_mu_i) == -1)
							new_mu_i = intervalCurrent_mu_i;
						else
							new_mu_i = mu_i;

					} else {
						// TODO to handle else-condition
						new_mu_i = mu_i;
//						LOG.warn("[MSTORE8] !offset.interval.isSingleton()");
						memoryResult = memory;
					}

					return new EVMAbsDomain(result, memoryResult, new_mu_i);
				} else if (op instanceof SloadOperator) { // SLOAD
					Stack result = stack.clone();
					Interval key = result.pop();

					// At the moment, we do not handle SLOAD
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof SstoreOperator) { // SSTORE
					Stack result = stack.clone();
					Interval key = result.pop();
					Interval value = result.pop();

					// At the moment, we do not handle SSTORE

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof Dup1Operator) { // DUP1

					return new EVMAbsDomain(dupX(1, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup2Operator) { // DUP2

					return new EVMAbsDomain(dupX(2, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup3Operator) { // DUP3

					return new EVMAbsDomain(dupX(3, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup4Operator) { // DUP4

					return new EVMAbsDomain(dupX(4, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup5Operator) { // DUP5

					return new EVMAbsDomain(dupX(5, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup6Operator) { // DUP6

					return new EVMAbsDomain(dupX(6, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup7Operator) { // DUP7

					return new EVMAbsDomain(dupX(7, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup8Operator) { // DUP8

					return new EVMAbsDomain(dupX(8, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup9Operator) { // DUP9

					return new EVMAbsDomain(dupX(9, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup10Operator) { // DUP10

					return new EVMAbsDomain(dupX(10, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup11Operator) { // DUP11

					return new EVMAbsDomain(dupX(11, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup12Operator) { // DUP12

					return new EVMAbsDomain(dupX(12, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup13Operator) { // DUP13

					return new EVMAbsDomain(dupX(13, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup14Operator) { // DUP14

					return new EVMAbsDomain(dupX(14, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup15Operator) { // DUP15

					return new EVMAbsDomain(dupX(15, stack.clone()), memory, mu_i);

				} else if (op instanceof Dup16Operator) { // DUP16

					return new EVMAbsDomain(dupX(16, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap1Operator) { // SWAP1

					return new EVMAbsDomain(swapX(1, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap2Operator) { // SWAP2

					return new EVMAbsDomain(swapX(2, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap3Operator) { // SWAP3

					return new EVMAbsDomain(swapX(3, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap4Operator) { // SWAP4

					return new EVMAbsDomain(swapX(4, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap5Operator) { // SWAP5

					return new EVMAbsDomain(swapX(5, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap6Operator) { // SWAP6

					return new EVMAbsDomain(swapX(6, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap7Operator) { // SWAP7

					return new EVMAbsDomain(swapX(7, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap8Operator) { // SWAP8

					return new EVMAbsDomain(swapX(8, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap9Operator) { // SWAP9

					return new EVMAbsDomain(swapX(9, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap10Operator) { // SWAP10

					return new EVMAbsDomain(swapX(10, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap11Operator) { // SWAP11

					return new EVMAbsDomain(swapX(11, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap12Operator) { // SWAP12

					return new EVMAbsDomain(swapX(12, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap13Operator) { // SWAP13

					return new EVMAbsDomain(swapX(13, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap14Operator) { // SWAP14

					return new EVMAbsDomain(swapX(14, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap15Operator) { // SWAP15

					return new EVMAbsDomain(swapX(15, stack.clone()), memory, mu_i);

				} else if (op instanceof Swap16Operator) { // SWAP16

					return new EVMAbsDomain(swapX(16, stack.clone()), memory, mu_i);

				} else if (op instanceof Log0Operator) { // LOG0
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle LOG0

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof Log1Operator) { // LOG1
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();

					// At the moment, we do not handle LOG1
					result.push(Interval.ZERO);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof Log2Operator) { // LOG2
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();
					Interval topic2 = result.pop();

					// At the moment, we do not handle LOG2
					result.push(Interval.ZERO);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof Log3Operator) { // LOG3
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();
					Interval topic2 = result.pop();
					Interval topic3 = result.pop();

					// At the moment, we do not handle LOG3
					result.push(Interval.ZERO);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof Log4Operator) { // LOG4
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();
					Interval topic2 = result.pop();
					Interval topic3 = result.pop();
					Interval topic4 = result.pop();

					// At the moment, we do not handle LOG4
					result.push(Interval.ZERO);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CreateOperator) { // CREATE
					Stack result = stack.clone();
					Interval value = result.pop();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle CREATE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CallOperator) { // CALL
					Stack result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval value = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle CALL
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof CallcodeOperator) { // CALLCODE
					Stack result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval value = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle CALLCODE
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof ReturnOperator) { // RETURN
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle RETURN

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof DelegatecallOperator) { // DELEGATECALL
					Stack result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle DELEGATECALL
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof Create2Operator) { // CREATE2
					Stack result = stack.clone();
					Interval value = result.pop();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval salt = result.pop();

					// At the moment, we do not handle CREATE2
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof StaticcallOperator) { // STATICCALL
					Stack result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle STATICCALL
					result.push(Interval.TOP);

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof RevertOperator) { // REVERT
					Stack result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle REVERT

					return new EVMAbsDomain(result, memory, mu_i);
				} else if (op instanceof InvalidOperator) { // INVALID
					return this;
				} else if (op instanceof SelfdestructOperator) { // SELFDESTRUCT
					Stack result = stack.clone();
					Interval recipient = result.pop();

					// At the moment, we do not handle SELFDESTRUCT

					return new EVMAbsDomain(result, memory, mu_i);
				}
			}
		} catch (NoSuchElementException e) {
			System.err.println("Operation not performed: " + e);
		}

		return top();
	}

	/**
	 * Duplicates the x-th element from the top of the stack and returns the
	 * modified stack.
	 *
	 * @param x     The position of the element to duplicate from the top of the
	 *                  stack.
	 * @param stack The original stack.
	 * 
	 * @return A new stack with the specified element duplicated at the top.
	 */
	private Stack dupX(int x, Stack stack) {
		int i = 0;
		Interval target = Interval.ZERO;

		Stack result = stack.clone();

		for (Iterator<Interval> iterator = result.iterator(); iterator.hasNext() && i < x; ++i) {
			target = iterator.next();
		}

		result.push(target);

		return result;
	}

	/**
	 * Swaps the top element with the x-th element from the top of the stack and
	 * returns the modified stack.
	 *
	 * @param x     The position of the element to swap with the top of the
	 *                  stack.
	 * @param stack The original stack.
	 * 
	 * @return A new stack with the specified elements swapped.
	 */
	private Stack swapX(int x, Stack stack) {
		Stack result = stack.clone();

		Interval target1 = result.pop();
		Interval[] popped = new Interval[x];

		// Swap target1 with popped[x - 1]

		for (int i = 0; i < x; ++i) {
			popped[i] = result.pop();
		}

		result.push(target1);

		for (int i = x - 2; i >= 0; --i) {
			result.push(popped[i]);
		}

		result.push(popped[x - 1]);

		return result;
	}

	@Override
	public EVMAbsDomain assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
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
					Stack result = stack.clone();
					result.pop(); // Interval destination = result.pop();
					Interval condition = result.pop();

					if (condition.equals(Interval.ZERO)) {
						// Condition is surely false (interval [0,0])
						// Return BOTTOM
						return bottom();
					} else if (condition.equals(new Interval(1, 1))) {
						// Condition is surely true (interval [1,1])
						// Return the result
						return new EVMAbsDomain(result, memory, mu_i);
					} else {
						// Condition could be either true or false
						// Return the result
						return new EVMAbsDomain(result, memory, mu_i);
					}

				} else if (op instanceof LogicalNegation) {
					// Get the expression wrapped by LogicalNegation
					SymbolicExpression wrappedExpr = un.getExpression();

					if (wrappedExpr instanceof UnaryExpression) {
						UnaryOperator wrappedOperator = ((UnaryExpression) wrappedExpr).getOperator();

						// Check if LogicalNegation is wrapping a JUMPI
						if (wrappedOperator instanceof JumpiOperator) { // !JUMPI
							Stack result = stack.clone();
							result.pop(); // Interval destination =
							// result.pop();
							Interval condition = result.pop();

							if (condition.equals(Interval.ZERO)) {
								// Condition is surely false (interval [0,0])
								// Return the result
								return new EVMAbsDomain(result, memory, mu_i);
							} else if (condition.equals(new Interval(1, 1))) {
								// Condition is surely true (interval [1,1])
								// Return BOTTOM
								return bottom();
							} else {
								// Condition could be either true or false
								// Return the result
								return new EVMAbsDomain(result, memory, mu_i);
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

	@Override
	public EVMAbsDomain forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public EVMAbsDomain forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return Satisfiability.UNKNOWN;
	}

	@Override
	public EVMAbsDomain pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public EVMAbsDomain popScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public DomainRepresentation representation() {
		if (isBottom())
			return Lattice.bottomRepresentation();
		else if (isTop())
			return Lattice.topRepresentation();

		// TODO to create a more optimized version
		return new StringRepresentation("{ stack: " + stack + ", memory: " + memory + ", mu_i: " + mu_i + " }");
	}

	@Override
	public EVMAbsDomain top() {
		return TOP;
	}

	@Override
	public EVMAbsDomain bottom() {
		return BOTTOM;
	}

//	@Override
//	public boolean isBottom() {
//		return stack == null &&
//				memory == null &&
//				mu_i == null;
//	}
//
//	@Override
//	public boolean isTop() {
//		return isTop;
//	}

//	@Override
//	public int hashCode() {
//		return Objects.hash(stack, memory, mu_i);
//	}

//	@Override
//	public boolean equals(Object obj) {
//		// EVMAbsDomain check
//		if (this == obj)
//			return true;
//		if (obj == null)
//			return false;
//		if (getClass() != obj.getClass())
//			return false;
//
//		EVMAbsDomain other = (EVMAbsDomain) obj;
//		// isTop check
//		if (this.isTop != other.isTop)
//			return false;
//		// If both are top, there is no need to check the stack
//		if (this.isTop)
//			return true;
//
//		if (stack == null && other.getStack() != null)
//			return false;
//		if (memory == null && other.getMemory() != null)
//			return false;
//		if (mu_i == null && other.getMu_i() != null)
//			return false;
//
//		if (this.isBottom() == false && other.isBottom() == false)
//			return stack.equals(other.getStack()) &&
//					memory.equals(other.getMemory()) &&
//					mu_i.equals(other.getMu_i());
//
//		return this.isBottom() == other.isBottom(); // TODO check if it is
//		// correct
//	}
	

	/**
	 * Helper method to convert a memory word to a BigInteger
	 * 
	 * @param expression the memory word to convert
	 * 
	 * @return the BigInteger corresponding to the memory word
	 */
	private BigDecimal toBigDecimal(SymbolicExpression expression) {
		Constant c = (Constant) expression;
		String hex = (String) c.getValue();
		String hexadecimal = hex.substring(2);
		BigInteger bigIntVal = new BigInteger(hexadecimal, 16);
		BigDecimal bigDecimalVal = new BigDecimal(bigIntVal);
		return bigDecimalVal;
	}

	@Override
	public int hashCode() {
		return Objects.hash(isTop, memory, mu_i, stack);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		EVMAbsDomain other = (EVMAbsDomain) obj;
		return isTop == other.isTop && Objects.equals(memory, other.memory) && Objects.equals(mu_i, other.mu_i)
				&& Objects.equals(stack, other.stack);
	}

	/**
	 * Getter for the interval value at the top of the stack.
	 * 
	 * @return the interval value at the top of the stack.
	 */
	public Interval getTop() {
		return stack.getTop();
	}

	@Override
	public EVMAbsDomain wideningAux(EVMAbsDomain other) throws SemanticException {
		return new EVMAbsDomain(stack.widening(other.getStack()),
				memory.widening(other.getMemory()),
				mu_i.widening(other.getMu_i()));
	}
	
	@Override
	public EVMAbsDomain lubAux(EVMAbsDomain other) throws SemanticException {

		return new EVMAbsDomain(stack.lub(other.getStack()),
				memory.lub(other.getMemory()),
				mu_i.lub(other.getMu_i()));
	}

	@Override
	public boolean lessOrEqualAux(EVMAbsDomain other) throws SemanticException {
		return stack.lessOrEqual(other.getStack()) &&
				memory.lessOrEqual(other.getMemory()) &&
				mu_i.lessOrEqual(other.getMu_i());
	}
	
	/**
	 * Shifts the elements of a byte array to the right by a specified number of bits.
	 *
	 * @param byteArray      The byte array to be shifted.
	 * @param shiftBitCount  The number of bits by which the array elements should be shifted to the right.
	 * @return               The byte array after the right shift operation.
	 * 
	 * <p>This method performs a bitwise right shift on the input byte array, where each element is treated as
	 * a single byte. The shift operation is performed in-place, and the original array is modified.</p>
	 *
	 * <p>If the {@code shiftBitCount} is zero, the array remains unchanged.</p>
	 *
	 * <p>The method uses a circular shift approach, with consideration for byte boundaries and a carry mechanism.</p>
	 *
	 * @throws IllegalArgumentException If the {@code byteArray} is {@code null}.
	 */
	public static byte[] shiftRight(byte[] byteArray, int shiftBitCount) {
	    final int shiftMod = shiftBitCount % 8;
	    final byte carryMask = (byte) (0xFF << (8 - shiftMod));
	    final int offsetBytes = (shiftBitCount / 8);

	    int sourceIndex;
	    for (int i = byteArray.length - 1; i >= 0; i--) {
	        sourceIndex = i - offsetBytes;
	        if (sourceIndex < 0) {
	            byteArray[i] = 0;
	        } else {
	            byte src = byteArray[sourceIndex];
	            byte dst = (byte) ((0xff & src) >>> shiftMod);
	            if (sourceIndex - 1 >= 0) {
	                dst |= byteArray[(sourceIndex - 1)] << (8 - shiftMod) & carryMask;
	            }
	            byteArray[i] = dst;
	        }
	    }
	    return byteArray;
	}
	
	/**
	 * Shifts the given byte array to the left by the specified number of bits.
	 *
	 * @param byteArray The byte array to be left-shifted.
	 * @param shiftBitCount The number of bits by which to shift the byte array to the left.
	 * @return The resulting byte array after left-shifting by the specified bit count.
	 * 
	 * <p>This method performs a left shift on the provided byte array, where each byte is shifted to the left
	 * by the given number of bits. The shift operation is performed in a bitwise manner, and the bits shifted
	 * beyond the byte boundary are wrapped around to the opposite end. The shift is done in place, and the
	 * modified byte array is returned as the result.</p>
	 * 
	 * <p>The {@code shiftBitCount} parameter determines the number of bits to shift. </p>
	 * 
	 * @throws IllegalArgumentException If the input {@code byteArray} is {@code null}.
	 */
	public static byte[] shiftLeft(byte[] byteArray, int shiftBitCount) {
	    final int shiftMod = shiftBitCount % 8;
	    final byte carryMask = (byte) ((1 << shiftMod) - 1);
	    final int offsetBytes = (shiftBitCount / 8);

	    int start;
	    
	    if(byteArray.length > 32)
	    	start = 1;
	    else
	    	start = 0;
	    
	    int sourceIndex;
	    for (int i = start; i < byteArray.length; i++) {
	        sourceIndex = i + offsetBytes;
	        if (sourceIndex >= byteArray.length) {
	            byteArray[i] = 0;
	        } else {
	            byte src = byteArray[sourceIndex];
	            byte dst = (byte) (src << shiftMod);
	            if (sourceIndex + 1 < byteArray.length) {
	                dst |= byteArray[sourceIndex + 1] >>> (8 - shiftMod) & carryMask;
	            }
	            byteArray[i] = dst;
	        }
	    }
	    return byteArray;
	}
	
	/**
	 * Shifts the bits of the given byte array towards the least significant bit (SAR - Shift Arithmetic Right).
	 * The bits moved before the first one are discarded, and the new bits are set to 0 if the previous most
	 * significant bit was 0; otherwise, the new bits are set to 1.
	 *
	 * @param byteArray The byte array to be right-shifted.
	 * @param shiftBitCount The number of bits by which to shift the byte array to the right.
	 * @return The resulting byte array after right-shifting by the specified bit count.
	 *
	 * <p>This method performs a right shift on the provided byte array (SAR operation), where each byte is
	 * shifted to the right by the given number of bits. The shift operation is performed in a bitwise manner,
	 * and the bits shifted beyond the byte boundary are discarded. The new bits introduced during the shift
	 * are set based on the value of the previous most significant bit (0 or 1).</p>
	 *
	 * <p>The {@code shiftBitCount} parameter determines the number of bits to shift.</p>
	 *
	 * @throws IllegalArgumentException If the input {@code byteArray} is {@code null}.
	 */
	public static byte[] shiftArithmeticRight(byte[] byteArray, int shiftBitCount) {
	    final int shiftMod = shiftBitCount % 8;
	    final byte carryMask = (byte) (0xFF << (8 - shiftMod));
	    final int offsetBytes = (shiftBitCount / 8);

	    int sourceIndex;
	    int start;
	    
	    if(byteArray.length > 32)
	    	start = 1;
	    else
	    	start = 0;
	    for (int i = start; i < byteArray.length; i++) {
	        sourceIndex = i + offsetBytes;
	        if (sourceIndex >= byteArray.length) {
	            byteArray[i] = (byte) (byteArray[i] < 0 ? 0xFF : 0);
	        } else {
	            byte src = byteArray[sourceIndex];
	            byte dst = (byte) (src >>> shiftMod);
	            if (sourceIndex + 1 < byteArray.length) {
	                dst |= byteArray[sourceIndex + 1] << (8 - shiftMod) & carryMask;
	            }
	            byteArray[i] = dst;
	        }
	    }
	    return byteArray;
	}
	
	/**
	 * Prints the hexadecimal representation of a byte array to the standard output.
	 *
	 * @param bytes The byte array to be printed in hexadecimal format.
	 * 
	 * <p>This method iterates through each byte in the array and prints its hexadecimal representation.
	 * Each byte is formatted as a two-digit uppercase hexadecimal value, separated by a space.
	 * After printing all bytes, a newline character is appended to the output.</p>
	 *
	 * @throws IllegalArgumentException If the input {@code bytes} is {@code null}.
	 */
	public static void printByte(byte[] bytes) {
        for (byte b : bytes) {
            System.out.printf("%02X ", b);
        }
        System.out.println(); 
    }

}