package it.unipr.analysis.taint;

import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Origin;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class TxOriginAbstractDomain extends TaintAbstractDomain {

	private static final TxOriginAbstractDomain TOP = new TxOriginAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final TxOriginAbstractDomain BOTTOM = new TxOriginAbstractDomain(null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public TxOriginAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param circularArray the stack of values
	 */
	protected TxOriginAbstractDomain(TaintElement[] circularArray, TaintElement memory) {
		this(circularArray, memory, null);
	}

	protected TxOriginAbstractDomain(TaintElement[] circularArray, TaintElement memory, EVMCFG cfg) {
		super(circularArray, memory, cfg);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Origin;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public TxOriginAbstractDomain top() {
		return TOP;
	}

	@Override
	public TxOriginAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
		return mk(array, memory, null);
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory, EVMCFG cfg) {
		return new TxOriginAbstractDomain(array, memory, cfg);
	}
}
