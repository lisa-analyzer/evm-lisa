package it.unipr.crosschain.taint;

import it.unipr.analysis.operator.*;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Set;

/**
 * This abstract domain represents the taint analysis for detecting unchecked
 * external influences in smart contracts. It extends TaintAbstractDomain to
 * track whether values derived from external sources (msg.sender, callvalue,
 * etc.) influence the contract's state without validation. Analysis Process:
 * (i) Identifies operations that introduce tainted values from external input.
 * (ii) Tracks symbolic execution to determine if tainted values propagate to
 * SSTORE. (iii) Helps in detecting vulnerabilities where external inputs modify
 * contract state without verification.
 *
 * @see TaintAbstractDomain
 */
public class UncheckedExternalInfluenceAbstractDomain extends TaintAbstractDomain {

	private static final UncheckedExternalInfluenceAbstractDomain TOP = new UncheckedExternalInfluenceAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)),
			TaintElement.CLEAN,
			null);
	private static final UncheckedExternalInfluenceAbstractDomain BOTTOM = new UncheckedExternalInfluenceAbstractDomain(
			null,
			TaintElement.BOTTOM,
			null);

	/**
	 * Builds an initial symbolic stack.
	 */
	public UncheckedExternalInfluenceAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN, null);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected UncheckedExternalInfluenceAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory, EVMCFG cfg) {
		super(stack, memory, cfg);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Calldataload
				|| stmt instanceof Callvalue
				|| stmt instanceof Caller
				|| stmt instanceof Origin;
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
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory, EVMCFG cfg) {
		return new UncheckedExternalInfluenceAbstractDomain(list, memory, cfg);
	}
}
