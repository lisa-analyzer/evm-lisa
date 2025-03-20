package it.unipr.analysis.taint;

import it.unipr.analysis.operator.OriginOperator;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Set;

public class TxOriginAbstractDomain extends TaintAbstractDomain {

	private static final TxOriginAbstractDomain TOP = new TxOriginAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final TxOriginAbstractDomain BOTTOM =
			new TxOriginAbstractDomain(null, TaintElement.BOTTOM);


	private static TaintElement[] createFilledArray(int size, TaintElement element) {
		TaintElement[] array = new TaintElement[size];
		Arrays.fill(array, element);
		return array;
	}


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
		super(circularArray, memory);
	}

	@Override
	public Set<Operator> getTaintedOpcode() {
		return Collections.singleton(OriginOperator.INSTANCE);
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
		return new TxOriginAbstractDomain(array, memory);
	}
}
