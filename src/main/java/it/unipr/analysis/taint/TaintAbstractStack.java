package it.unipr.analysis.taint;

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
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.function.Predicate;

public class TaintAbstractStack implements ValueDomain<TaintAbstractStack>, BaseLattice<TaintAbstractStack> {

	private static int STACK_LIMIT = 32;
	private static final TaintAbstractStack TOP = new TaintAbstractStack(
			new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)));
	private static final TaintAbstractStack BOTTOM = new TaintAbstractStack(null);

	private final ArrayList<TaintElement> stack;

	
	/**
	 * Builds an initial symbolic stack.
	 */
	public TaintAbstractStack() {
		this.stack = new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM));
	}

	/**
	 * Builds a taint abstract stack starting from a given stack.
	 *
	 * @param stack the stack of values
	 */
	private TaintAbstractStack(ArrayList<TaintElement> stack) {
		this.stack = stack;
	}

	@Override
	public TaintAbstractStack assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle)
			throws SemanticException {
		// nothing to do here
		return this;
	}

	@SuppressWarnings("unused")
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
				case "TimestampOperator":
				case "OriginOperator": {
					TaintAbstractStack resultStack = clone();
					resultStack.push(TaintElement.TAINT);
					return resultStack;
				}
				case "CodesizeOperator":
				case "GaspriceOperator":
				case "ReturndatasizeOperator":
				case "CoinbaseOperator":
				case "NumberOperator":
				case "DifficultyOperator": /**/
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
					TaintAbstractStack resultStack = clone();
					resultStack.push(TaintElement.CLEAN);
					resultStack.toString();
					return resultStack;
				}

				/*
				 * case "JumpdestOperator": { // JUMPDEST return this; } //
				 * Above, operators that do not perform pop() // Below,
				 * operators that perform pop operation on the stack case
				 * "JumpOperator": { // JUMP for (AbstractStack stack : stacks)
				 * { if (stack.hasBottomUntil(1)) continue; AbstractStack
				 * resultStack = stack.clone(); StackElement jmpDest =
				 * resultStack.pop(); if (((EVMCFG)
				 * pp.getCFG()).getAllPushedJumps().contains(pp) &&
				 * jmpDest.isTop()) continue; if (jmpDest.isBottom() ||
				 * jmpDest.isTopNotJumpdest()) continue; if (((EVMCFG)
				 * pp.getCFG()).getAllJumpdestLocations().contains(jmpDest.
				 * getNumber()) || jmpDest.isTop()) result.add(resultStack); }
				 * if (result.isEmpty()) return BOTTOM; else return new
				 * EVMAbstractState(result, memory, storage, mu_i); } case
				 * "JumpiOperator": { // JUMPI for (AbstractStack stack :
				 * stacks) { if (stack.hasBottomUntil(2)) continue;
				 * AbstractStack resultStack = stack.clone(); StackElement
				 * jmpDest = resultStack.pop(); StackElement cond =
				 * resultStack.pop(); if (jmpDest.isBottom() || cond.isBottom()
				 * || jmpDest.isTopNotJumpdest()) continue; if (((EVMCFG)
				 * pp.getCFG()).getAllJumpdestLocations().contains(jmpDest.
				 * getNumber()) || jmpDest.isTop()) result.add(resultStack); }
				 * if (result.isEmpty()) return BOTTOM; else return new
				 * EVMAbstractState(result, memory, storage, mu_i); }
				 */

				case "BalanceOperator":
				case "NotOperator":
				case "CalldataloadOperator":
				case "CalldatacopyOperator":
				case "MloadOperator":
				case "SloadOperator":
				case "IszeroOperator": { // pop 1, push 1
					if (hasBottomUntil(1))
						return BOTTOM;

					TaintAbstractStack resultStack = clone();
					TaintElement opnd1 = resultStack.pop();

					resultStack.push(TaintElement.semantics(opnd1));
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
						return BOTTOM;

					TaintAbstractStack resultStack = clone();
					TaintElement opnd1 = resultStack.pop();
					TaintElement opnd2 = resultStack.pop();

					resultStack.push(TaintElement.semantics(opnd1, opnd2));
					return resultStack;
				}

				case "MulmodOperator":
				case "AddmodOperator": { // pops 3, push 1
					if (hasBottomUntil(3))
						return BOTTOM;

					TaintAbstractStack resultStack = clone();
					TaintElement opnd1 = resultStack.pop();
					TaintElement opnd2 = resultStack.pop();
					TaintElement opnd3 = resultStack.pop();

					resultStack.push(TaintElement.semantics(opnd1, opnd2, opnd3));
					return resultStack;
				}

				case "PopOperator": { // POP
					if (hasBottomUntil(1))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}

				/*
				 * case "MstoreOperator": { // MSTORE Memory memoryResult =
				 * memory; StackElement new_mu_i = mu_i; for (AbstractStack
				 * stack : stacks) { if (stack.hasBottomUntil(2)) continue;
				 * AbstractStack stackResult = stack.clone(); StackElement
				 * offset = stackResult.pop(); StackElement value =
				 * stackResult.pop(); if (offset.isTop()) { new_mu_i = mu_i;
				 * memoryResult = memory; } else { StackElement current_mu_i_lub
				 * = StackElement.BOTTOM; Number thirtyTwo = new Number(32);
				 * Number current_mu_i = offset.getNumber().add(thirtyTwo)
				 * .divide(thirtyTwo); memoryResult =
				 * memory.putState(offset.getNumber(), value); current_mu_i_lub
				 * = current_mu_i_lub.lub(new StackElement(current_mu_i));
				 * new_mu_i = current_mu_i_lub; } result.add(stackResult); } if
				 * (result.isEmpty()) return BOTTOM; else return new
				 * EVMAbstractState(result, memoryResult, storage, new_mu_i); }
				 * case "Mstore8Operator": { // MSTORE8 Memory memoryResult =
				 * memory; StackElement new_mu_i = mu_i; for (AbstractStack
				 * stack : stacks) { if (stack.hasBottomUntil(2)) continue;
				 * AbstractStack stackResult = stack.clone(); StackElement
				 * offset = stackResult.pop(); StackElement value =
				 * stackResult.pop(); if (offset.isTop()) { new_mu_i = mu_i;
				 * memoryResult = memory; } else { StackElement current_mu_i_lub
				 * = StackElement.BOTTOM; Number current_mu_i =
				 * offset.getNumber().add(new Number(1)) .divide(new
				 * Number(32)); memoryResult =
				 * memory.putState(offset.getNumber(), value.mod(new
				 * StackElement(new Number(256)))); current_mu_i_lub =
				 * current_mu_i_lub.lub(new StackElement(current_mu_i));
				 * new_mu_i = current_mu_i_lub; } result.add(stackResult); } if
				 * (result.isEmpty()) return BOTTOM; else return new
				 * EVMAbstractState(result, memoryResult, storage, new_mu_i); }
				 * case "SstoreOperator": { // SSTORE Memory storageResult =
				 * storage.bottom(); for (AbstractStack stack : stacks) { if
				 * (stack.hasBottomUntil(2)) continue; AbstractStack resultStack
				 * = stack.clone(); StackElement key = resultStack.pop();
				 * StackElement value = resultStack.pop(); Memory storageCopy =
				 * storage.clone(); if (!(key.isTopNumeric() ||
				 * key.isTopNotJumpdest())) storageResult =
				 * storageCopy.putState(key.getNumber(), value);
				 * result.add(resultStack); } if (result.isEmpty()) return
				 * BOTTOM; else return new EVMAbstractState(result, memory,
				 * storageResult, mu_i); }
				 */
				case "Dup1Operator": { // DUP1
					if (hasBottomUntil(1))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(1, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup2Operator": { // DUP2
					if (hasBottomUntil(2))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(2, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup3Operator": { // DUP3
					if (hasBottomUntil(3))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(3, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup4Operator": { // DUP4
					if (hasBottomUntil(4))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(4, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup5Operator": { // DUP5
					if (hasBottomUntil(5))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(5, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup6Operator": { // DUP6
					if (hasBottomUntil(6))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(6, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup7Operator": { // DUP7
					if (hasBottomUntil(7))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(7, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup8Operator": { // DUP8
					if (hasBottomUntil(8))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(8, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup9Operator": { // DUP9
					if (hasBottomUntil(9))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(9, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup10Operator": { // DUP10
					if (hasBottomUntil(10))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(10, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup11Operator": { // DUP11
					if (hasBottomUntil(11))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(11, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup12Operator": { // DUP12
					if (hasBottomUntil(12))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(12, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup13Operator": { // DUP13
					if (hasBottomUntil(13))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(13, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup14Operator": { // DUP14
					if (hasBottomUntil(14))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(14, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup15Operator": { // DUP15
					if (hasBottomUntil(15))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(15, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Dup16Operator": { // DUP16
					if (hasBottomUntil(16))
						return BOTTOM;
					TaintAbstractStack resultStack = dupX(16, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap1Operator": { // SWAP1
					if (hasBottomUntil(1))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(1, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap2Operator": { // SWAP2
					if (hasBottomUntil(2))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(2, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap3Operator": { // SWAP3
					if (hasBottomUntil(3))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(3, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap4Operator": { // SWAP4
					if (hasBottomUntil(4))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(4, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap5Operator": { // SWAP5
					if (hasBottomUntil(5))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(5, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap6Operator": { // SWAP6
					if (hasBottomUntil(6))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(6, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap7Operator": { // SWAP7
					if (hasBottomUntil(7))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(7, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap8Operator": { // SWAP8
					if (hasBottomUntil(8))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(8, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap9Operator": { // SWAP9
					if (hasBottomUntil(9))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(9, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap10Operator": { // SWAP10
					if (hasBottomUntil(10))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(10, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap11Operator": { // SWAP11
					if (hasBottomUntil(11))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(11, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap12Operator": { // SWAP12
					if (hasBottomUntil(12))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(12, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap13Operator": { // SWAP13
					if (hasBottomUntil(13))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(13, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap14Operator": { // SWAP14
					if (hasBottomUntil(14))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(14, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap15Operator": { // SWAP15
					if (hasBottomUntil(15))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(15, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Swap16Operator": { // SWAP16
					if (hasBottomUntil(16))
						return BOTTOM;
					TaintAbstractStack resultStack = swapX(16, clone());

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Log0Operator": { // LOG0
					// At the moment, we do not handle LOG0
					if (hasBottomUntil(2))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Log1Operator": { // LOG1
					// At the moment, we do not handle LOG1
					if (hasBottomUntil(3))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Log2Operator": { // LOG2
					// At the moment, we do not handle LOG2
					if (hasBottomUntil(4))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Log3Operator": { // LOG3
					// At the moment, we do not handle LOG3
					if (hasBottomUntil(5))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();
					resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Log4Operator": { // LOG4
					// At the moment, we do not handle LOG4
					if (hasBottomUntil(6))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					resultStack.pop();
					resultStack.pop();
					resultStack.pop();
					resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "CreateOperator": { // CREATE
					// At the moment, we do not handle CREATE
					if (hasBottomUntil(3))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement value = resultStack.pop();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "Create2Operator": { // CREATE2
					// At the moment, we do not handle CREATE2
					if (hasBottomUntil(4))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement value = resultStack.pop();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();
					TaintElement salt = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "CallOperator": { // CALL
					// At the moment, we do not handle CALL
					if (hasBottomUntil(7))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement gas = resultStack.pop();
					TaintElement to = resultStack.pop();
					TaintElement value = resultStack.pop();
					TaintElement inOffset = resultStack.pop();
					TaintElement inLength = resultStack.pop();
					TaintElement outOffset = resultStack.pop();
					TaintElement outLength = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "CallcodeOperator": { // CALLCODE
					// At the moment, we do not handle CALLCODE
					if (hasBottomUntil(7))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement gas = resultStack.pop();
					TaintElement to = resultStack.pop();
					TaintElement value = resultStack.pop();
					TaintElement inOffset = resultStack.pop();
					TaintElement inLength = resultStack.pop();
					TaintElement outOffset = resultStack.pop();
					TaintElement outLength = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "ReturnOperator": { // RETURN
					// At the moment, we do not handle RETURN
					if (hasBottomUntil(2))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "DelegatecallOperator": { // DELEGATECALL
					// At the moment, we do not handle DELEGATECALL
					if (hasBottomUntil(6))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement gas = resultStack.pop();
					TaintElement to = resultStack.pop();
					TaintElement inOffset = resultStack.pop();
					TaintElement inLength = resultStack.pop();
					TaintElement outOffset = resultStack.pop();
					TaintElement outLength = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "StaticcallOperator": { // STATICCALL
					// At the moment, we do not handle STATICCALL
					if (hasBottomUntil(6))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement gas = resultStack.pop();
					TaintElement to = resultStack.pop();
					TaintElement inOffset = resultStack.pop();
					TaintElement inLength = resultStack.pop();
					TaintElement outOffset = resultStack.pop();
					TaintElement outLength = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "RevertOperator": { // REVERT
					// At the moment, we do not handle REVERT
					if (hasBottomUntil(2))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement offset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "InvalidOperator": { // INVALID
					return this;
				}
				case "SelfdestructOperator": { // SELFDESTRUCT
					// At the moment, we do not handle SELFDESTRUCT
					if (hasBottomUntil(1))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement recipient = resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "CodecopyOperator": { // CODECOPY
					// At the moment, we do not handle CODECOPY
					if (hasBottomUntil(3))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement memOffset = resultStack.pop();
					TaintElement dataOffset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "ExtcodesizeOperator": { // EXTCODESIZE
					// At the moment, we do not handle EXTCODESIZE
					if (hasBottomUntil(1))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement address = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "ExtcodecopyOperator": { // EXTCODECOPY
					// At the moment, we do not handle EXTCODECOPY
					if (hasBottomUntil(4))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement address = resultStack.pop();
					TaintElement memOffset = resultStack.pop();
					TaintElement dataOffset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "ReturndatacopyOperator": { // RETURNDATACOPY
					// At the moment, we do not handle RETURNDATACOPY
					if (hasBottomUntil(3))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement memOffset = resultStack.pop();
					TaintElement dataOffset = resultStack.pop();
					TaintElement length = resultStack.pop();

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "ExtcodehashOperator": { // EXTCODEHASH
					// At the moment, we do not handle EXTCODEHASH
					if (hasBottomUntil(1))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement address = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);
					resultStack.push(TaintElement.TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				case "BlockhashOperator": { // BLOCKHASH
					// At the moment, we do not handle BLOCKHASH
					if (hasBottomUntil(1))
						return BOTTOM;
					TaintAbstractStack resultStack = clone();
					TaintElement blockNumber = resultStack.pop();

					// resultStack.push(StackElement.NOT_JUMPDEST_TOP);

					if (resultStack.isEmpty())
						return BOTTOM;
					else
						return resultStack;
				}
				}
			}
		}

		if (!(expression instanceof Skip))
			throw new SemanticException("Reachable just with the skip node");

		return top();
	}

	private TaintAbstractStack swapX(int x, TaintAbstractStack stack) {
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

		return new TaintAbstractStack(result);
	}

	private TaintAbstractStack dupX(int x, TaintAbstractStack stack) {
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

		return new TaintAbstractStack(result);
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
	public String toString() {
		if (isBottom())
			return Lattice.BOTTOM_STRING;
		else if (isTop())
			return Lattice.TOP_STRING;

		return stack.toString();
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
		if (isBottom())
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
