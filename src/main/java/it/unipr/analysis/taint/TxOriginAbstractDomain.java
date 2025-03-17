package it.unipr.analysis.taint;

import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Origin;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Set;

public class TxOriginAbstractDomain extends TaintAbstractDomain {

	private static final TxOriginAbstractDomain TOP = new TxOriginAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT,
					TaintElement.BOTTOM)),
			TaintElement.CLEAN,
			null);
	private static final TxOriginAbstractDomain BOTTOM = new TxOriginAbstractDomain(
			null,
			TaintElement.BOTTOM,
			null);

	/**
	 * Builds an initial symbolic stack.
	 */
	public TxOriginAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN, null);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected TxOriginAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory, EVMCFG cfg) {
		super(stack, memory, cfg);
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
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory, EVMCFG cfg) {
		return new TxOriginAbstractDomain(list, memory, cfg);
	}
}
