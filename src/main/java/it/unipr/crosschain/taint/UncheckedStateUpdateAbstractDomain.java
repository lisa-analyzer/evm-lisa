package it.unipr.crosschain.taint;

import it.unipr.analysis.operator.*;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * This abstract domain represents the taint analysis for detecting unchecked
 * state updates in smart contracts. It extends TaintAbstractDomain to track
 * whether values derived from external calls (CALL, DELEGATECALL, STATICCALL)
 * influence the contract's state without validation.
 * <p>
 * <b>Purpose:</b>
 * </p>
 * <ul>
 * <li>Identifies operations that introduce tainted values from external
 * contract calls.</li>
 * <li>Tracks symbolic execution to determine if tainted values propagate to
 * SSTORE.</li>
 * <li>Detects vulnerabilities where external calls modify the contract state
 * without verification.</li>
 * </ul>
 *
 * @see TaintAbstractDomain
 */
public class UncheckedStateUpdateAbstractDomain extends TaintAbstractDomain {

	private static final UncheckedStateUpdateAbstractDomain TOP = new UncheckedStateUpdateAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)),
			TaintElement.CLEAN);
	private static final UncheckedStateUpdateAbstractDomain BOTTOM = new UncheckedStateUpdateAbstractDomain(null,
			TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public UncheckedStateUpdateAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected UncheckedStateUpdateAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public Set<Operator> getTaintedOpcode() {
		Set<Operator> taintedOpcode = new HashSet<>();
		taintedOpcode.add(CallOperator.INSTANCE);
		taintedOpcode.add(DelegatecallOperator.INSTANCE);
		taintedOpcode.add(StaticcallOperator.INSTANCE);
		return taintedOpcode;
	}

	@Override
	public UncheckedStateUpdateAbstractDomain top() {
		return TOP;
	}

	@Override
	public UncheckedStateUpdateAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory) {
		return new UncheckedStateUpdateAbstractDomain(list, memory);
	}
}
