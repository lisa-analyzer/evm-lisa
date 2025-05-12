package it.unipr.analysis;

import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.frontend.EVMFrontend;
import it.unipr.utils.MyCache;
import it.unive.lisa.analysis.BaseLattice;
import it.unive.lisa.analysis.Lattice;
import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SemanticOracle;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.edge.TrueEdge;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.SymbolicExpression;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;
import java.io.IOException;
import java.math.BigInteger;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.function.Predicate;
import org.apache.commons.lang3.tuple.Pair;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.bouncycastle.jcajce.provider.digest.Keccak;
import org.bouncycastle.jcajce.provider.digest.Keccak.Digest256;

public class EVMAbstractState
		implements ValueDomain<EVMAbstractState>, BaseLattice<EVMAbstractState> {

	private static final Logger log = LogManager.getLogger(EVMAbstractState.class);

	private static final EVMAbstractState TOP = new EVMAbstractState(true, "");
	private static final EVMAbstractState BOTTOM = new EVMAbstractState(new AbstractStackSet().bottom(),
			new AbstractMemory().bottom(), new AbstractStorage().bottom());
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
	private final AbstractMemory memory;

	/**
	 * The storage.
	 */
	private final AbstractStorage storage;

	private static boolean USE_STORAGE_LIVE = false;

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
		this.memory = new AbstractMemory();
		this.storage = new AbstractStorage();

		if (contractAddress == null)
			CONTRACT_ADDRESS = null;
		else
			CONTRACT_ADDRESS = (contractAddress.matches("^0x[a-fA-F0-9]{40}$")) ? contractAddress : null;
	}

	/**
	 * Builds a EVMAbsDomain with the given stack, memory and mu_i. The built
	 * EVMAbsDomain is not TOP.
	 *
	 * @param stacks  the stack to be used.
	 * @param memory  the memory to be used.
	 * @param storage the storage to be used.
	 */
	public EVMAbstractState(AbstractStackSet stacks, AbstractMemory memory, AbstractStorage storage) {
		this.isTop = false;
		this.stacks = stacks;
		this.memory = memory;
		this.storage = storage;
	}

	/**
	 * Returns a cloned copy of the stack.
	 *
	 * @return A cloned copy of the stack or null if the original stack is null.
	 */
	public AbstractStackSet getStacks() {
		return stacks;
	}

	/**
	 * Returns a cloned copy of the memory.
	 *
	 * @return A cloned copy of the memory or null if the original memory is
	 *             null.
	 */
	public AbstractMemory getMemory() {
		return memory.clone();
	}

	/**
	 * Returns a cloned copy of the storage.
	 *
	 * @return A cloned copy of the storage or null if the original storage is
	 *             null.
	 */
	public AbstractStorage getStorage() {
		return storage.clone();
	}

	public static void setUseStorageLive() {
		USE_STORAGE_LIVE = true;
	}

	@Override
	public EVMAbstractState assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle) {
		// nothing to do here
		return this;
	}

	@SuppressWarnings("unused")
	@Override
	public EVMAbstractState smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// bottom state is propagated
		if (this.isBottom())
			return this;

		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();
			AbstractStackSet result = new AbstractStackSet(new HashSet<>(stacks.size()), false);

			if (op != null) {

				EVMCFG cfg = (EVMCFG) pp.getCFG();
				switch (op.getClass().getSimpleName()) {
				case "Push0Operator": { // PUSH0

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.ZERO);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage);
				}
				case "PushOperator": { // PUSH

					StackElement toPush = new StackElement(toBigInteger(un.getExpression()));

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(toPush);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage);
				}
				case "AddressOperator": { // ADDRESS

					StackElement hex;
					if (CONTRACT_ADDRESS == null)
						hex = StackElement.TOP;
					else
						hex = new StackElement(toBigInteger(CONTRACT_ADDRESS));

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(hex);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage);
				}

				case "BlobBaseFeeOperator": // BLOBBASEFEE
				case "GasOperator": // GAS
				case "MsizeOperator": // MSIZE
				case "BasefeeOperator": // BASEFEE
				case "CoinbaseOperator": // COINBASE
				case "TimestampOperator": // TIMESTAMP
				case "NumberOperator": // NUMBER
				case "DifficultyOperator": // DIFFICULTY
				case "GaslimitOperator": // GASLIMIT
				case "ChainidOperator": // CHAINID
				case "SelfbalanceOperator": // SELFBALANCE
				case "GaspriceOperator": // GASPRICE
				case "CodesizeOperator": // CODESIZE
				case "OriginOperator": // ORIGIN
				case "CallerOperator": // CALLER
				case "CalldatasizeOperator": // CALLDATASIZE
				case "CallvalueOperator": { // CALLVALUE
					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage);
				}

				case "ReturndatasizeOperator": { // RETURNDATASIZE
					for (AbstractStack stack : stacks) {
						// stack corresponding to the case when
						// last call failed
						AbstractStack resultStackFailing = stack.clone();
						resultStackFailing.push(StackElement.ZERO);
						result.add(resultStackFailing);

						// stack corresponding to the case when
						// last call was successful
						AbstractStack resultStackSuccess = stack.clone();
						resultStackSuccess.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStackSuccess);
					}

					return new EVMAbstractState(result, memory, storage);
				}
				case "PcOperator": { // PC
					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						Integer i = (Integer) ((Constant) un.getExpression()).getValue();
						resultStack.push(new StackElement(BigInteger.valueOf(i)));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage);
				}

				case "JumpdestOperator": { // JUMPDEST
					return this;
				}

				// Above, operators that do not perform pop()
				// Below, operators that perform pop operation on the stack

				case "JumpOperator": { // JUMP

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;

						AbstractStack resultStack = stack.clone();
						StackElement jmpDest = resultStack.pop();

						if (jmpDest.isBottom() || jmpDest.isTopNotJumpdest())
							continue;

						if (jmpDest.isTop() || cfg.getAllPushedJumps().contains(pp))
							result.add(resultStack);
						else if (cfg.getAllJumpdestLocations().contains(jmpDest.getNumber())) {
							Statement dest = cfg.getAllJumpdest().stream()
									.filter(j -> new Number(((ProgramCounterLocation) j.getLocation()).getPc())
											.equals(jmpDest.getNumber()))
									.findFirst().get();

							if (!cfg.getEdges().contains(new SequentialEdge((Statement) pp, dest)))
								cfg.addEdge(new SequentialEdge((Statement) pp, dest));
							result.add(resultStack);
						}
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "JumpiOperator": { // JUMPI

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement jmpDest = resultStack.pop();
						StackElement cond = resultStack.pop();

						if (jmpDest.isBottom() || cond.isBottom() || jmpDest.isTopNotJumpdest())
							continue;

						if (jmpDest.isTop() || cfg.getAllPushedJumps().contains(pp))
							result.add(resultStack);
						else if (cfg.getAllJumpdestLocations().contains(jmpDest.getNumber())) {
							Statement dest = cfg.getAllJumpdest().stream()
									.filter(j -> new Number(((ProgramCounterLocation) j.getLocation()).getPc())
											.equals(jmpDest.getNumber()))
									.findFirst().get();

							if (!cfg.getEdges().contains(new TrueEdge((Statement) pp, dest)))
								cfg.addEdge(new TrueEdge((Statement) pp, dest));
							result.add(resultStack);
						}
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "AddOperator": { // ADD

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.sum(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SubOperator": { // SUB

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.sub(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "MulOperator": { // MUL

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.mul(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "DivOperator": { // DIV
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						try {
							resultStack.push(opnd1.div(opnd2));
						} catch (ArithmeticException e) {
							resultStack.push(StackElement.ZERO);
						}
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SdivOperator": { // SDIV
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						try {
							resultStack.push(opnd1.div(opnd2));
						} catch (ArithmeticException e) {
							resultStack.push(StackElement.ZERO);
						}
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ModOperator": { // MOD
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.mod(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SmodOperator": { // SMOD
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.mod(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "AddmodOperator": { // ADDMOD
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();
						StackElement opnd3 = resultStack.pop();

						resultStack.push(opnd1.addmod(opnd2, opnd3));
						result.add(resultStack);
					}
					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "MulmodOperator": { // MULMOD
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();
						StackElement opnd3 = resultStack.pop();

						resultStack.push(opnd1.mulmod(opnd2, opnd3));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ExpOperator": { // EXP
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.exp(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SignextendOperator": { // SIGNEXTEND
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd2);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "LtOperator": { // LT
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.lt(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SltOperator": { // SLT
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.lt(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "GtOperator": { // GT
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.gt(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SgtOperator": { // SGT
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.gt(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "EqOperator": { // EQ
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.eq(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "IszeroOperator": { // ISZERO
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();

						resultStack.push(opnd1.isZero());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "AndOperator": { // AND
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.and(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "OrOperator": { // OR
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.or(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "XorOperator": { // XOR
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.xor(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "NotOperator": { // NOT
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();

						resultStack.push(opnd1.not());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ByteOperator": { // BYTE
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement indexOfByte = resultStack.pop();
						StackElement target = resultStack.pop();
						StackElement resultStackElement = StackElement.ZERO;

						if (target.isTop() || indexOfByte.isTop()) {
							resultStack.push(StackElement.TOP);
						} else if (target.isTopNotJumpdest() || indexOfByte.isTopNotJumpdest()) {
							resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						} else {
							byte[] valueAsByteArray = target.getNumber().toByteArray();

							if (indexOfByte.compareTo(new StackElement(valueAsByteArray.length)) >= 0)
								resultStackElement.lub(StackElement.ZERO);
							else if (indexOfByte.compareTo(new StackElement(Number.MAX_INT)) < 0) {
								int selectedByteAsInt = valueAsByteArray[indexOfByte.getNumber().getInt()];
								resultStackElement.lub(new StackElement(selectedByteAsInt));
							}

							resultStack.push(resultStackElement);
						}

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ShlOperator": { // SHL
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.shl(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ShrOperator": { // SHR
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.shr(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SarOperator": { // SAR

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement opnd1 = resultStack.pop();
						StackElement opnd2 = resultStack.pop();

						resultStack.push(opnd1.sar(opnd2));
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}

				case "BlobHashOperator": { // BLOBHASH
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement index = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}

				case "Sha3Operator": { // SHA3
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();
						StackElement size = resultStack.pop();

						if (offset.isUnknown() || size.isUnknown() || memory.isTop())
							resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						else if (offset.compareTo(new StackElement(Number.MAX_INT)) <= 0
								|| size.compareTo(new StackElement(Number.MAX_INT)) <= 0) {

							/*
							 * Read exactly size bytes from your abstract
							 * memory.
							 */
							byte[] chunk = memory.readBytes(
									offset.getNumber().getInt(),
									size.getNumber().getInt());

							if (chunk == null)
								resultStack.push(StackElement.NOT_JUMPDEST_TOP);
							else {
								Digest256 kecc = new Keccak.Digest256();
								kecc.update(chunk, 0, chunk.length);
								byte[] hash = kecc.digest();
								BigInteger hashedValue = new BigInteger(1, hash);

								resultStack.push(new StackElement(hashedValue));
							}
						} else
							resultStack.push(StackElement.NOT_JUMPDEST_TOP);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "BalanceOperator": { // BALANCE
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement address = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "CalldataloadOperator": { // CALLDATALOAD
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "CalldatacopyOperator": { // CALLDATACOPY
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(3);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "CodecopyOperator": { // CODECOPY
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(3);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ExtcodesizeOperator": { // EXTCODESIZE
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement address = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ExtcodecopyOperator": { // EXTCODECOPY
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(4);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ReturndatacopyOperator": { // RETURNDATACOPY
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(3);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ExtcodehashOperator": { // EXTCODEHASH
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement address = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "BlockhashOperator": { // BLOCKHASH
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement blockNumber = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "PopOperator": { // POP
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.pop();
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "TloadOperator": { // TLOAD
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement key = resultStack.pop();

						resultStack.push(StackElement.TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}

				case "TstoreOperator": { // TSTORE
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(2);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}

				case "MloadOperator": { // MLOAD
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();

						if (offset.isTop()
								|| offset.isTopNotJumpdest()
								|| memory.isTop()) {
							resultStack.push(StackElement.TOP);
						} else {
							StackElement mload = memory.mload(offset);
							if (mload.isBottom())
								continue;

							resultStack.push(mload);
						}

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "MstoreOperator": { // MSTORE
					AbstractMemory memoryResult = memory.bottom();

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack stackResult = stack.clone();

						StackElement offset = stackResult.pop();
						StackElement value = stackResult.pop();

						if (offset.isTop() || offset.isTopNotJumpdest() || memory.isTop()) {
							memoryResult = AbstractMemory.TOP;
						} else {
							AbstractMemory memoryTmp = memory.mstore(offset, value);
							if (memoryTmp.isBottom())
								continue;

							memoryResult = memoryResult.lub(memoryTmp);
						}
						result.add(stackResult);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memoryResult, storage);
				}
				case "Mstore8Operator": { // MSTORE8
					AbstractMemory memoryResult = memory.bottom();

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack stackResult = stack.clone();

						StackElement offset = stackResult.pop();
						StackElement value = stackResult.pop();

						if (offset.isTop() || offset.isTopNotJumpdest() || memory.isTop()) {
							memoryResult = AbstractMemory.TOP;
						} else {
							AbstractMemory memoryTmp = memory.mstore8(offset, value);
							if (memoryTmp.isBottom())
								continue;
							memoryResult = memoryResult.lub(memoryTmp);
						}
						result.add(stackResult);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memoryResult, storage);
				}
				case "McopyOperator": { // MCOPY
					AbstractMemory memoryResult = memory.bottom();

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack stackResult = stack.clone();

						StackElement destOffset = stackResult.pop();
						StackElement offset = stackResult.pop();
						StackElement size = stackResult.pop();

						if (destOffset.isTop() || offset.isTop() || size.isTop()
								|| destOffset.isTopNotJumpdest() || offset.isTopNotJumpdest()
								|| size.isTopNotJumpdest()) {
							memoryResult = AbstractMemory.TOP;
						} else if (memory.isTop()) {
							memoryResult = AbstractMemory.TOP;
						} else {
							AbstractMemory memoryTmp = memory.mcopy(destOffset, offset, size);
							if (memoryTmp.isBottom())
								continue;
							memoryResult = memoryResult.lub(memoryTmp);
						}
						result.add(stackResult);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memoryResult, storage);
				}
				case "SloadOperator": { // SLOAD

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement key = resultStack.pop();
						AbstractStorage storageCopy = storage.clone();

						StackElement valueToPush = StackElement.TOP;
						if (key.isTop() || key.isTopNotJumpdest())
							valueToPush = StackElement.TOP;
						else {
							if (storage.getKeys().contains(key.getNumber()))
								valueToPush = valueToPush.lub(storage.getState(key.getNumber()));
							else {
								if (USE_STORAGE_LIVE && CONTRACT_ADDRESS != null) {
									StackElement valueCached = MyCache.getInstance()
											.get(Pair.of(CONTRACT_ADDRESS, key.getNumber()));

									if (valueCached == null) {
										long start = System.currentTimeMillis();
										valueToPush = getStorageAt(key.getNumber(), CONTRACT_ADDRESS); // API
										// request
										long timeLostToGetStorage = System.currentTimeMillis() - start;

										MyCache.getInstance().updateTimeLostToGetStorage(CONTRACT_ADDRESS,
												timeLostToGetStorage);

										MyCache.getInstance().put(Pair.of(CONTRACT_ADDRESS, key.getNumber()),
												valueToPush);
									} else {
										valueToPush = valueCached;
										log.debug("Value cached");
									}
								} else
									valueToPush = StackElement.TOP;
							}
						}

						resultStack.push(valueToPush);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "SstoreOperator": { // SSTORE

					AbstractStorage storageResult = storage.bottom();

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement key = resultStack.pop();
						StackElement value = resultStack.pop();

						AbstractStorage storageCopy = storage.clone();

						if (!(key.isTop() || key.isTopNotJumpdest()))
							storageResult = storageCopy.putState(key.getNumber(), value);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storageResult);
				}
				case "Dup1Operator": { // DUP1

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = dupX(1, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup2Operator": { // DUP2

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = dupX(2, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup3Operator": { // DUP3

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = dupX(3, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup4Operator": { // DUP4

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = dupX(4, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup5Operator": { // DUP5

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(5))
							continue;
						AbstractStack resultStack = dupX(5, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup6Operator": { // DUP6

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = dupX(6, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup7Operator": { // DUP7

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = dupX(7, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup8Operator": { // DUP8

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(8))
							continue;
						AbstractStack resultStack = dupX(8, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup9Operator": { // DUP9

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(9))
							continue;
						AbstractStack resultStack = dupX(9, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup10Operator": { // DUP10

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(10))
							continue;
						AbstractStack resultStack = dupX(10, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup11Operator": { // DUP11

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(11))
							continue;
						AbstractStack resultStack = dupX(11, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup12Operator": { // DUP12

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(12))
							continue;
						AbstractStack resultStack = dupX(12, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup13Operator": { // DUP13

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(13))
							continue;
						AbstractStack resultStack = dupX(13, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup14Operator": { // DUP14

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(14))
							continue;
						AbstractStack resultStack = dupX(14, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup15Operator": { // DUP15

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(15))
							continue;
						AbstractStack resultStack = dupX(15, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Dup16Operator": { // DUP16

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(16))
							continue;
						AbstractStack resultStack = dupX(16, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap1Operator": { // SWAP1

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = swapX(1, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap2Operator": { // SWAP2

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = swapX(2, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap3Operator": { // SWAP3

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = swapX(3, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap4Operator": { // SWAP4

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(5))
							continue;
						AbstractStack resultStack = swapX(4, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap5Operator": { // SWAP5

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = swapX(5, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap6Operator": { // SWAP6

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = swapX(6, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap7Operator": { // SWAP7

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(8))
							continue;
						AbstractStack resultStack = swapX(7, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap8Operator": { // SWAP8

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(9))
							continue;
						AbstractStack resultStack = swapX(8, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap9Operator": { // SWAP9

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(10))
							continue;
						AbstractStack resultStack = swapX(9, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap10Operator": { // SWAP10

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(11))
							continue;
						AbstractStack resultStack = swapX(10, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap11Operator": { // SWAP11

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(12))
							continue;
						AbstractStack resultStack = swapX(11, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap12Operator": { // SWAP12

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(13))
							continue;
						AbstractStack resultStack = swapX(12, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap13Operator": { // SWAP13

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(14))
							continue;
						AbstractStack resultStack = swapX(13, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap14Operator": { // SWAP14

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(15))
							continue;
						AbstractStack resultStack = swapX(14, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap15Operator": { // SWAP15

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(16))
							continue;
						AbstractStack resultStack = swapX(15, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Swap16Operator": { // SWAP16

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(17))
							continue;
						AbstractStack resultStack = swapX(16, stack);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Log0Operator": { // LOG0
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(2);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Log1Operator": { // LOG1
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(3);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Log2Operator": { // LOG2
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(4);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Log3Operator": { // LOG3
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(5))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(5);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Log4Operator": { // LOG4
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(6);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "CreateOperator": { // CREATE
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(3);

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "Create2Operator": { // CREATE2
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(4);

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "CallOperator": { // CALL
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(7);

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "CallcodeOperator": { // CALLCODE
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(7);
						
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "ReturnOperator": { // RETURN
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "DelegatecallOperator": { // DELEGATECALL
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(6);

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "StaticcallOperator": { // STATICCALL
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(6);

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "RevertOperator": { // REVERT
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						resultStack.popX(2);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				case "InvalidOperator": { // INVALID
					return this;
				}
				case "SelfdestructOperator": { // SELFDESTRUCT
					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement recipient = resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage);
				}
				}
			}
		}

		throw new SemanticException("Unrecognized opcode: " + pp);
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
		return stack.dupX(x);
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
		return stack.swapX(x);
	}

	@Override
	public EVMAbstractState assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest,
			SemanticOracle oracle) {
		return this;
	}

	@Override
	public EVMAbstractState forgetIdentifier(Identifier id) {
		// nothing to do here
		return this;
	}

	@Override
	public EVMAbstractState forgetIdentifiersIf(Predicate<Identifier> test) {
		// nothing to do here
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle) {
		// nothing to do here
		return Satisfiability.UNKNOWN;
	}

	@Override
	public EVMAbstractState pushScope(ScopeToken token) {
		// nothing to do here
		return this;
	}

	@Override
	public EVMAbstractState popScope(ScopeToken token) {
		// nothing to do here
		return this;
	}

	@Override
	public StructuredRepresentation representation() {
		if (isBottom())
			return Lattice.bottomRepresentation();
		else if (isTop())
			return Lattice.topRepresentation();

		return new StringRepresentation(
				"{ stacks: " + stacks + ", memory: " + memory + ", storage: " + storage + " }");
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
		return this == TOP;
	}

	@Override
	public boolean isBottom() {
		return this == BOTTOM;
	}

	/**
	 * Helper method to convert a memory word to a BigInteger.
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
		return new Number(bigIntVal);
	}

	@Override
	public int hashCode() {
		return Objects.hash(isTop, memory, stacks, storage);
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
		return isTop == other.isTop && Objects.equals(memory, other.memory) && Objects.equals(stacks, other.stacks)
				&& Objects.equals(storage, other.storage);
	}

	/**
	 * Getter for the interval value at the top of the stack.
	 *
	 * @return the interval value at the top of the stack.
	 */
	public Set<StackElement> getTop() {
		Set<StackElement> result = new HashSet<>();
		for (AbstractStack stack : stacks)
			result.add(stack.getTop());

		return result;
	}

	/**
	 * Yields the second elements of all the stacks in the stack set.
	 *
	 * @return the second elements of all the stacks in the stack set
	 */
	public Set<StackElement> getSecondElement() {
		Set<StackElement> result = new HashSet<>();
		for (AbstractStack stack : stacks)
			result.add(stack.getSecondElement());

		return result;
	}

	@Override
	public EVMAbstractState wideningAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stacks.widening(other.stacks),
				memory.widening(other.getMemory()),
				storage.widening(other.storage));
	}

	@Override
	public EVMAbstractState lubAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stacks.lubAux(other.stacks),
				memory.lub(other.getMemory()),
				storage.lub(other.storage));
	}

	@Override
	public EVMAbstractState glbAux(EVMAbstractState other) throws SemanticException {
		return new EVMAbstractState(stacks.glbAux(other.stacks),
				memory.glb(other.getMemory()),
				storage.glb(other.storage));
	}

	@Override
	public boolean lessOrEqualAux(EVMAbstractState other) throws SemanticException {
		return stacks.lessOrEqual(other.stacks) &&
				memory.lessOrEqual(other.getMemory()) &&
				storage.lessOrEqual(other.getStorage());
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
		for (byte b : bytes)
			System.out.printf("%02X ", b);
		System.out.println();
	}

	/**
	 * Retrieves the storage value at a specific key for a given Ethereum
	 * contract address using the Etherscan API.
	 *
	 * @param key     the storage key as a Number. This key will be converted to
	 *                    a hexadecimal string.
	 * @param address the Ethereum contract address as a String.
	 *
	 * @return a {@link StackElement} containing the storage value if the
	 *             request is successful, or {@link StackElement#TOP} if an
	 *             error occurs.
	 */
	public StackElement getStorageAt(Number key, String address) {
		try {
			BigInteger toHex = Number.toBigInteger(key);
			String hexString = "0x" + toHex.toString(16);

			String getStorageAtRequest;
			synchronized (MyCache.getInstance()) {
				Thread.sleep(500);
				getStorageAtRequest = EVMFrontend.etherscanRequest("proxy", "eth_getStorageAt", hexString, address);
			}

			if (getStorageAtRequest == null || getStorageAtRequest.isEmpty()) {
				System.err.println("ERROR: couldn't download contract's storage.");
				return StackElement.TOP;
			}

			String[] test = getStorageAtRequest.split("\"");
			String bytecode = test[9].substring(2);

			BigInteger decimal = new BigInteger(bytecode, 16);

			return new StackElement(decimal);
		} catch (IOException | InterruptedException e) {
			log.error(e.getMessage());
		}

		return StackElement.TOP;
	}

	@Override
	public boolean knowsIdentifier(Identifier id) {
		return true;
	}
}