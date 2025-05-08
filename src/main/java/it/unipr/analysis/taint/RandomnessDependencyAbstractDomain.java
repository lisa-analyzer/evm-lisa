package it.unipr.analysis.taint;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import it.unipr.analysis.operator.BalanceOperator;
import it.unipr.analysis.operator.BlockhashOperator;
import it.unipr.analysis.operator.DifficultyOperator;
import it.unipr.analysis.operator.TimestampOperator;
import it.unive.lisa.symbolic.value.Operator;

public class RandomnessDependencyAbstractDomain extends TaintAbstractDomain {
	private static final RandomnessDependencyAbstractDomain TOP = new RandomnessDependencyAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final RandomnessDependencyAbstractDomain BOTTOM = new RandomnessDependencyAbstractDomain(null,
			TaintElement.BOTTOM);

	private static TaintElement[] createFilledArray(int size, TaintElement element) {
		TaintElement[] array = new TaintElement[size];
		Arrays.fill(array, element);
		return array;
	}
	
	/**
	 * Builds an initial symbolic stack.
	 */
	public RandomnessDependencyAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected RandomnessDependencyAbstractDomain(TaintElement[] stack, TaintElement memory) {
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
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public RandomnessDependencyAbstractDomain top() {
		return TOP;
	}

	@Override
	public RandomnessDependencyAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory) {
		return new RandomnessDependencyAbstractDomain(stack, memory);
	}

}