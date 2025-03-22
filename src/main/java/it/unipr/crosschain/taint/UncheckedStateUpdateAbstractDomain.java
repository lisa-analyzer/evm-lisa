package it.unipr.crosschain.taint;

import it.unipr.analysis.operator.*;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.Call;
import it.unipr.cfg.Delegatecall;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Staticcall;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

/**
 * This abstract domain represents the taint analysis for detecting unchecked
 * state updates in smart contracts. It extends TaintAbstractDomain to track
 * whether values derived from external calls (CALL, DELEGATECALL, STATICCALL)
 * influence the contract's state without validation. Analysis Process: (i)
 * Identifies operations that introduce tainted values from external contract
 * calls. (ii) Tracks symbolic execution to determine if tainted values
 * propagate to SSTORE. (iii) Detects vulnerabilities where external calls
 * modify the contract state without verification.
 *
 * @see TaintAbstractDomain
 */
public class UncheckedStateUpdateAbstractDomain extends TaintAbstractDomain {

	private static final UncheckedStateUpdateAbstractDomain TOP = new UncheckedStateUpdateAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final UncheckedStateUpdateAbstractDomain BOTTOM = new UncheckedStateUpdateAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public UncheckedStateUpdateAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param circularArray the stack of values
	 */
	protected UncheckedStateUpdateAbstractDomain(TaintElement[] circularArray, TaintElement memory) {
		this(circularArray, memory, null);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param circularArray the stack of values
	 */
	protected UncheckedStateUpdateAbstractDomain(TaintElement[] circularArray, TaintElement memory, EVMCFG cfg) {
		super(circularArray, memory, cfg);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Call
				|| stmt instanceof Delegatecall
				|| stmt instanceof Staticcall;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
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
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
		return mk(array, memory, null);
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory, EVMCFG cfg) {
		return new UncheckedStateUpdateAbstractDomain(array, memory, cfg);
	}
}
