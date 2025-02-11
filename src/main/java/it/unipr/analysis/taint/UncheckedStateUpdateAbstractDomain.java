package it.unipr.analysis.taint;

import it.unipr.analysis.operator.*;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class UncheckedStateUpdateAbstractDomain extends TaintAbstractDomain {

	private static final UncheckedStateUpdateAbstractDomain TOP = new UncheckedStateUpdateAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)));
	private static final UncheckedStateUpdateAbstractDomain BOTTOM = new UncheckedStateUpdateAbstractDomain(null);

	/**
	 * Builds an initial symbolic stack.
	 */
	public UncheckedStateUpdateAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)));
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected UncheckedStateUpdateAbstractDomain(ArrayList<TaintElement> stack) {
		super(stack);
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
	public TaintAbstractDomain mk(ArrayList<TaintElement> list) {
		return new UncheckedStateUpdateAbstractDomain(list);
	}
}
