package it.unipr.analysis.taint;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.function.Predicate;

import org.apache.commons.lang3.tuple.Pair;

import it.unipr.analysis.AbstractStack;
import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.Memory;
import it.unipr.analysis.MyCache;
import it.unipr.analysis.Number;
import it.unipr.analysis.StackElement;
import it.unipr.cfg.EVMCFG;
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
import it.unive.lisa.symbolic.value.Skip;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;

public class TaintAbstractStack implements ValueDomain<TaintAbstractStack>, BaseLattice<TaintAbstractStack> {

	private static int STACK_LIMIT = 32;
	private static final TaintAbstractStack TOP = new TaintAbstractStack(
			new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.TOP)));
	private static final TaintAbstractStack BOTTOM = new TaintAbstractStack(null);

	private final ArrayList<TaintElement> stack;

	/**
	 * Builds a taint abstract stack starting from a given stack.
	 *
	 * @param stack the stack of values
	 */
	public TaintAbstractStack(ArrayList<TaintElement> stack) {
		this.stack = stack;
	}

	@Override
	public TaintAbstractStack assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
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
				case "OriginOperator":
				{ 
					TaintAbstractStack resultStack = clone();
					resultStack.push(TaintElement.TAINT);
					return resultStack;
				}
				case "CallvalueOperator":
				case "CallerOperator":
				case "AddressOperator":
				case "PushOperator":
				case "Push0Operator": { 
					TaintAbstractStack resultStack = clone();
					resultStack.push(TaintElement.CLEAN);
					return resultStack;
				}


				case "CalldatasizeOperator": { // CALLDATASIZE
					// At the moment, we do not handle CALLDATASIZE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CodesizeOperator": { // CODESIZE
					// At the moment, we do not handle CODESIZE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "GaspriceOperator": { // GASPRICE
					// At the moment, we do not handle GASPRIZE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ReturndatasizeOperator": { // RETURNDATASIZE
					// At the moment, we do not handle RETURNDATASIZE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CoinbaseOperator": { // COINBASE
					// At the moment, we do not handle COINBASE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "TimestampOperator": { // TIMESTAMP
					// At the moment, we do not handle TIMESTAMP

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "NumberOperator": { // NUMBER
					// At the moment, we do not handle NUMBER

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "DifficultyOperator": { // DIFFICULTY
					// At the moment, we do not handle DIFFICULTY

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "GaslimitOperator": { // GASLIMIT
					// At the moment, we do not handle GASLIMIT

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ChainidOperator": { // CHAINID
					// At the moment, we do not handle CHAINID

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SelfbalanceOperator": { // SELFBALANCE
					// At the moment, we do not handle SELFBALANCE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "PcOperator": { // PC

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						Integer i = (Integer) ((Constant) un.getExpression()).getValue();
						resultStack.push(new StackElement(BigInteger.valueOf(i)));
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "GasOperator": { // GAS
					// At the moment, we do not handle GAS

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MsizeOperator": { // MSIZE
					// At the moment, we do not handle MSIZE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "BasefeeOperator": { // BASEFEE
					// At the moment, we do not handle BASEFEE

					for (AbstractStack stack : stacks) {
						AbstractStack resultStack = stack.clone();
						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
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

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;

						AbstractStack resultStack = stack.clone();
						StackElement jmpDest = resultStack.pop();
						if (((EVMCFG) pp.getCFG()).getAllPushedJumps().contains(pp) && jmpDest.isTop())
							continue;

						if (jmpDest.isBottom() || jmpDest.isTopNotJumpdest())
							continue;

						if (((EVMCFG) pp.getCFG()).getAllJumpdestLocations().contains(jmpDest.getNumber())
								|| jmpDest.isTop())
							result.add(resultStack);

					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
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

						if (((EVMCFG) pp.getCFG()).getAllJumpdestLocations().contains(jmpDest.getNumber())
								|| jmpDest.isTop())
							result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ModOperator": 
				case "SdivOperator":
				case "DivOperator":
				case "MulOperator":
				case "SubOperator":
				case "AddOperator": { // pops 2, push 1
					if (hasBottomUntil(2))
						return BOTTOM;
					
					TaintAbstractStack resultStack = clone();
					TaintElement opnd1 = resultStack.pop();
					TaintElement opnd2 = resultStack.pop();

					resultStack.push(TaintElement.semantics(opnd1, opnd2));
					return resultStack;
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
							resultStack.push(StackElement.NUMERIC_TOP);
						} else if (target.isTopNotJumpdest() || indexOfByte.isTopNotJumpdest()) {
							resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						} else {
							byte[] valueAsByteArray = target.getNumber().toByteArray();
							int intIndex = indexOfByte.getNumber().intValue();

							if (intIndex <= 0 || intIndex >= valueAsByteArray.length) {
								resultStackElement.lub(StackElement.ZERO);
							} else {
								int selectedByteAsInt = valueAsByteArray[intIndex];
								resultStackElement.lub(new StackElement(selectedByteAsInt));
							}

							resultStack.push(resultStackElement);
						}

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Sha3Operator": { // SHA3
					// At the moment, we do not handle SHA3

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "BalanceOperator": { // BALANCE
					// At the moment, we do not handle BALANCE

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CalldataloadOperator": { // CALLDATALOAD
					// At the moment, we do not handle CALLDATALOAD

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CalldatacopyOperator": { // CALLDATACOPY
					// At the moment, we do not handle CALLDATACOPY

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement memOffset = resultStack.pop();
						StackElement dataOffset = resultStack.pop();
						StackElement length = resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CodecopyOperator": { // CODECOPY
					// At the moment, we do not handle CODECOPY

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement memOffset = resultStack.pop();
						StackElement dataOffset = resultStack.pop();
						StackElement length = resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ExtcodesizeOperator": { // EXTCODESIZE
					// At the moment, we do not handle EXTCODESIZE

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ExtcodecopyOperator": { // EXTCODECOPY
					// At the moment, we do not handle EXTCODECOPY

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement address = resultStack.pop();
						StackElement memOffset = resultStack.pop();
						StackElement dataOffset = resultStack.pop();
						StackElement length = resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ReturndatacopyOperator": { // RETURNDATACOPY
					// At the moment, we do not handle RETURNDATACOPY

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement memOffset = resultStack.pop();
						StackElement dataOffset = resultStack.pop();
						StackElement length = resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ExtcodehashOperator": { // EXTCODEHASH
					// At the moment, we do not handle EXTCODEHASH

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "BlockhashOperator": { // BLOCKHASH
					// At the moment, we do not handle BLOCKHASH

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
						return new EVMAbstractState(result, memory, storage, mu_i);
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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MloadOperator": { // MLOAD

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();

						StackElement offset = resultStack.pop();

						if (mu_i.equals(StackElement.ZERO)) {
							// This is an error. We cannot read from memory if
							// there is no active words saved
							resultStack.push(StackElement.ZERO);
						} else if (offset.isTop()) {
							resultStack.push(StackElement.NUMERIC_TOP);
						} else if (offset.isTopNotJumpdest()) {
							resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						} else {
							StackElement mload = offset.mload(memory);
							if (mload.isBottom())
								continue;
							resultStack.push(mload);
						}

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "MstoreOperator": { // MSTORE

					Memory memoryResult = memory;
					StackElement new_mu_i = mu_i;

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack stackResult = stack.clone();

						StackElement offset = stackResult.pop();
						StackElement value = stackResult.pop();

						if (offset.isTop()) {
							new_mu_i = mu_i;
							memoryResult = memory;
						} else {
							StackElement current_mu_i_lub = StackElement.BOTTOM;

							Number thirtyTwo = new Number(32);
							Number current_mu_i = offset.getNumber().add(thirtyTwo)
									.divide(thirtyTwo);

							memoryResult = memory.putState(offset.getNumber(), value);

							current_mu_i_lub = current_mu_i_lub.lub(new StackElement(current_mu_i));

							new_mu_i = current_mu_i_lub;
						}
						result.add(stackResult);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memoryResult, storage, new_mu_i);
				}
				case "Mstore8Operator": { // MSTORE8

					Memory memoryResult = memory;
					StackElement new_mu_i = mu_i;

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack stackResult = stack.clone();

						StackElement offset = stackResult.pop();
						StackElement value = stackResult.pop();

						if (offset.isTop()) {
							new_mu_i = mu_i;
							memoryResult = memory;
						} else {
							StackElement current_mu_i_lub = StackElement.BOTTOM;

							Number current_mu_i = offset.getNumber().add(new Number(1))
									.divide(new Number(32));

							memoryResult = memory.putState(offset.getNumber(),
									value.mod(new StackElement(new Number(256))));
							current_mu_i_lub = current_mu_i_lub.lub(new StackElement(current_mu_i));

							new_mu_i = current_mu_i_lub;
						}
						result.add(stackResult);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memoryResult, storage, new_mu_i);
				}
				case "SloadOperator": { // SLOAD

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement key = resultStack.pop();
						Memory storageCopy = storage.clone();

						StackElement valueToPush = StackElement.BOTTOM;
						if (key.isTop() || key.isTopNotJumpdest())
							valueToPush = StackElement.NUMERIC_TOP;
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
									valueToPush = StackElement.NUMERIC_TOP;
							}
						}

						resultStack.push(valueToPush);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "SstoreOperator": { // SSTORE

					Memory storageResult = storage.bottom();

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement key = resultStack.pop();
						StackElement value = resultStack.pop();

						Memory storageCopy = storage.clone();

						if (!(key.isTopNumeric() || key.isTopNotJumpdest()))
							storageResult = storageCopy.putState(key.getNumber(), value);

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storageResult, mu_i);
				}
				case "Dup1Operator": { // DUP1

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(1))
							continue;
						AbstractStack resultStack = dupX(1, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup2Operator": { // DUP2

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = dupX(2, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup3Operator": { // DUP3

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = dupX(3, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup4Operator": { // DUP4

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = dupX(4, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup5Operator": { // DUP5

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(5))
							continue;
						AbstractStack resultStack = dupX(5, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup6Operator": { // DUP6

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = dupX(6, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup7Operator": { // DUP7

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = dupX(7, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup8Operator": { // DUP8

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(8))
							continue;
						AbstractStack resultStack = dupX(8, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup9Operator": { // DUP9

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(9))
							continue;
						AbstractStack resultStack = dupX(9, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup10Operator": { // DUP10

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(10))
							continue;
						AbstractStack resultStack = dupX(10, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup11Operator": { // DUP11

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(11))
							continue;
						AbstractStack resultStack = dupX(11, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup12Operator": { // DUP12

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(12))
							continue;
						AbstractStack resultStack = dupX(12, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup13Operator": { // DUP13

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(13))
							continue;
						AbstractStack resultStack = dupX(13, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup14Operator": { // DUP14

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(14))
							continue;
						AbstractStack resultStack = dupX(14, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup15Operator": { // DUP15

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(15))
							continue;
						AbstractStack resultStack = dupX(15, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Dup16Operator": { // DUP16

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(16))
							continue;
						AbstractStack resultStack = dupX(16, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap1Operator": { // SWAP1

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(2))
							continue;
						AbstractStack resultStack = swapX(1, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap2Operator": { // SWAP2

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = swapX(2, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap3Operator": { // SWAP3

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = swapX(3, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap4Operator": { // SWAP4

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(5))
							continue;
						AbstractStack resultStack = swapX(4, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap5Operator": { // SWAP5

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = swapX(5, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap6Operator": { // SWAP6

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = swapX(6, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap7Operator": { // SWAP7

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(8))
							continue;
						AbstractStack resultStack = swapX(7, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap8Operator": { // SWAP8

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(9))
							continue;
						AbstractStack resultStack = swapX(8, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap9Operator": { // SWAP9

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(10))
							continue;
						AbstractStack resultStack = swapX(9, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap10Operator": { // SWAP10

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(11))
							continue;
						AbstractStack resultStack = swapX(10, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap11Operator": { // SWAP11

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(12))
							continue;
						AbstractStack resultStack = swapX(11, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap12Operator": { // SWAP12

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(13))
							continue;
						AbstractStack resultStack = swapX(12, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap13Operator": { // SWAP13

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(14))
							continue;
						AbstractStack resultStack = swapX(13, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap14Operator": { // SWAP14

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(15))
							continue;
						AbstractStack resultStack = swapX(14, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap15Operator": { // SWAP15

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(16))
							continue;
						AbstractStack resultStack = swapX(15, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Swap16Operator": { // SWAP16

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(17))
							continue;
						AbstractStack resultStack = swapX(16, stack.clone());
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log0Operator": { // LOG0
					// At the moment, we do not handle LOG0

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log1Operator": { // LOG1
					// At the moment, we do not handle LOG1

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log2Operator": { // LOG2
					// At the moment, we do not handle LOG2

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();
						resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log3Operator": { // LOG3
					// At the moment, we do not handle LOG3

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(5))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();
						resultStack.pop();
						resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Log4Operator": { // LOG4
					// At the moment, we do not handle LOG4

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();
						resultStack.pop();
						resultStack.pop();
						resultStack.pop();
						resultStack.pop();

						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CreateOperator": { // CREATE
					// At the moment, we do not handle CREATE

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(3))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement value = resultStack.pop();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "Create2Operator": { // CREATE2
					// At the moment, we do not handle CREATE2

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(4))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement value = resultStack.pop();
						StackElement offset = resultStack.pop();
						StackElement length = resultStack.pop();
						StackElement salt = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CallOperator": { // CALL
					// At the moment, we do not handle CALL

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement gas = resultStack.pop();
						StackElement to = resultStack.pop();
						StackElement value = resultStack.pop();
						StackElement inOffset = resultStack.pop();
						StackElement inLength = resultStack.pop();
						StackElement outOffset = resultStack.pop();
						StackElement outLength = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "CallcodeOperator": { // CALLCODE
					// At the moment, we do not handle CALLCODE

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(7))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement gas = resultStack.pop();
						StackElement to = resultStack.pop();
						StackElement value = resultStack.pop();
						StackElement inOffset = resultStack.pop();
						StackElement inLength = resultStack.pop();
						StackElement outOffset = resultStack.pop();
						StackElement outLength = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "ReturnOperator": { // RETURN
					// At the moment, we do not handle RETURN

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "DelegatecallOperator": { // DELEGATECALL
					// At the moment, we do not handle DELEGATECALL

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement gas = resultStack.pop();
						StackElement to = resultStack.pop();
						StackElement inOffset = resultStack.pop();
						StackElement inLength = resultStack.pop();
						StackElement outOffset = resultStack.pop();
						StackElement outLength = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "StaticcallOperator": { // STATICCALL
					// At the moment, we do not handle STATICCALL

					for (AbstractStack stack : stacks) {
						if (stack.hasBottomUntil(6))
							continue;
						AbstractStack resultStack = stack.clone();
						StackElement gas = resultStack.pop();
						StackElement to = resultStack.pop();
						StackElement inOffset = resultStack.pop();
						StackElement inLength = resultStack.pop();
						StackElement outOffset = resultStack.pop();
						StackElement outLength = resultStack.pop();

						resultStack.push(StackElement.NOT_JUMPDEST_TOP);
						result.add(resultStack);
					}

					if (result.isEmpty())
						return BOTTOM;
					else
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "RevertOperator": { // REVERT
					// At the moment, we do not handle REVERT

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				case "InvalidOperator": { // INVALID
					return this;
				}
				case "SelfdestructOperator": { // SELFDESTRUCT
					// At the moment, we do not handle SELFDESTRUCT

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
						return new EVMAbstractState(result, memory, storage, mu_i);
				}
				}
			}
		}

		if (!(expression instanceof Skip))
			throw new SemanticException("Reachable just with the skip node");

		return top();
	}

	@Override
	public TaintAbstractStack assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest,
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
	public TaintAbstractStack forgetIdentifier(Identifier id) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
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
	public TaintAbstractStack pushScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack popScope(ScopeToken token) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public TaintAbstractStack top() {
		return TOP;
	}

	@Override
	public TaintAbstractStack bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractStack glbAux(TaintAbstractStack other) throws SemanticException {
		ArrayList<TaintElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<TaintElement> thisIterator = this.stack.iterator();
		Iterator<TaintElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			TaintElement thisElement = thisIterator.next();
			TaintElement otherElement = otherIterator.next();
			result.add(thisElement.glb(otherElement));
		}

		return new TaintAbstractStack(result);
	}

	@Override
	public TaintAbstractStack lubAux(TaintAbstractStack other) throws SemanticException {
		ArrayList<TaintElement> result = new ArrayList<>(STACK_LIMIT);

		Iterator<TaintElement> thisIterator = this.stack.iterator();
		Iterator<TaintElement> otherIterator = other.stack.iterator();

		while (thisIterator.hasNext() && otherIterator.hasNext()) {
			TaintElement thisElement = thisIterator.next();
			TaintElement otherElement = otherIterator.next();
			result.add(thisElement.lub(otherElement));
		}

		return new TaintAbstractStack(result);
	}

	@Override
	public boolean lessOrEqualAux(TaintAbstractStack other) throws SemanticException {
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
	public TaintAbstractStack clone() {
		if (isBottom() || isTop())
			return this;
		return new TaintAbstractStack(new ArrayList<>(stack));
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		TaintAbstractStack other = (TaintAbstractStack) obj;
		return java.util.Objects.equals(stack, other.stack);
	}

	@Override
	public int hashCode() {
		return java.util.Objects.hash(stack);
	}
}
