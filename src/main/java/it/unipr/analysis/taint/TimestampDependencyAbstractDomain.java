package it.unipr.analysis.taint;

import it.unipr.analysis.StackElement;
import it.unipr.analysis.operator.BalanceOperator;
import it.unipr.analysis.operator.BlockhashOperator;
import it.unipr.analysis.operator.DifficultyOperator;
import it.unipr.analysis.operator.TimestampOperator;
import it.unive.lisa.symbolic.value.Operator;

import java.util.*;

public class TimestampDependencyAbstractDomain extends TaintAbstractDomain {
	private static final TimestampDependencyAbstractDomain TOP = new TimestampDependencyAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final TimestampDependencyAbstractDomain BOTTOM =
			new TimestampDependencyAbstractDomain(null, TaintElement.BOTTOM);


	private static TaintElement[] createFilledArray(int size, TaintElement element) {
		TaintElement[] array = new TaintElement[size];
		Arrays.fill(array, element);
		return array;
	}

	/**
	 * Builds an initial symbolic stack.
	 */
	public TimestampDependencyAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param circularArray the stack of values
	 */
	protected TimestampDependencyAbstractDomain(TaintElement[] circularArray, TaintElement memory) {
		super(circularArray, memory);
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
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
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
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
		return new TimestampDependencyAbstractDomain(array, memory);
	}

}