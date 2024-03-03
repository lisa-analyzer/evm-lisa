package it.unipr.analysis;

import it.unipr.analysis.operator.JumpiOperator;
import it.unive.lisa.analysis.BaseLattice;
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
import it.unive.lisa.symbolic.value.Skip;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.LogicalNegation;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import java.math.BigInteger;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.function.Predicate;
import org.apache.commons.lang3.tuple.Pair;

public class EVMAbstractState implements ValueDomain<EVMAbstractState>, BaseLattice<EVMAbstractState> {

	private static final EVMAbstractState TOP = new EVMAbstractState(true, "");
	private static final EVMAbstractState BOTTOM = new EVMAbstractState(new AbstractStackSet().bottom(),
			new Memory().bottom(), new Memory().bottom(), KIntegerSet.BOTTOM);
	private final boolean isTop;

	/**
	 * The address of the running contract.
	 */
	private static String CONTRACT_ADDRESS;

	/**
	 * The stack memory.
	 */
	private final AbstractStackSet stacks;

	/**
	 * The volatile memory.
	 */
	private final Memory memory;

	/**
	 * The storage.
	 */
	private final Memory storage;

	private final KIntegerSet mu_i;

	/**
	 * Builds the abstract domain.
	 */
	public EVMAbstractState(String contractAddress) {
		this(false, contractAddress);
	}

	/**
	 * Builds the abstract domain.
	 * 
	 * @param isTop whether the abstract value is top.
	 */
	private EVMAbstractState(boolean isTop, String contractAddress) {
		this.isTop = isTop;
		this.stacks = new AbstractStackSet();
		this.memory = new Memory();
		this.storage = new Memory();
		this.mu_i = KIntegerSet.ZERO;

		CONTRACT_ADDRESS = contractAddress;
	}

	/**
	 * Builds a EVMAbsDomain with the given stack, memory and mu_i. The built
	 * EVMAbsDomain is not TOP.
	 * 
	 * @param stack  the stack to be used.
	 * @param memory the memory to be used.
	 * @param mu_i   the mu_i to be used.
	 */
	public EVMAbstractState(AbstractStackSet stacks, Memory memory, Memory storage, KIntegerSet mu_i) {
		this.isTop = false;
		this.stacks = stacks;
		this.memory = memory;
		this.storage = storage;
		this.mu_i = mu_i;
	}

