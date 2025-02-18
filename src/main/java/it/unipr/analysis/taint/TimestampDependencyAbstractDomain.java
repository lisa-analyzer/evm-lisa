package it.unipr.analysis.taint;

import it.unipr.analysis.operator.BalanceOperator;
import it.unipr.analysis.operator.BlockhashOperator;
import it.unipr.analysis.operator.DifficultyOperator;
import it.unipr.analysis.operator.TimestampOperator;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class TimestampDependencyAbstractDomain extends TaintAbstractDomain {
	private static final TimestampDependencyAbstractDomain TOP = new TimestampDependencyAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN);
	private static final TimestampDependencyAbstractDomain BOTTOM = new TimestampDependencyAbstractDomain(null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public TimestampDependencyAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected TimestampDependencyAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public Set<Operator> getTaintedOpcode() {
		Set<Operator> taintedOpcode = new HashSet<>();
		taintedOpcode.add(TimestampOperator.INSTANCE);
		taintedOpcode.add(BlockhashOperator.INSTANCE);
		taintedOpcode.add(DifficultyOperator.INSTANCE);
		taintedOpcode.add(BalanceOperator.INSTANCE);
		return taintedOpcode;
	}

	@Override
	public TimestampDependencyAbstractDomain top() {
		return TOP;
	}

	@Override
	public TimestampDependencyAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory) {
		return new TimestampDependencyAbstractDomain(list, memory);
	}

}