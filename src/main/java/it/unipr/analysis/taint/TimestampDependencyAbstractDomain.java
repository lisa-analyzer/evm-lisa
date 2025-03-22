package it.unipr.analysis.taint;

import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class TimestampDependencyAbstractDomain extends TaintAbstractDomain {
	private static final TimestampDependencyAbstractDomain TOP = new TimestampDependencyAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final TimestampDependencyAbstractDomain BOTTOM = new TimestampDependencyAbstractDomain(null,
			TaintElement.BOTTOM);

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
	 * @param stack the stack of values
	 */
	protected TimestampDependencyAbstractDomain(TaintElement[] stack, TaintElement memory) {
		this(stack, memory, null);
	}

	protected TimestampDependencyAbstractDomain(TaintElement[] stack, TaintElement memory, EVMCFG cfg) {
		super(stack, memory, cfg);
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
	public TimestampDependencyAbstractDomain top() {
		return TOP;
	}

	@Override
	public TimestampDependencyAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory) {
		return mk(stack, memory, null);
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory, EVMCFG cfg) {
		return new TimestampDependencyAbstractDomain(stack, memory, cfg);
	}

}