	/**
	 * Returns a cloned copy of the stack.
	 *
	 * @return A cloned copy of the stack or null if the original stack is null.
	 */
	public AbstractStackSet getStacks() {
		return stacks.clone();
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
		return mu_i;
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
			return this;

		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op != null) {

				switch (op.getClass().getSimpleName()) {
				case "Push0Operator": { // PUSH0
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.ZERO);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "PushOperator": { // PUSH
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);
					KIntegerSet toPush = new KIntegerSet(toBigInteger(un.getExpression()));

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(toPush);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "AddressOperator": { // ADDRESS
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);
					KIntegerSet hex = new KIntegerSet(toBigInteger(CONTRACT_ADDRESS));

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(hex);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "OriginOperator": { // ORIGIN
					// At the moment, we do not handle ORIGIN
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CallerOperator": { // CALLER
					// At the moment, we do not handle CALLER
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CallvalueOperator": { // CALLVALUE
					// At the moment, we do not handle CALLVALUE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CalldatasizeOperator": { // CALLDATASIZE
					// At the moment, we do not handle CALLDATASIZE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CodesizeOperator": { // CODESIZE
					// At the moment, we do not handle CODESIZE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "GaspriceOperator": { // GASPRICE
					// At the moment, we do not handle GASPRIZE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ReturndatasizeOperator": { // RETURNDATASIZE
					// At the moment, we do not handle RETURNDATASIZE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CoinbaseOperator": { // COINBASE
					// At the moment, we do not handle COINBASE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "TimestampOperator": { // TIMESTAMP
					// At the moment, we do not handle TIMESTAMP
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "NumberOperator": { // NUMBER
					// At the moment, we do not handle NUMBER
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "DifficultyOperator": { // DIFFICULTY
					// At the moment, we do not handle DIFFICULTY
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "GaslimitOperator": { // GASLIMIT
					// At the moment, we do not handle GASLIMIT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ChainidOperator": { // CHAINID
					// At the moment, we do not handle CHAINID
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SelfbalanceOperator": { // SELFBALANCE
					// At the moment, we do not handle SELFBALANCE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "PcOperator": { // PC
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						Integer i = (Integer) ((Constant) un.getExpression()).getValue();
						resultStack.push(new KIntegerSet(BigInteger.valueOf(i)));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "GasOperator": { // GAS
					// At the moment, we do not handle GAS
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "JumpiOperator": { // JUMPI
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.pop();
						resultStack.pop();
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MsizeOperator": { // MSIZE
					// At the moment, we do not handle MSIZE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "BasefeeOperator": { // BASEFEE
					// At the moment, we do not handle BASEFEE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "JumpdestOperator": { // JUMPDEST
					return this;
				}

				// Above, operators that do not perform pop()
				// Below, operators that perform pop operation on the stack

				case "JumpOperator": { // JUMP
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.pop();
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "AddOperator": { // ADD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.sum(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SubOperator": { // SUB
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.sub(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MulOperator": { // MUL
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.mul(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "DivOperator": { // DIV
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();
//						System.err.println(opnd1 + " " + opnd2);
//						System.err.println(opnd2.equals(KIntegerSet.ZERO) && !opnd1.isTop());
//						
//						resultStack.push(opnd1.div(opnd2));
//						resultStack.push(opnd2.equals(KIntegerSet.ZERO) && !opnd1.isTop() ? KIntegerSet.ZERO : opnd1.div(opnd2));
						try {
							resultStack.push(opnd1.div(opnd2));
						} catch (ArithmeticException e) {
							resultStack.push(KIntegerSet.ZERO);
						}
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SdivOperator": { // SDIV
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

//						resultStack.push(opnd2.equals(KIntegerSet.ZERO) && !opnd1.isTop() ? KIntegerSet.ZERO : opnd1.div(opnd2));
						try {
							resultStack.push(opnd1.div(opnd2));
						} catch (ArithmeticException e) {
							resultStack.push(KIntegerSet.ZERO);
						}
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ModOperator": { // MOD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.mod(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SmodOperator": { // SMOD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.mod(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "AddmodOperator": { // ADDMOD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();
						KIntegerSet opnd3 = resultStack.pop();

						resultStack.push(opnd1.addmod(opnd2, opnd3));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MulmodOperator": { // MULMOD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();
						KIntegerSet opnd3 = resultStack.pop();

						resultStack.push(opnd1.mulmod(opnd2, opnd3));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ExpOperator": { // EXP
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.exp(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SignextendOperator": { // SIGNEXTEND
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd2);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "LtOperator": { // LT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.lt(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SltOperator": { // SLT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.lt(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "GtOperator": { // GT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.gt(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SgtOperator": { // SGT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.gt(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "EqOperator": { // EQ
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.eq(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "IszeroOperator": { // ISZERO
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();

						resultStack.push(opnd1.isZero());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "AndOperator": { // AND
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.and(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "OrOperator": { // OR
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.or(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "XorOperator": { // XOR
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.xor(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "NotOperator": { // NOT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();

						resultStack.push(opnd1.not());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ByteOperator": { // BYTE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet indexOfByte = resultStack.pop();
						KIntegerSet target = resultStack.pop();
						KIntegerSet resultKIntegerSet = KIntegerSet.ZERO;

						if (target.isTop() || indexOfByte.isTop()) {
							resultStack.push(KIntegerSet.NUMERIC_TOP);
						} else {
							for (Number value : target) {
								byte[] valueAsByteArray = value.toByteArray();

								for (Number index : indexOfByte) {
									int intIndex = index.intValue();

									if (intIndex <= 0 || intIndex >= valueAsByteArray.length) {
										resultKIntegerSet.lub(KIntegerSet.ZERO);
									} else {
										int selectedByteAsInt = valueAsByteArray[intIndex];
										resultKIntegerSet.lub(new KIntegerSet(selectedByteAsInt));
									}
								}
							}
							resultStack.push(resultKIntegerSet);
						}

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ShlOperator": { // SHL
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.shl(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ShrOperator": { // SHR
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.shr(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SarOperator": { // SAR
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet opnd1 = resultStack.pop();
						KIntegerSet opnd2 = resultStack.pop();

						resultStack.push(opnd1.sar(opnd2));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Sha3Operator": { // SHA3
					// At the moment, we do not handle SHA3
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "BalanceOperator": { // BALANCE
					// At the moment, we do not handle BALANCE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet address = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CalldataloadOperator": { // CALLDATALOAD
					// At the moment, we do not handle CALLDATALOAD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();

						resultStack.push(KIntegerSet.NUMERIC_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CalldatacopyOperator": { // CALLDATACOPY
					// At the moment, we do not handle CALLDATACOPY
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet memOffset = resultStack.pop();
						KIntegerSet dataOffset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CodecopyOperator": { // CODECOPY
					// At the moment, we do not handle CODECOPY
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet memOffset = resultStack.pop();
						KIntegerSet dataOffset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ExtcodesizeOperator": { // EXTCODESIZE
					// At the moment, we do not handle EXTCODESIZE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet address = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ExtcodecopyOperator": { // EXTCODECOPY
					// At the moment, we do not handle EXTCODECOPY
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet address = resultStack.pop();
						KIntegerSet memOffset = resultStack.pop();
						KIntegerSet dataOffset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ReturndatacopyOperator": { // RETURNDATACOPY
					// At the moment, we do not handle RETURNDATACOPY
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet memOffset = resultStack.pop();
						KIntegerSet dataOffset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ExtcodehashOperator": { // EXTCODEHASH
					// At the moment, we do not handle EXTCODEHASH
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet address = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "BlockhashOperator": { // BLOCKHASH
					// At the moment, we do not handle BLOCKHASH
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet blockNumber = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "PopOperator": { // POP
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.pop();
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MloadOperator": { // MLOAD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet new_mu_i = null;

						KIntegerSet offset = resultStack.pop();

						if (mu_i.equals(KIntegerSet.ZERO)) {
							// This is an error. We cannot read from memory if
							// there is no active words saved
							resultStack.push(KIntegerSet.NUMERIC_TOP);
						} else if (offset.isTop()) {
							resultStack.push(KIntegerSet.NUMERIC_TOP);
							new_mu_i = mu_i;
						} else {
							resultStack.push(offset.mload(memory));
							new_mu_i = mu_i;
						}

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MstoreOperator": { // MSTORE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);
					Memory memoryResult = memory;
					KIntegerSet new_mu_i = mu_i;

					for (AbstractStack stack : stacks) {
						AbstractStack stackResult = stack.clone();

						KIntegerSet offset = stackResult.pop();
						KIntegerSet value = stackResult.pop();

						if (offset.isTop()) {
							new_mu_i = mu_i;
							memoryResult = memory;
						} else {
							KIntegerSet current_mu_i_lub = KIntegerSet.BOTTOM;

							for (Number os : offset) {
								Number thirtyTwo = new Number(32);
								Number current_mu_i = os.add(thirtyTwo)
										.divide(thirtyTwo);

								memoryResult = memory.putState(os, value);

								current_mu_i_lub = current_mu_i_lub.lub(new KIntegerSet(current_mu_i));
							}

							new_mu_i = current_mu_i_lub;
						}
						result.add(stackResult);
					}

					return new EVMAbstractState(result, memoryResult, storage, new_mu_i);
				}
				case "Mstore8Operator": { // MSTORE8
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);
					Memory memoryResult = memory;
					KIntegerSet new_mu_i = mu_i;

					for (AbstractStack stack : stacks) {
						AbstractStack stackResult = stack.clone();

						KIntegerSet offset = stackResult.pop();
						KIntegerSet value = stackResult.pop();

						if (offset.isTop()) {
							new_mu_i = mu_i;
							memoryResult = memory;
						} else {
							KIntegerSet current_mu_i_lub = KIntegerSet.BOTTOM;

							for (Number os : offset) {
								Number current_mu_i = os.add(new Number(1))
										.divide(new Number(32));

								memoryResult = memory.putState(os, value.mod(new KIntegerSet(new Number(256))));

								current_mu_i_lub = current_mu_i_lub.lub(new KIntegerSet(current_mu_i));
							}

							new_mu_i = current_mu_i_lub;
						}
						result.add(stackResult);
					}

					return new EVMAbstractState(result, memoryResult, storage, new_mu_i);
				}
				case "SloadOperator": { // SLOAD
					// At the moment, we do not handle SLOAD
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet key = resultStack.pop();

						KIntegerSet valueToPush = KIntegerSet.BOTTOM;
						if (key.isTop() || key.isTopNotJumpdest() || storage.isBottom())
							valueToPush = KIntegerSet.NUMERIC_TOP;
						else {
							for (Number k : key)
								if (storage.getMap().containsKey(k))
									valueToPush = valueToPush.lub(storage.getState(k));
								else
									valueToPush = valueToPush.lub(KIntegerSet.NUMERIC_TOP);
						}

						resultStack.push(valueToPush);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SstoreOperator": { // SSTORE
					// At the moment, we do not handle SSTORE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);
					Memory storageResult = new Memory().bottom();
					
					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet key = resultStack.pop();
						KIntegerSet value = resultStack.pop();

						Memory storageCopy = storage.clone();
						
						for (Number k : key) 
							storageCopy = storageCopy.putState(k, value);
						
						storageResult = storageResult.lub(storageCopy);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storageResult, mu_i);
				}
				case "Dup1Operator": { // DUP1
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(1, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup2Operator": { // DUP2
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(2, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup3Operator": { // DUP3
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(3, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup4Operator": { // DUP4
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(4, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup5Operator": { // DUP5
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(5, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup6Operator": { // DUP6
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(6, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup7Operator": { // DUP7
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(7, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup8Operator": { // DUP8
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(8, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup9Operator": { // DUP9
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(9, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup10Operator": { // DUP10
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(10, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup11Operator": { // DUP11
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(11, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup12Operator": { // DUP12
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(12, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup13Operator": { // DUP13
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(13, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup14Operator": { // DUP14
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(14, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup15Operator": { // DUP15
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(15, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup16Operator": { // DUP16
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = dupX(16, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap1Operator": { // SWAP1
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(1, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap2Operator": { // SWAP2
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(2, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap3Operator": { // SWAP3
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(3, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap4Operator": { // SWAP4
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(4, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap5Operator": { // SWAP5
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(5, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap6Operator": { // SWAP6
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(6, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap7Operator": { // SWAP7
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(7, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap8Operator": { // SWAP8
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(8, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap9Operator": { // SWAP9
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(9, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap10Operator": { // SWAP10
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(10, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap11Operator": { // SWAP11
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(11, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap12Operator": { // SWAP12
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(12, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap13Operator": { // SWAP13
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(13, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap14Operator": { // SWAP14
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(14, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap15Operator": { // SWAP15
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(15, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap16Operator": { // SWAP16
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = swapX(16, stack.clone());
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log0Operator": { // LOG0
					// At the moment, we do not handle LOG0
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log1Operator": { // LOG1
					// At the moment, we do not handle LOG1
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log2Operator": { // LOG2
					// At the moment, we do not handle LOG2
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();
						resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log3Operator": { // LOG3
					// At the moment, we do not handle LOG3
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();
						resultStack.pop();
						resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log4Operator": { // LOG4
					// At the moment, we do not handle LOG4
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();
						resultStack.pop();
						resultStack.pop();
						resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CreateOperator": { // CREATE
					// At the moment, we do not handle CREATE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet value = resultStack.pop();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Create2Operator": { // CREATE2
					// At the moment, we do not handle CREATE2
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet value = resultStack.pop();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();
						KIntegerSet salt = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CallOperator": { // CALL
					// At the moment, we do not handle CALL
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet gas = resultStack.pop();
						KIntegerSet to = resultStack.pop();
						KIntegerSet value = resultStack.pop();
						KIntegerSet inOffset = resultStack.pop();
						KIntegerSet inLength = resultStack.pop();
						KIntegerSet outOffset = resultStack.pop();
						KIntegerSet outLength = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CallcodeOperator": { // CALLCODE
					// At the moment, we do not handle CALLCODE
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet gas = resultStack.pop();
						KIntegerSet to = resultStack.pop();
						KIntegerSet value = resultStack.pop();
						KIntegerSet inOffset = resultStack.pop();
						KIntegerSet inLength = resultStack.pop();
						KIntegerSet outOffset = resultStack.pop();
						KIntegerSet outLength = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ReturnOperator": { // RETURN
					// At the moment, we do not handle RETURN
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "DelegatecallOperator": { // DELEGATECALL
					// At the moment, we do not handle DELEGATECALL
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet gas = resultStack.pop();
						KIntegerSet to = resultStack.pop();
						KIntegerSet inOffset = resultStack.pop();
						KIntegerSet inLength = resultStack.pop();
						KIntegerSet outOffset = resultStack.pop();
						KIntegerSet outLength = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "StaticcallOperator": { // STATICCALL
					// At the moment, we do not handle STATICCALL
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet gas = resultStack.pop();
						KIntegerSet to = resultStack.pop();
						KIntegerSet inOffset = resultStack.pop();
						KIntegerSet inLength = resultStack.pop();
						KIntegerSet outOffset = resultStack.pop();
						KIntegerSet outLength = resultStack.pop();

						resultStack.push(KIntegerSet.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "RevertOperator": { // REVERT
					// At the moment, we do not handle REVERT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet offset = resultStack.pop();
						KIntegerSet length = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "InvalidOperator": { // INVALID
					return this;
				}
				case "SelfdestructOperator": { // SELFDESTRUCT
					// At the moment, we do not handle SELFDESTRUCT
					AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						KIntegerSet recipient = resultStack.pop();

						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				}
			}
		}

		if (!(expression instanceof Skip))
			throw new SemanticException("Reachable just with the skip node");

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

		if (stack.size() < x || x < 1)
			return stack.bottom();

		Object[] obj = clone.toArray();

		int first;
		if (stack.size() < AbstractStack.getStackLimit())
			first = AbstractStack.getStackLimit();
		else
			first = clone.size();

		KIntegerSet tmp = (KIntegerSet) obj[first - x];

		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < clone.size(); i++)
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

		if (stack.size() < x + 1 || x < 1)
			return stack.bottom();

		Object[] obj = clone.toArray();
		int first;

		if (stack.size() < AbstractStack.getStackLimit())
			first = AbstractStack.getStackLimit() - 1;
		else
			first = clone.size() - 1;

		Object tmp = obj[first];
		obj[first] = obj[first - x];
		obj[first - x] = tmp;

		LinkedList<KIntegerSet> result = new LinkedList<>();

		for (int i = 0; i < clone.size(); i++)
			result.add((KIntegerSet) obj[i]);

		return new AbstractStack(result);
	}

	@Override
	public EVMAbstractState assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest)
			throws SemanticException {
		// Ensure BOTTOM and TOP propagation

		if (this.isBottom() || this.isTop())
			return this;

		if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof JumpiOperator) { // JUMPI

				@SuppressWarnings("unchecked")
				Pair<Set<AbstractStack>, Set<AbstractStack>> split = ((Pair<Set<AbstractStack>,
						Set<AbstractStack>>) ((Constant) un.getExpression()).getValue());
				if (split.getLeft().isEmpty() && split.getRight().isEmpty())
					return top();
				else if (split.getLeft().isEmpty())
					return bottom();
				return new EVMAbstractState(new AbstractStackSet(split.getLeft(), false), memory, storage, mu_i);

			} else if (op instanceof LogicalNegation) {
				// Get the expression wrapped by LogicalNegation
				SymbolicExpression wrappedExpr = un.getExpression();

				if (wrappedExpr instanceof UnaryExpression) {
					UnaryOperator wrappedOperator = ((UnaryExpression) wrappedExpr).getOperator();

					// Check if LogicalNegation is wrapping a JUMPI
					if (wrappedOperator instanceof JumpiOperator) { // !JUMPI

						@SuppressWarnings("unchecked")
						Pair<Set<AbstractStack>,
						Set<AbstractStack>> split = ((Pair<Set<AbstractStack>, Set<
								AbstractStack>>) ((Constant) ((UnaryExpression) wrappedExpr).getExpression())
								.getValue());
						if (split.getLeft().isEmpty() && split.getRight().isEmpty())
							return top();
						else if (split.getRight().isEmpty())
							return bottom();
						return new EVMAbstractState(new AbstractStackSet(split.getRight(), false), memory, storage, mu_i);
					}
				}
			}
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

		return new StringRepresentation(
				"{ stacks: " + stacks.toString2() + ", memory: " + memory + ", mu_i: " + mu_i + " }");
	}

	@Override
	public EVMAbstractState top() {
		return TOP;
	}

	@Override
	public EVMAbstractState bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isTop() {
		return stacks.isTop();
	}

	@Override
	public boolean isBottom() {
		return stacks.isBottom();
	}

	/**
	 * Helper method to convert a memory word to a BigInteger
	 * 
	 * @param expression the memory word to convert
	 * 
	 * @return the BigInteger corresponding to the memory word
	 */
	private Number toBigInteger(SymbolicExpression expression) {
		Constant c = (Constant) expression;
		String hex = (String) c.getValue();
		return toBigInteger(hex);
	}

	private Number toBigInteger(String str) {
		String hexadecimal = str.substring(2);
		BigInteger bigIntVal = new BigInteger(hexadecimal, 16);
		//		BigDecimal bigDecimalVal = new BigDecimal(bigIntVal);
		return new Number(bigIntVal);
	}

	@Override
	public int hashCode() {
		return Objects.hash(isTop, memory, mu_i, stacks, storage);
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
				&& Objects.equals(stacks, other.stacks) && Objects.equals(storage, other.storage);
	}
	
	

	/**
	 * Getter for the interval value at the top of the stack.
	 * 
	 * @return the interval value at the top of the stack.
	 */
	public Set<KIntegerSet> getTop() {
		Set<KIntegerSet> result = new HashSet<KIntegerSet>();
		for (AbstractStack stack : stacks)
			result.add(stack.getTop());

		return result;
	}

	public Set<KIntegerSet> getSecondElement() {
		Set<KIntegerSet> result = new HashSet<KIntegerSet>();
		for (AbstractStack stack : stacks)
			result.add(stack.getSecondElement());

		return result;
	}

	/**
	 * Yields whether the stack is empty.
	 * 
	 * @return {@code true} if the stack is empty, {@code false} otherwise
	 */
	public boolean isEmpty() {
		for (AbstractStack stack : stacks)
			if (!stack.isEmpty())
				return false;

		return true;
	}

	@Override
	public EVMAbstractState wideningAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stacks.widening(other.getStacks()),
				memory.widening(other.getMemory()),
				storage.widening(other.storage),
				mu_i.widening(other.getMu_i()));
	}

	@Override
	public EVMAbstractState lubAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stacks.lubAux(other.getStacks()),
				memory.lub(other.getMemory()),
				storage.lub(other.storage),
				mu_i.lub(other.getMu_i()));
	}

	@Override
	public EVMAbstractState glbAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stacks.glbAux(other.getStacks()),
				memory.glb(other.getMemory()),
				storage.glb(other.storage),
				mu_i.glb(other.getMu_i()));
	}

	@Override
	public boolean lessOrEqualAux(EVMAbstractState other) throws SemanticException {
		return stacks.lessOrEqual(other.getStacks()) &&
				memory.lessOrEqual(other.getMemory()) &&
				mu_i.lessOrEqual(other.getMu_i());
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