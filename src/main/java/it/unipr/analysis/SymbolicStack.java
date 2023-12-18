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
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.function.Predicate;

/**
 * Class representing the symbolic stack abstract domain.
 */
public class SymbolicStack implements ValueDomain<SymbolicStack> {

	private static final SymbolicStack TOP = new SymbolicStack();
	private static final SymbolicStack BOTTOM = new SymbolicStack(null);

	private final ArrayDeque<Interval> stack;
	private Memory memory;
	private BigDecimal mu_i; // TODO Give a better name
	private final boolean isTop;

	/**
	 * Default constructor, builds a TOP symbolic stack.
	 */
	public SymbolicStack() {
		this(true);
	}

	/**
	 * Builds a symbolic stack with the given stack.
	 * The built symbolic stack is not TOP.
	 * 
	 * @param stack the stack to be used.
	 */
	public SymbolicStack(ArrayDeque<Interval> stack) {
		this.stack = stack;
		this.isTop = false;
		this.memory = new Memory();
		this.mu_i = new BigDecimal(0);
	}
	
	/**
	 * Builds a symbolic stack with the given stack, memory and mu_i.
	 * The built symbolic stack is not TOP.
	 * 
	 * @param stack the stack to be used.
	 * @param memory the memory to be used.
	 * @param mu_i the mu_i to be used.
	 */
	public SymbolicStack(ArrayDeque<Interval> stack, Memory memory, BigDecimal mu_i) {
		this.stack = stack;
		this.isTop = false;
		this.memory = memory;
		this.mu_i = mu_i;
	}

	/**
	 * Private "helper" constructor.
	 * Builds an empty symbolic stack and sets the isTop flag.
	 * 
	 * @param isTop true if the stack is TOP, false if it is BOTTOM.
	 */
	private SymbolicStack(boolean isTop) {
		this.isTop = isTop;
		this.stack = new ArrayDeque<Interval>();
		this.memory = new Memory();
		this.mu_i = new BigDecimal(0);
	}

	/**
	 * {@inheritDoc}
	 * 
	 * TODO: implement.
	 */
	@Override
	public SymbolicStack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	/**
	 * {@inheritDoc} Given an expression, modifies the symbolic stack
	 * accordingly and returns the modified stack.
	 *
	 * @return the modified symbolic stack
	 * @throws SemanticException if something goes wrong during the evaluation.
	 */
	@Override
	public SymbolicStack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// Ensure BOTTOM propagation
		if (this.isBottom()) {
			return SymbolicStack.BOTTOM;
		}

		try {
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

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof AddressOperator) { // ADDRESS
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle ADDRESS
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof OriginOperator) { // ORIGIN
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle ORIGIN
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CallerOperator) { // CALLER
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle CALLER
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CallvalueOperator) { // CALLVALUE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle CALLVALUE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CalldatasizeOperator) { // CALLDATASIZE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle CALLDATASIZE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CodesizeOperator) { // CODESIZE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle CODESIZE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof GaspriceOperator) { // GASPRICE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle GASPRICE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ReturndatasizeOperator) { // RETURNDATASIZE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle RETURNDATASIZE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CoinbaseOperator) { // COINBASE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle COINBASE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof TimestampOperator) { // TIMESTAMP
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle TIMESTAMP
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof NumberOperator) { // NUMBER
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle NUMBER
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof DifficultyOperator) { // DIFFICULTY
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle DIFFICULTY
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof GaslimitOperator) { // GASLIMIT
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle GASLIMIT
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ChainidOperator) { // CHAINID
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle CHAINID
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof SelfbalanceOperator) { // SELFBALANCE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle SELFBALANCE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof PcOperator) { // PC
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle PC
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof GasOperator) { // GAS
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle GAS
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof JumpOperator) { // JUMP
					if ((Integer) ((Constant) un.getExpression()).getValue() > 0) {
						ArrayDeque<Interval> result = stack.clone();
						result.pop();
						return new SymbolicStack(result, memory, mu_i);
					} else
						return this;
				} else if (op instanceof JumpiOperator) { // JUMPI
					return this;
				} else if (op instanceof MsizeOperator) { // MSIZE
					ArrayDeque<Interval> result = stack.clone();

					// At the moment, we do not handle MSIZE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof JumpdestOperator) { // JUMPDEST
					return this;
				}

				// Above, operators that do not perform pop()

				// from here on, top is propagated
				if (isTop())
					return this;

				// Below, operators that perform pop()

