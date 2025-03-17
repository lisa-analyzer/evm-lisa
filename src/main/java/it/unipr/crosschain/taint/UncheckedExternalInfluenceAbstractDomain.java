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
 * external influences in smart contracts. It extends TaintAbstractDomain to
 * track whether values derived from external sources (msg.sender, callvalue,
 * etc.) influence the contract's state without validation.
 * <p>
 * <b>Purpose:</b>
 * </p>
 * <ul>
 * <li>Identifies operations that introduce tainted values from external
 * input.</li>
 * <li>Tracks symbolic execution to determine if tainted values propagate to
 * SSTORE.</li>
 * <li>Helps in detecting vulnerabilities where external inputs modify contract
 * state without verification.</li>
 * </ul>
 *
 * @see TaintAbstractDomain
 */
public class UncheckedExternalInfluenceAbstractDomain extends TaintAbstractDomain {

	private static final UncheckedExternalInfluenceAbstractDomain TOP = new UncheckedExternalInfluenceAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)),
			TaintElement.CLEAN);
	private static final UncheckedExternalInfluenceAbstractDomain BOTTOM = new UncheckedExternalInfluenceAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public UncheckedExternalInfluenceAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected UncheckedExternalInfluenceAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public Set<Operator> getTaintedOpcode() {
		Set<Operator> taintedOpcode = new HashSet<>();
		taintedOpcode.add(CalldataloadOperator.INSTANCE);
		taintedOpcode.add(CallvalueOperator.INSTANCE);
		taintedOpcode.add(CallerOperator.INSTANCE);
		taintedOpcode.add(OriginOperator.INSTANCE);
		return taintedOpcode;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public UncheckedExternalInfluenceAbstractDomain top() {
		return TOP;
	}

	@Override
	public UncheckedExternalInfluenceAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory) {
		return new UncheckedExternalInfluenceAbstractDomain(list, memory);
	}
}
