package it.unipr.analysis.taint;

import it.unipr.cfg.Origin;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class TxOriginAbstractDomain extends TaintAbstractDomain {

	private static final TxOriginAbstractDomain TOP = new TxOriginAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), 0, 0, TaintElement.CLEAN);
	private static final TxOriginAbstractDomain BOTTOM = new TxOriginAbstractDomain(null, 0, 0, TaintElement.BOTTOM);

	/**
	 * Constructs a new {@code TxOriginAbstractDomain} with an empty (BOTTOM)
	 * stack, zero head/tail, and CLEAN memory state.
	 */
	public TxOriginAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), 0, 0, TaintElement.CLEAN);
	}

	/**
	 * Constructs a new {@code TxOriginAbstractDomain} with the given stack
	 * state, stack pointers, and memory state.
	 *
	 * @param stack  the stack array containing taint information for each
	 *                   element
	 * @param head   the current head pointer of the stack
	 * @param tail   the current tail pointer of the stack
	 * @param memory the taint state of the memory
	 */
	protected TxOriginAbstractDomain(TaintElement[] stack, int head, int tail, TaintElement memory) {
		super(stack, head, tail, memory);
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
	public TaintAbstractDomain mk(TaintElement[] stack, int head, int tail, TaintElement memory) {
		return new TxOriginAbstractDomain(stack, head, tail, memory);
	}
}
