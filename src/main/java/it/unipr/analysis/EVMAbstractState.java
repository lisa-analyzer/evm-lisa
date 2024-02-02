package it.unipr.analysis;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.RoundingMode;
import java.util.LinkedList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Objects;
import java.util.function.Predicate;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import it.unipr.analysis.operator.JumpiOperator;
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
import it.unive.lisa.symbolic.value.operator.unary.LogicalNegation;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;

public class EVMAbstractState implements ValueDomain<EVMAbstractState>, BaseLattice<EVMAbstractState> {
	private static final Logger LOG = LogManager.getLogger(EVMAbstractState.class);

	private static final EVMAbstractState TOP = new EVMAbstractState();
	private static final EVMAbstractState BOTTOM = new EVMAbstractState(null, null, null);
	private final boolean isTop;

	/**
	 * The stack memory.
	 */
	private final AbstractStack stack;

	/**
	 * The volatile memory.
	 */
	private final Memory memory;

	private final KIntegerSet mu_i; // TODO Give a better name

	/**
	 * Builds the abstract domain.
	 */
	public EVMAbstractState() {
		this(true);
	}

	/**
	 * Builds the abstract domain.
	 * 
	 * @param isTop whether the abstract value is top.
	 */
	private EVMAbstractState(boolean isTop) {
		this.isTop = isTop;
		this.stack = new AbstractStack();
		this.memory = new Memory();
		this.mu_i = KIntegerSet.ZERO;
	}

