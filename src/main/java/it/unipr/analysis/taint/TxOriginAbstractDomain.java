package it.unipr.analysis.taint;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Set;

import it.unipr.analysis.operator.OriginOperator;
import it.unive.lisa.symbolic.value.Operator;

public class TxOriginAbstractDomain extends TaintAbstractDomain {

	private static final TxOriginAbstractDomain TOP = new TxOriginAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN);
	private static final TxOriginAbstractDomain BOTTOM = new TxOriginAbstractDomain(null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public TxOriginAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected TxOriginAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public Set<Operator> getTaintedOpcode() {
		return Collections.singleton(OriginOperator.INSTANCE);
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
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory) {
		return new TxOriginAbstractDomain(list, memory);
	}
}
