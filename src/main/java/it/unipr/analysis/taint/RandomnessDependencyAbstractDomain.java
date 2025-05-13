package it.unipr.analysis.taint;

import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class RandomnessDependencyAbstractDomain extends TaintAbstractDomain {
	private static final RandomnessDependencyAbstractDomain TOP = new RandomnessDependencyAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final RandomnessDependencyAbstractDomain BOTTOM = new RandomnessDependencyAbstractDomain(null,
			TaintElement.BOTTOM);

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
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Timestamp
				|| stmt instanceof Blockhash
				|| stmt instanceof Difficulty
				|| stmt instanceof Balance;
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