	/**
	 * Builds a EVMAbsDomain with the given stack, memory and mu_i. The built
	 * EVMAbsDomain is not TOP.
	 * 
	 * @param stack  the stack to be used.
	 * @param memory the memory to be used.
	 * @param mu_i   the mu_i to be used.
	 */
	public EVMAbstractState(AbstractStack stack, Memory memory, KIntegerSet mu_i) {
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
	public AbstractStack getStack() {
		return stack.clone();
	}

	/**
	 * Returns a cloned copy of the memory.
	 *
	 * @return A cloned copy of the memory or null if the original memory is
	 *             null.
	 */
	public Memory getMemory() {
		return memory.clone();
	}

	/**
	 * Returns a cloned copy of the interval mu_i.
	 *
	 * @return A cloned copy of the interval mu_i or null if the original mu_i
	 *             is null.
	 */
	public KIntegerSet getMu_i() {
		return mu_i; // TODO to be cloned
	}

	@Override
	public EVMAbstractState assign(Identifier id, ValueExpression expression, ProgramPoint pp)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@SuppressWarnings("unused")
	@Override
	public EVMAbstractState smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// bottom state is propagated
		if (this.isBottom())
			return EVMAbstractState.BOTTOM;

		try {
			if (expression instanceof Constant) {
				return this;
			} else if (expression instanceof UnaryExpression) {
				UnaryExpression un = (UnaryExpression) expression;
				UnaryOperator op = un.getOperator();

				if (op != null) {

					switch (op.getClass().getSimpleName()) {
					case "Push0Operator": { // PUSH0
						AbstractStack result = stack.clone();
						result.push(KIntegerSet.ZERO);
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "PushOperator": { // PUSH
						AbstractStack result = stack.clone();
						BigDecimal valueToPush = this.toBigDecimal(un.getExpression());

						result.push(new KIntegerSet(valueToPush));

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "AddressOperator": { // ADDRESS
						AbstractStack result = stack.clone();

						// At the moment, we do not handle ADDRESS
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "OriginOperator": { // ORIGIN
						AbstractStack result = stack.clone();

						// At the moment, we do not handle ORIGIN
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CallerOperator": { // CALLER
						AbstractStack result = stack.clone();

						// At the moment, we do not handle CALLER
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CallvalueOperator": { // CALLVALUE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle CALLVALUE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CalldatasizeOperator": { // CALLDATASIZE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle CALLDATASIZE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CodesizeOperator": { // CODESIZE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle CODESIZE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "GaspriceOperator": { // GASPRICE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle GASPRICE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ReturndatasizeOperator": { // RETURNDATASIZE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle RETURNDATASIZE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CoinbaseOperator": { // COINBASE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle COINBASE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "TimestampOperator": { // TIMESTAMP
						AbstractStack result = stack.clone();

						// At the moment, we do not handle TIMESTAMP
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "NumberOperator": { // NUMBER
						AbstractStack result = stack.clone();

						// At the moment, we do not handle NUMBER
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "DifficultyOperator": { // DIFFICULTY
						AbstractStack result = stack.clone();

						// At the moment, we do not handle DIFFICULTY
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "GaslimitOperator": { // GASLIMIT
						AbstractStack result = stack.clone();

						// At the moment, we do not handle GASLIMIT
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ChainidOperator": { // CHAINID
						AbstractStack result = stack.clone();

						// At the moment, we do not handle CHAINID
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SelfbalanceOperator": { // SELFBALANCE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle SELFBALANCE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "PcOperator": { // PC
						AbstractStack result = stack.clone();

						// At the moment, we do not handle PC
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "GasOperator": { // GAS
						AbstractStack result = stack.clone();

						// At the moment, we do not handle GAS
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "JumpOperator": { // JUMP
						AbstractStack result = stack.clone();
						result.pop();
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "JumpiOperator": { // JUMPI
						return this;
					}
					case "MsizeOperator": { // MSIZE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle MSIZE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "JumpdestOperator": { // JUMPDEST
						return this;
					}
					}
					// Above, operators that do not perform pop()

					// from here on, top is propagated
					if (isTop())
						return this;

					// Below, operators that perform pop operation on the stack
					switch (op.getClass().getSimpleName()) {

					case "AddOperator": { // ADD
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						result.push(opnd1.sum(opnd2));
					}
					case "SubOperator": { // SUB
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						result.push(opnd1.sub(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "MulOperator": { // MUL
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();

						result.push(opnd1.mul(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "DivOperator": { // DIV
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
				
						result.push(opnd1.div(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SdivOperator": { // SDIV
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						Interval div;

						result.push(opnd1.div(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ModOperator": { // MOD
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						Interval mod;

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						
						result.push(opnd1.mod(opnd2));

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SmodOperator": { // SMOD
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						Interval mod;

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						result.push(opnd1.mod(opnd2));

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "AddmodOperator": { // ADDMOD
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						KIntegerSet opnd3 = result.pop();
						Interval addmod;

						result.push(opnd1.addmod(opnd2, opnd3));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "MulmodOperator": { // MULMOD
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						KIntegerSet opnd3 = result.pop();
						Interval mulmod;

						if (opnd1.isBottom() || opnd2.isBottom() || opnd3.isBottom())
							return top();
						
						result.push(opnd1.mulmod(opnd2, opnd3));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ExpOperator": { // EXP
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();

						result.push(opnd1.exp(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SignextendOperator": { // SIGNEXTEND
						AbstractStack result = stack.clone();
						result.pop();
						result.pop();

						// At the moment, we do not handle SIGNEXTEND
						result.push(KIntegerSet.TOP);
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "LtOperator": { // LT
						AbstractStack result = stack.clone();

						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						result.push(opnd1.lt(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SltOperator": { // SLT
						AbstractStack result = stack.clone();

						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						
						result.push(opnd1.lt(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "GtOperator": { // GT
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();

						result.push(opnd1.gt(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SgtOperator": { // SGT
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						
						result.push(opnd1.gt(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "EqOperator": { // EQ
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom())
							return top();
						result.push(opnd1.eq(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "IszeroOperator": { // ISZERO
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();

						if (opnd1.isBottom())
							return top();
						
						result.push(opnd1.isZero());
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "AndOperator": { // AND
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom()) {
							result.push(KIntegerSet.TOP);
							return new EVMAbstractState(result, memory, mu_i);
						}

						result.push(opnd1.and(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "OrOperator": { // OR
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						if (opnd1.isBottom() || opnd2.isBottom()) {
							result.push(KIntegerSet.TOP);
							return new EVMAbstractState(result, memory, mu_i);
						}

						result.push(opnd1.or(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "XorOperator": { // XOR
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						
						result.push(opnd1.xor(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "NotOperator": { // NOT
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();

						result.push(opnd1.not());
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ByteOperator": { // BYTE
						AbstractStack result = stack.clone();
						KIntegerSet indexOfByte = result.pop();
						KIntegerSet target = result.pop();

//						Interval resultInterval = new Interval().bottom(); // Accumulates
//						// retrieved
//						// bytes
//
//						if (target.isBottom() || target.isTop()) {
//							result.push(Interval.TOP);
//						} else {
//
//							// Loop through all targets (each value of the
//							// target
//							// interval)
//							for (Long value : target.interval) {
//								byte[] valueAsByteArray = BigInteger.valueOf(value).toByteArray();
//
//								// Loop through all possible indexes of byte to
//								// select
//								for (Long index : indexOfByte.interval) {
//									int intIndex = index.intValue();
//
//									// Check if index is valid (>= 0 and <
//									// valueAsByteArray.length)
//									if (intIndex <= 0 || intIndex >= valueAsByteArray.length) {
//										resultInterval.lub(Interval.ZERO);
//									} else {
//										int selectedByteAsInt = valueAsByteArray[intIndex];
//										resultInterval.lub(new Interval(selectedByteAsInt, selectedByteAsInt));
//									}
//								}
//							}

							result.push(KIntegerSet.TOP);
//						}

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ShlOperator": { // SHL
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();

						result.push(opnd1.shl(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ShrOperator": { // SHR
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						
						result.push(opnd1.shr(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SarOperator": { // SAR
						AbstractStack result = stack.clone();
						KIntegerSet opnd1 = result.pop();
						KIntegerSet opnd2 = result.pop();
						
						result.push(opnd1.sar(opnd2));
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "Sha3Operator": { // SHA3
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle SHA3
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "BalanceOperator": { // BALANCE
						AbstractStack result = stack.clone();
						KIntegerSet address = result.pop();

						// At the moment, we do not handle BALANCE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CalldataloadOperator": { // CALLDATALOAD
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();

						// At the moment, we do not handle CALLDATALOAD
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CalldatacopyOperator": { // CALLDATACOPY
						AbstractStack result = stack.clone();
						KIntegerSet memOffset = result.pop();
						KIntegerSet dataOffset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle CALLDATACOPY

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CodecopyOperator": { // CODECOPY
						AbstractStack result = stack.clone();
						KIntegerSet memOffset = result.pop();
						KIntegerSet codeOffset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle CODECOPY

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ExtcodesizeOperator": { // EXTCODESIZE
						AbstractStack result = stack.clone();
						KIntegerSet address = result.pop();

						// At the moment, we do not handle EXTCODESIZE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ExtcodecopyOperator": { // EXTCODECOPY
						AbstractStack result = stack.clone();
						KIntegerSet address = result.pop();
						KIntegerSet memOffset = result.pop();
						KIntegerSet codeOffset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle EXTCODECOPY

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ReturndatacopyOperator": { // RETURNDATACOPY
						AbstractStack result = stack.clone();
						KIntegerSet memOffset = result.pop();
						KIntegerSet retOffset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle RETURNDATACOPY

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ExtcodehashOperator": { // EXTCODEHASH
						AbstractStack result = stack.clone();
						KIntegerSet address = result.pop();

						// At the moment, we do not handle EXTCODEHASH
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "BlockhashOperator": { // BLOCKHASH
						AbstractStack result = stack.clone();
						KIntegerSet blockNumber = result.pop();

						// At the moment, we do not handle BLOCKHASH
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "PopOperator": { // POP
						AbstractStack result = stack.clone();

						result.pop();

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "MloadOperator": { // MLOAD
						AbstractStack result = stack.clone();
						KIntegerSet new_mu_i = null;

						KIntegerSet offset = result.pop();

						if (mu_i.equals(KIntegerSet.MINUS_ONE)) {
							// This is an error. We cannot read from memory if
							// there
							// is no active words saved
							result.push(KIntegerSet.TOP);
							return new EVMAbstractState(result, memory, mu_i);
						}

						if (memory == null) {
							LOG.warn("[MLOAD] memory == null");
						}

						if (offset.isTop() || offset.isBottom()) {
							result.push(KIntegerSet.TOP);
							new_mu_i = mu_i;
						} else  {
							result.push(offset.mload(memory));

							// We create a new Interval singleton with the newly
							// calculated `current_mu_i`
							// Interval intervalCurrent_mu_i = new
							// Interval(current_mu_i.intValueExact(),
							// current_mu_i.intValueExact());
							//
							// // Then we compare the 2 mu_i and update the new
							// value
							// if (mu_i.compareTo(intervalCurrent_mu_i) == -1)
							// new_mu_i = intervalCurrent_mu_i;
							// else
							new_mu_i = mu_i;
						} 

						return new EVMAbstractState(result, memory, new_mu_i);
					}
					case "MstoreOperator": { // MSTORE
						AbstractStack stackResult = stack.clone();
						Memory memoryResult = null;
						KIntegerSet new_mu_i = null;

						KIntegerSet offset = stackResult.pop();
						KIntegerSet value = stackResult.pop();

						if (offset.isTop() || offset.isBottom() ) {
							new_mu_i = mu_i;
							memoryResult = memory;
						} else {
							KIntegerSet current_mu_i_lub = KIntegerSet.BOTTOM;
							for (BigDecimal os : offset) {
								BigDecimal thirtyTwo = new BigDecimal(32);
								BigDecimal current_mu_i = os.add(thirtyTwo)
										.divide(thirtyTwo)
										.setScale(0, RoundingMode.UP); 

								memoryResult = memory.putState(os, value);

								// We create a new Interval singleton with the newly
								// calculated `current_mu_i`
								current_mu_i_lub = current_mu_i_lub.lub(new KIntegerSet(current_mu_i));
							}
							

//							// Then we compare the 2 mu_i and update the new
//							// value
//							if (mu_i.compareTo(intervalCurrent_mu_i) == -1)
//								new_mu_i = intervalCurrent_mu_i;
//							else
//								new_mu_i = mu_i;
							new_mu_i = current_mu_i_lub; // TODO: check

						} 

						return new EVMAbstractState(stackResult, memoryResult, new_mu_i);
					}
					case "Mstore8Operator": { // MSTORE8
						AbstractStack result = stack.clone();
//						Memory memoryResult = null;
//						Interval new_mu_i = null;

						KIntegerSet offset = result.pop();
						KIntegerSet value = result.pop();

//						if (offset.interval.isSingleton()) {
//							BigDecimal one = new BigDecimal(1);
//							BigDecimal thirtyTwo = new BigDecimal(32);
//
//							BigDecimal offsetBigDecimal = offset.interval.getHigh().getNumber();
//							BigDecimal current_mu_i = offsetBigDecimal.add(one)
//									.divide(thirtyTwo)
//									.setScale(0, RoundingMode.UP); // setScale()
//							// =
//							// Ceiling
//							// function
//
//							if (value.interval.isSingleton()) {
//								BigDecimal valueBigDecimal = offset.interval.getHigh().getNumber();
//								BigDecimal valueByteBigDecimal = valueBigDecimal.remainder(new BigDecimal(256));
//
//								Interval valueInByte = new Interval(valueByteBigDecimal.intValueExact(),
//										valueByteBigDecimal.intValueExact());
//
//								memoryResult = memory.putState(offsetBigDecimal, valueInByte);
//							} else {
//								// TODO to handle else-condition
//								// If value is not singleton, how would we
//								// handle
//								// the `mod 256` operation?
//								memoryResult = memory.putState(offsetBigDecimal, Interval.TOP);
//							}
//
//							// We create a new Interval singleton with the newly
//							// calculated `current_mu_i`
//							Interval intervalCurrent_mu_i = new Interval(current_mu_i.intValueExact(),
//									current_mu_i.intValueExact());
//
//							if (mu_i.compareTo(intervalCurrent_mu_i) == -1)
//								new_mu_i = intervalCurrent_mu_i;
//							else
//								new_mu_i = mu_i;
//
//						} else {
//							// TODO to handle else-condition
//							new_mu_i = mu_i;
//							memoryResult = memory;
//						}

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SloadOperator": { // SLOAD
						AbstractStack result = stack.clone();
						KIntegerSet key = result.pop();

						// At the moment, we do not handle SLOAD
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "SstoreOperator": { // SSTORE
						AbstractStack result = stack.clone();
						KIntegerSet key = result.pop();
						KIntegerSet value = result.pop();

						// At the moment, we do not handle SSTORE

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "Dup1Operator": { // DUP1
						return new EVMAbstractState(dupX(1, stack.clone()), memory, mu_i);
					}
					case "Dup2Operator": { // DUP2
						return new EVMAbstractState(dupX(2, stack.clone()), memory, mu_i);
					}
					case "Dup3Operator": { // DUP3
						return new EVMAbstractState(dupX(3, stack.clone()), memory, mu_i);
					}
					case "Dup4Operator": { // DUP4
						return new EVMAbstractState(dupX(4, stack.clone()), memory, mu_i);
					}
					case "Dup5Operator": { // DUP5
						return new EVMAbstractState(dupX(5, stack.clone()), memory, mu_i);
					}
					case "Dup6Operator": { // DUP6
						return new EVMAbstractState(dupX(6, stack.clone()), memory, mu_i);
					}
					case "Dup7Operator": { // DUP7
						return new EVMAbstractState(dupX(7, stack.clone()), memory, mu_i);
					}
					case "Dup8Operator": { // DUP8
						return new EVMAbstractState(dupX(8, stack.clone()), memory, mu_i);
					}
					case "Dup9Operator": { // DUP9
						return new EVMAbstractState(dupX(9, stack.clone()), memory, mu_i);
					}
					case "Dup10Operator": { // DUP10
						return new EVMAbstractState(dupX(10, stack.clone()), memory, mu_i);
					}
					case "Dup11Operator": { // DUP11
						return new EVMAbstractState(dupX(11, stack.clone()), memory, mu_i);
					}
					case "Dup12Operator": { // DUP12
						return new EVMAbstractState(dupX(12, stack.clone()), memory, mu_i);
					}
					case "Dup13Operator": { // DUP13
						return new EVMAbstractState(dupX(13, stack.clone()), memory, mu_i);
					}
					case "Dup14Operator": { // DUP14
						return new EVMAbstractState(dupX(14, stack.clone()), memory, mu_i);
					}
					case "Dup15Operator": { // DUP15
						return new EVMAbstractState(dupX(15, stack.clone()), memory, mu_i);
					}
					case "Dup16Operator": { // DUP16
						return new EVMAbstractState(dupX(16, stack.clone()), memory, mu_i);
					}
					case "Swap1Operator": { // SWAP1
						return new EVMAbstractState(swapX(1, stack.clone()), memory, mu_i);
					}
					case "Swap2Operator": { // SWAP2
						return new EVMAbstractState(swapX(2, stack.clone()), memory, mu_i);
					}
					case "Swap3Operator": { // SWAP3
						return new EVMAbstractState(swapX(3, stack.clone()), memory, mu_i);
					}
					case "Swap4Operator": { // SWAP4
						return new EVMAbstractState(swapX(4, stack.clone()), memory, mu_i);
					}
					case "Swap5Operator": { // SWAP5
						return new EVMAbstractState(swapX(5, stack.clone()), memory, mu_i);
					}
					case "Swap6Operator": { // SWAP6
						return new EVMAbstractState(swapX(6, stack.clone()), memory, mu_i);
					}
					case "Swap7Operator": { // SWAP7
						return new EVMAbstractState(swapX(7, stack.clone()), memory, mu_i);
					}
					case "Swap8Operator": { // SWAP8
						return new EVMAbstractState(swapX(8, stack.clone()), memory, mu_i);
					}
					case "Swap9Operator": { // SWAP9
						return new EVMAbstractState(swapX(9, stack.clone()), memory, mu_i);
					}
					case "Swap10Operator": { // SWAP10
						return new EVMAbstractState(swapX(10, stack.clone()), memory, mu_i);
					}
					case "Swap11Operator": { // SWAP11
						return new EVMAbstractState(swapX(11, stack.clone()), memory, mu_i);
					}
					case "Swap12Operator": { // SWAP12
						return new EVMAbstractState(swapX(12, stack.clone()), memory, mu_i);
					}
					case "Swap13Operator": { // SWAP13
						return new EVMAbstractState(swapX(13, stack.clone()), memory, mu_i);
					}
					case "Swap14Operator": { // SWAP14
						return new EVMAbstractState(swapX(14, stack.clone()), memory, mu_i);
					}
					case "Swap15Operator": { // SWAP15
						return new EVMAbstractState(swapX(15, stack.clone()), memory, mu_i);
					}
					case "Swap16Operator": { // SWAP16
						return new EVMAbstractState(swapX(16, stack.clone()), memory, mu_i);
					}
					case "Log0Operator": { // LOG0
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle LOG0
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "Log1Operator": { // LOG1
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();
						KIntegerSet topic1 = result.pop();

						// At the moment, we do not handle LOG1
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "Log2Operator": { // LOG2
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();
						KIntegerSet topic1 = result.pop();
						KIntegerSet topic2 = result.pop();

						// At the moment, we do not handle LOG2
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "Log3Operator": { // LOG3
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();
						KIntegerSet topic1 = result.pop();
						KIntegerSet topic2 = result.pop();
						KIntegerSet topic3 = result.pop();

						// At the moment, we do not handle LOG3
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "Log4Operator": { // LOG4
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();
						KIntegerSet topic1 = result.pop();
						KIntegerSet topic2 = result.pop();
						KIntegerSet topic3 = result.pop();
						KIntegerSet topic4 = result.pop();

						// At the moment, we do not handle LOG4
						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CreateOperator": { // CREATE
						AbstractStack result = stack.clone();
						KIntegerSet value = result.pop();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle CREATE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "Create2Operator": { // CREATE2
						AbstractStack result = stack.clone();
						KIntegerSet value = result.pop();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();
						KIntegerSet salt = result.pop();

						// At the moment, we do not handle CREATE2
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CallOperator": { // CALL
						AbstractStack result = stack.clone();
						KIntegerSet gas = result.pop();
						KIntegerSet to = result.pop();
						KIntegerSet value = result.pop();
						KIntegerSet inOffset = result.pop();
						KIntegerSet inLength = result.pop();
						KIntegerSet outOffset = result.pop();
						KIntegerSet outLength = result.pop();

						// At the moment, we do not handle CALL
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "CallcodeOperator": { // CALLCODE
						AbstractStack result = stack.clone();
						KIntegerSet gas = result.pop();
						KIntegerSet to = result.pop();
						KIntegerSet value = result.pop();
						KIntegerSet inOffset = result.pop();
						KIntegerSet inLength = result.pop();
						KIntegerSet outOffset = result.pop();
						KIntegerSet outLength = result.pop();

						// At the moment, we do not handle CALLCODE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "ReturnOperator": { // RETURN
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle RETURN

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "DelegatecallOperator": { // DELEGATECALL
						AbstractStack result = stack.clone();
						KIntegerSet gas = result.pop();
						KIntegerSet to = result.pop();
						KIntegerSet inOffset = result.pop();
						KIntegerSet inLength = result.pop();
						KIntegerSet outOffset = result.pop();
						KIntegerSet outLength = result.pop();

						// At the moment, we do not handle DELEGATECALL
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "StaticcallOperator": { // STATICCALL
						AbstractStack result = stack.clone();
						KIntegerSet gas = result.pop();
						KIntegerSet to = result.pop();
						KIntegerSet inOffset = result.pop();
						KIntegerSet inLength = result.pop();
						KIntegerSet outOffset = result.pop();
						KIntegerSet outLength = result.pop();

						// At the moment, we do not handle STATICCALL
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "RevertOperator": { // REVERT
						AbstractStack result = stack.clone();
						KIntegerSet offset = result.pop();
						KIntegerSet length = result.pop();

						// At the moment, we do not handle REVERT

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "InvalidOperator": { // INVALID
						return this;
					}
					case "SelfdestructOperator": { // SELFDESTRUCT
						AbstractStack result = stack.clone();
						KIntegerSet recipient = result.pop();

						// At the moment, we do not handle SELFDESTRUCT

						return new EVMAbstractState(result, memory, mu_i);
					}
					case "BasefeeOperator": { // BASEFEE
						AbstractStack result = stack.clone();

						// At the moment, we do not handle BASEFEE
						result.push(KIntegerSet.TOP);

						return new EVMAbstractState(result, memory, mu_i);
					}
					}
				}
			}
		} catch (NoSuchElementException e) {
			System.err.println("[SSS] Operation not performed: " + e.getMessage() + " " + e);
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
	private AbstractStack dupX(int x, AbstractStack stack) {
		List<KIntegerSet> clone = stack.clone().getStack();

		if(stack.size() < x || x < 1)
			return stack.clone();

		Object[] obj = clone.toArray();

		int first;
		if(stack.size() < AbstractStack.K)
			first = AbstractStack.K;
		else
			first = clone.size();

		KIntegerSet tmp = (KIntegerSet) obj[first - x];

		LinkedList<KIntegerSet> result = new LinkedList<>();

		for(int i = 0; i < clone.size(); i++)
			result.add((KIntegerSet) obj[i]);

		result.add(tmp);
		result.remove(0);

		return new AbstractStack(result);
	}

	/**
	 * Swaps the 1st with the (x + 1)-th element from the top of the stack and
	 * returns the modified stack.
	 *
	 * @param x     The position of the element to swap with the top of the
	 *                  stack.
	 * @param stack The original stack.
	 * 
	 * @return A new stack with the specified elements swapped.
	 */
	private AbstractStack swapX(int x, AbstractStack stack) {
		List<KIntegerSet> clone = stack.clone().getStack();

		if(stack.size() < x + 1 || x < 1)
			return stack.clone();

		Object[] obj = clone.toArray();
		int first;

		if(stack.size() < AbstractStack.K)
			first = AbstractStack.K - 1;
		else
			first = clone.size() - 1;

		Object tmp = obj[first];
		obj[first] = obj[first - x];
		obj[first - x] = tmp;

		LinkedList<KIntegerSet> result = new LinkedList<>();

		for(int i = 0; i < clone.size(); i++)
			result.add((KIntegerSet) obj[i]);

		return new AbstractStack(result);
	}

	@Override
	public EVMAbstractState assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
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
					AbstractStack result = stack.clone();
					result.pop();
					KIntegerSet condition = result.pop();

					if (condition.equals(KIntegerSet.ZERO)) {
						// Condition is surely false (interval [0,0])
						// Return BOTTOM
						return bottom();
					} else if (condition.equals(KIntegerSet.ONE)) {
						// Condition is surely true (interval [1,1])
						// Return the result
						return new EVMAbstractState(result, memory, mu_i);
					} else {
						// Condition could be either true or false
						// Return the result
						return new EVMAbstractState(result, memory, mu_i);
					}

				} else if (op instanceof LogicalNegation) {
					// Get the expression wrapped by LogicalNegation
					SymbolicExpression wrappedExpr = un.getExpression();

					if (wrappedExpr instanceof UnaryExpression) {
						UnaryOperator wrappedOperator = ((UnaryExpression) wrappedExpr).getOperator();

						// Check if LogicalNegation is wrapping a JUMPI
						if (wrappedOperator instanceof JumpiOperator) { // !JUMPI
							AbstractStack result = stack.clone();
							result.pop();
							KIntegerSet condition = result.pop();

							if (condition.equals(KIntegerSet.ZERO)) {
								// Condition is surely false (interval [0,0])
								// Return the result
								return new EVMAbstractState(result, memory, mu_i);
							} else if (condition.equals(KIntegerSet.ONE)) {
								// Condition is surely true (interval [1,1])
								// Return BOTTOM
								return bottom();
							} else {
								// Condition could be either true or false
								// Return the result
								return new EVMAbstractState(result, memory, mu_i);
							}
						}
					}
				}
			}
		} catch (NoSuchElementException e) {
			System.err.println("[ASSUME] Operation not performed: " + e.getMessage() + " " + e);
		}

		return this;
	}

	@Override
	public EVMAbstractState forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public EVMAbstractState forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return Satisfiability.UNKNOWN;
	}

	@Override
	public EVMAbstractState pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public EVMAbstractState popScope(ScopeToken token) throws SemanticException {
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
	public EVMAbstractState top() {
		return TOP;
	}

	@Override
	public EVMAbstractState bottom() {
		return BOTTOM;
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
		EVMAbstractState other = (EVMAbstractState) obj;
		return isTop == other.isTop && Objects.equals(memory, other.memory) && Objects.equals(mu_i, other.mu_i)
				&& Objects.equals(stack, other.stack);
	}

	/**
	 * Getter for the interval value at the top of the stack.
	 * 
	 * @return the interval value at the top of the stack.
	 */
	public KIntegerSet getTop() {
		return stack.getTop();
	}

	public boolean isEmpty() {
		return stack.isEmpty();
	}

	@Override
	public EVMAbstractState wideningAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stack.widening(other.getStack()),
				memory.widening(other.getMemory()),
				mu_i.widening(other.getMu_i()));
	}

	@Override
	public EVMAbstractState lubAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stack.lub(other.getStack()),
				memory.lub(other.getMemory()),
				mu_i.lub(other.getMu_i()));
	}

	@Override
	public EVMAbstractState glbAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stack.glb(other.getStack()),
				memory.glb(other.getMemory()),
				mu_i.glb(other.getMu_i()));
	}

	@Override
	public boolean lessOrEqualAux(EVMAbstractState other) throws SemanticException {
		return stack.lessOrEqual(other.getStack()) &&
				memory.lessOrEqual(other.getMemory()) &&
				mu_i.lessOrEqual(other.getMu_i());
	}

	

	/**
	 * Shifts the given byte array to the left by the specified number of bits.
	 *
	 * @param byteArray     The byte array to be left-shifted.
	 * @param shiftBitCount The number of bits by which to shift the byte array
	 *                          to the left.
	 * 
	 * @return The resulting byte array after left-shifting by the specified bit
	 *             count.
	 *             <p>
	 *             This method performs a left shift on the provided byte array,
	 *             where each byte is shifted to the left by the given number of
	 *             bits. The shift operation is performed in a bitwise manner,
	 *             and the bits shifted beyond the byte boundary are wrapped
	 *             around to the opposite end. The shift is done in place, and
	 *             the modified byte array is returned as the result.
	 *             </p>
	 *             <p>
	 *             The {@code shiftBitCount} parameter determines the number of
	 *             bits to shift.
	 *             </p>
	 * 
	 * @throws IllegalArgumentException If the input {@code byteArray} is
	 *                                      {@code null}.
	 */
	public static byte[] shiftLeft(byte[] byteArray, int shiftBitCount) {
		final int shiftMod = shiftBitCount % 8;
		final byte carryMask = (byte) ((1 << shiftMod) - 1);
		final int offsetBytes = (shiftBitCount / 8);

		int start;

		if (byteArray.length > 32)
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
	 * Shifts the bits of the given byte array towards the least significant bit
	 * (SAR - Shift Arithmetic Right). The bits moved before the first one are
	 * discarded, and the new bits are set to 0 if the previous most significant
	 * bit was 0; otherwise, the new bits are set to 1.
	 *
	 * @param byteArray     The byte array to be right-shifted.
	 * @param shiftBitCount The number of bits by which to shift the byte array
	 *                          to the right.
	 * 
	 * @return The resulting byte array after right-shifting by the specified
	 *             bit count.
	 *             <p>
	 *             This method performs a right shift on the provided byte array
	 *             (SAR operation), where each byte is shifted to the right by
	 *             the given number of bits. The shift operation is performed in
	 *             a bitwise manner, and the bits shifted beyond the byte
	 *             boundary are discarded. The new bits introduced during the
	 *             shift are set based on the value of the previous most
	 *             significant bit (0 or 1).
	 *             </p>
	 *             <p>
	 *             The {@code shiftBitCount} parameter determines the number of
	 *             bits to shift.
	 *             </p>
	 *
	 * @throws IllegalArgumentException If the input {@code byteArray} is
	 *                                      {@code null}.
	 */
	public static byte[] shiftArithmeticRight(byte[] byteArray, int shiftBitCount) {
		final int shiftMod = shiftBitCount % 8;
		final byte carryMask = (byte) (0xFF << (8 - shiftMod));
		final int offsetBytes = (shiftBitCount / 8);

		int sourceIndex;
		int start;

		if (byteArray.length > 32)
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
	 * Prints the hexadecimal representation of a byte array to the standard
	 * output.
	 *
	 * @param bytes The byte array to be printed in hexadecimal format.
	 *                  <p>
	 *                  This method iterates through each byte in the array and
	 *                  prints its hexadecimal representation. Each byte is
	 *                  formatted as a two-digit uppercase hexadecimal value,
	 *                  separated by a space. After printing all bytes, a
	 *                  newline character is appended to the output.
	 *                  </p>
	 *
	 * @throws IllegalArgumentException If the input {@code bytes} is
	 *                                      {@code null}.
	 */
	public static void printByte(byte[] bytes) {
		for (byte b : bytes) {
			System.out.printf("%02X ", b);
		}
		System.out.println();
	}

}