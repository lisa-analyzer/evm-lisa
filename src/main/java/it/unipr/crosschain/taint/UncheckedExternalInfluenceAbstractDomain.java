package it.unipr.crosschain.taint;

import it.unipr.analysis.operator.*;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
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
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final UncheckedExternalInfluenceAbstractDomain BOTTOM = new UncheckedExternalInfluenceAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public UncheckedExternalInfluenceAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	/**
	 * Constructs an instance of UncheckedExternalInfluenceAbstractDomain with a
	 * given stack and memory taint element.
	 *
	 * @param circularArray the stack of taint elements representing the
	 *                          symbolic execution stack
	 * @param memory        the taint element representing the memory taint
	 *                          status
	 */
	protected UncheckedExternalInfluenceAbstractDomain(TaintElement[] circularArray, TaintElement memory) {
		this(circularArray, memory, null);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param circularArray the stack of values
	 */
	protected UncheckedExternalInfluenceAbstractDomain(TaintElement[] circularArray, TaintElement memory, EVMCFG cfg) {
		super(circularArray, memory, cfg);
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
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
		return mk(array, memory, null);
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory, EVMCFG cfg) {
		return new UncheckedExternalInfluenceAbstractDomain(array, memory, cfg);
	}

	@Override
	public UncheckedExternalInfluenceAbstractDomain top() {
		return TOP;
	}

	@Override
	public UncheckedExternalInfluenceAbstractDomain bottom() {
		return BOTTOM;
	}

}