				if (op instanceof AddOperator) { // ADD
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// Using Numeric32BitAdd as it implements AdditionOperator
					Interval sum = opnd1.evalBinaryExpression(Numeric32BitAdd.INSTANCE, opnd1, opnd2, pp);

					result.push(sum);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof SubOperator) { // SUB
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Interval sub = opnd1.evalBinaryExpression(Numeric32BitSub.INSTANCE, opnd1, opnd2, pp);

					result.push(sub);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof MulOperator) { // MUL
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Interval mul = opnd1.evalBinaryExpression(Numeric32BitMul.INSTANCE, opnd1, opnd2, pp);

					result.push(mul);

					return new SymbolicStack(result, memory, mu_i);
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

					result.push(div);

					return new SymbolicStack(result, memory, mu_i);
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

					return new SymbolicStack(result, memory, mu_i);
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

					return new SymbolicStack(result, memory, mu_i);
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

					return new SymbolicStack(result, memory, mu_i);
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
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof SignextendOperator) { // SIGNEXTEND
					ArrayDeque<Interval> result = stack.clone();
					result.pop();
					result.pop();

					// At the moment, we do not handle SIGNEXTEND
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if ((op instanceof LtOperator) || (op instanceof SltOperator)) { // LT,
																						// SLT
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Satisfiability lt = opnd1.satisfiesBinaryExpression(ComparisonLt.INSTANCE, opnd1, opnd2, pp);

					result.push(lt.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
				} else if ((op instanceof GtOperator) || (op instanceof SgtOperator)) { // GT,
																						// SGT
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Satisfiability gt = opnd1.satisfiesBinaryExpression(ComparisonGt.INSTANCE, opnd1, opnd2, pp);

					result.push(gt.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof EqOperator) { // EQ
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					Satisfiability eq = opnd1.satisfiesBinaryExpression(ComparisonEq.INSTANCE, opnd1, opnd2, pp);

					result.push(eq.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof IszeroOperator) { // ISZERO
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();

					Satisfiability iszero = opnd1.satisfiesBinaryExpression(ComparisonEq.INSTANCE, opnd1, Interval.ZERO,
							pp);

					result.push(iszero.equals(Satisfiability.SATISFIED) ? new Interval(1, 1) : Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
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
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new SymbolicStack(result, memory, mu_i);
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
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new SymbolicStack(result, memory, mu_i);
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
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new SymbolicStack(result, memory, mu_i);
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
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ByteOperator) { // BYTE
					ArrayDeque<Interval> result = stack.clone();
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

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ShlOperator) { // SHL
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// SHL is not handled in Interval, so we work with low() and
					// high()

					MathNumber low, high;

					try {
						low = new MathNumber(opnd1.interval.getLow().toByte() << opnd2.interval.getLow().toByte());
						high = new MathNumber(opnd1.interval.getHigh().toByte() << opnd2.interval.getHigh().toByte());
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ShrOperator) { // SHR
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// SHR is not handled in Interval, so we work with low() and
					// high()

					MathNumber low, high;

					try {
						low = new MathNumber(opnd1.interval.getLow().toByte() >> opnd2.interval.getLow().toByte());
						high = new MathNumber(opnd1.interval.getHigh().toByte() >> opnd2.interval.getHigh().toByte());
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new SymbolicStack(result, memory, mu_i);

				} else if (op instanceof SarOperator) { // SAR
					ArrayDeque<Interval> result = stack.clone();
					Interval opnd1 = result.pop();
					Interval opnd2 = result.pop();

					// SAR is not handled in Interval, so we work with low() and
					// high()

					MathNumber low, high;

					try {
						low = new MathNumber(opnd1.interval.getLow().toByte() >> opnd2.interval.getLow().toByte());
						high = new MathNumber(opnd1.interval.getHigh().toByte() >> opnd2.interval.getHigh().toByte());
					} catch (MathNumberConversionException e) {
						result.push(Interval.TOP);
						return new SymbolicStack(result, memory, mu_i);
					}

					result.push(new Interval(low, high));

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof Sha3Operator) { // SHA3
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle SHA3
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof BalanceOperator) { // BALANCE
					ArrayDeque<Interval> result = stack.clone();
					Interval address = result.pop();

					// At the moment, we do not handle BALANCE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CalldataloadOperator) { // CALLDATALOAD
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();

					// At the moment, we do not handle CALLDATALOAD
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CalldatacopyOperator) { // CALLDATACOPY
					ArrayDeque<Interval> result = stack.clone();
					Interval memOffset = result.pop();
					Interval dataOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle CALLDATACOPY

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CodecopyOperator) { // CODECOPY
					ArrayDeque<Interval> result = stack.clone();
					Interval memOffset = result.pop();
					Interval codeOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle CODECOPY

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ExtcodesizeOperator) { // EXTCODESIZE
					ArrayDeque<Interval> result = stack.clone();
					Interval address = result.pop();

					// At the moment, we do not handle EXTCODESIZE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ExtcodecopyOperator) { // EXTCODECOPY
					ArrayDeque<Interval> result = stack.clone();
					Interval address = result.pop();
					Interval memOffset = result.pop();
					Interval codeOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle EXTCODECOPY

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ReturndatacopyOperator) { // RETURNDATACOPY
					ArrayDeque<Interval> result = stack.clone();
					Interval memOffset = result.pop();
					Interval retOffset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle RETURNDATACOPY

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ExtcodehashOperator) { // EXTCODEHASH
					ArrayDeque<Interval> result = stack.clone();
					Interval address = result.pop();

					// At the moment, we do not handle EXTCODEHASH
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof BlockhashOperator) { // BLOCKHASH
					ArrayDeque<Interval> result = stack.clone();
					Interval blockNumber = result.pop();

					// At the moment, we do not handle BLOCKHASH
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof PopOperator) { // POP
					ArrayDeque<Interval> result = stack.clone();

					result.pop();

					return new SymbolicStack(result, memory, mu_i);
					
				} else if (op instanceof MloadOperator) { // MLOAD
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					
					System.out.println("\t[MLOAD] Memory (before exec) = " + memory);
					System.out.println("\t[MLOAD] mu_i (before exec) = " + mu_i);
					
					if(mu_i.intValueExact() < new BigDecimal(1).intValueExact()) {
						// This is an error. We cannot read from memory if there is no active words saved
						// TODO to handle this error
					}
						
					System.out.println("\t[MLOAD] offset.interval.isSingleton() = " + offset.interval.isSingleton());
					
					if(offset.interval.isSingleton()) {
						BigDecimal offsetBigDecimal = offset.interval.getHigh().getNumber();
						BigDecimal thirtyTwo = new BigDecimal(32);
						
						System.out.println("\t[MLOAD] offsetBigDecimal (before exec) = " + offsetBigDecimal);
						
						Interval state = memory.getState(offsetBigDecimal);
						
						System.out.println("\t[MLOAD] State = " + state);
						
						result.push(state);
						
						mu_i = mu_i.max(offsetBigDecimal.add(thirtyTwo).divide(thirtyTwo));
					
					} else {
						// TODO to handle else-condition
						result.push(Interval.TOP);
					}
					
					System.out.println("\t[MLOAD] Memory (after exec) = " + memory);
					System.out.println("\t[MLOAD] mu_i (after exec) = " + mu_i);
					
					return new SymbolicStack(result, memory, mu_i);
					
				} else if (op instanceof MstoreOperator) { // MSTORE
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval value = result.pop();
					
					System.out.println("\t[MSTORE] Memory (before exec) = " + memory);
					System.out.println("\t[MSTORE] mu_i (before exec) = " + mu_i);
					
					if(offset.interval.isSingleton()) {
						BigDecimal offsetBigDecimal = offset.interval.getHigh().getNumber();
						BigDecimal thirtyTwo = new BigDecimal(32);
						
						memory = memory.putState(offsetBigDecimal, value);
						
						mu_i = mu_i.max(offsetBigDecimal.add(thirtyTwo).divide(thirtyTwo));
	
					} else {
						// TODO to handle else-condition
					}
					
					System.out.println("\t[MSTORE] Memory (after exec) = " + memory);
					System.out.println("\t[MSTORE] mu_i (after exec) = " + mu_i);
					
					return new SymbolicStack(result, memory, mu_i);
					
				} else if (op instanceof Mstore8Operator) { // MSTORE8
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval value = result.pop();

					// At the moment, we do not handle MSTORE8

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof SloadOperator) { // SLOAD
					ArrayDeque<Interval> result = stack.clone();
					Interval key = result.pop();

					// At the moment, we do not handle SLOAD
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof SstoreOperator) { // SSTORE
					ArrayDeque<Interval> result = stack.clone();
					Interval key = result.pop();
					Interval value = result.pop();

					// At the moment, we do not handle SSTORE

					return new SymbolicStack(result, memory, mu_i);
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

				} else if (op instanceof Log0Operator) { // LOG0
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle LOG0

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof Log1Operator) { // LOG1
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();

					// At the moment, we do not handle LOG1
					result.push(Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof Log2Operator) { // LOG2
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();
					Interval topic2 = result.pop();

					// At the moment, we do not handle LOG2
					result.push(Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof Log3Operator) { // LOG3
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();
					Interval topic2 = result.pop();
					Interval topic3 = result.pop();

					// At the moment, we do not handle LOG3
					result.push(Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof Log4Operator) { // LOG4
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval topic1 = result.pop();
					Interval topic2 = result.pop();
					Interval topic3 = result.pop();
					Interval topic4 = result.pop();

					// At the moment, we do not handle LOG4
					result.push(Interval.ZERO);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CreateOperator) { // CREATE
					ArrayDeque<Interval> result = stack.clone();
					Interval value = result.pop();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle CREATE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CallOperator) { // CALL
					ArrayDeque<Interval> result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval value = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle CALL
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof CallcodeOperator) { // CALLCODE
					ArrayDeque<Interval> result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval value = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle CALLCODE
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof ReturnOperator) { // RETURN
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle RETURN

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof DelegatecallOperator) { // DELEGATECALL
					ArrayDeque<Interval> result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle DELEGATECALL
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof Create2Operator) { // CREATE2
					ArrayDeque<Interval> result = stack.clone();
					Interval value = result.pop();
					Interval offset = result.pop();
					Interval length = result.pop();
					Interval salt = result.pop();

					// At the moment, we do not handle CREATE2
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof StaticcallOperator) { // STATICCALL
					ArrayDeque<Interval> result = stack.clone();
					Interval gas = result.pop();
					Interval to = result.pop();
					Interval inOffset = result.pop();
					Interval inLength = result.pop();
					Interval outOffset = result.pop();
					Interval outLength = result.pop();

					// At the moment, we do not handle STATICCALL
					result.push(Interval.TOP);

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof RevertOperator) { // REVERT
					ArrayDeque<Interval> result = stack.clone();
					Interval offset = result.pop();
					Interval length = result.pop();

					// At the moment, we do not handle REVERT

					return new SymbolicStack(result, memory, mu_i);
				} else if (op instanceof InvalidOperator) { // INVALID
					return this;
				} else if (op instanceof SelfdestructOperator) { // SELFDESTRUCT
					ArrayDeque<Interval> result = stack.clone();
					Interval recipient = result.pop();

					// At the moment, we do not handle SELFDESTRUCT

					return new SymbolicStack(result, memory, mu_i);
				}
			}
		} catch (NoSuchElementException e) {
			System.err.println("Operation not performed: " + e);
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
		
		// TODO to create a more optimized version
		return new StringRepresentation(stack + ", memory: " + memory + ", mu_i: " + mu_i);
	}

	@Override
	public SymbolicStack lub(SymbolicStack other) throws SemanticException {
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

		return new SymbolicStack(result, memory, mu_i);
	}

	@Override
	public SymbolicStack widening(SymbolicStack other) throws SemanticException {
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

			return new SymbolicStack(widenedStack);
		}

		if (this.stack.size() == other.stack.size()) {
			ArrayDeque<Interval> widenedStack = new ArrayDeque<>();

			Iterator<Interval> thisIterator = this.stack.descendingIterator();
			Iterator<Interval> otherIterator = other.stack.descendingIterator();

			while (thisIterator.hasNext() && otherIterator.hasNext()) {
				Interval widenedInterval = thisIterator.next().widening(otherIterator.next());
				widenedStack.push(widenedInterval);
			}

			return new SymbolicStack(widenedStack);
		}

		return this;
	}

	@Override
	public boolean lessOrEqual(SymbolicStack other) throws SemanticException {
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
		// SymbolicStack check
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;

		SymbolicStack other = (SymbolicStack) obj;
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
	public SymbolicStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
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
						return new SymbolicStack(result, memory, mu_i);
					} else {
						// Condition could be either true or false
						// Return the result
						return new SymbolicStack(result, memory, mu_i);
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
								return new SymbolicStack(result, memory, mu_i);
							} else if (condition.equals(new Interval(1, 1))) {
								// Condition is surely true (interval [1,1])
								// Return BOTTOM
								return bottom();
							} else {
								// Condition could be either true or false
								// Return the result
								return new SymbolicStack(result, memory, mu_i);
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
	public SymbolicStack forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}
}