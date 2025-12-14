package it.unipr.analysis.taint;

import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class RandomnessDependencyAbstractDomain extends TaintAbstractDomain {

	private static final RandomnessDependencyAbstractDomain TOP = new RandomnessDependencyAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), 0, 0, TaintElement.CLEAN);
	private static final RandomnessDependencyAbstractDomain BOTTOM = new RandomnessDependencyAbstractDomain(null, 0, 0,
			TaintElement.BOTTOM);

	/**
	 * Constructs a new {@code RandomnessDependencyAbstractDomain} with an empty
	 * (BOTTOM) stack, zero head/tail, and CLEAN memory state.
	 */
	public RandomnessDependencyAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), 0, 0, TaintElement.CLEAN);
	}

	/**
	 * Constructs a new {@code RandomnessDependencyAbstractDomain} with the
	 * given stack state, stack pointers, and memory state.
	 *
	 * @param stack  the stack array containing taint information for each
	 *                   element
	 * @param head   the current head pointer of the stack
	 * @param tail   the current tail pointer of the stack
	 * @param memory the taint state of the memory
	 */
	protected RandomnessDependencyAbstractDomain(TaintElement[] stack, int head, int tail, TaintElement memory) {
		super(stack, head, tail, memory);
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
	public TaintAbstractDomain mk(TaintElement[] stack, int head, int tail, TaintElement memory) {
		return new RandomnessDependencyAbstractDomain(stack, head, tail, memory);
	}
}