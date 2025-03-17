package it.unipr.analysis.taint;

import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Set;

public class TimestampDependencyAbstractDomain extends TaintAbstractDomain {
	private static final TimestampDependencyAbstractDomain TOP = new TimestampDependencyAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)),
			TaintElement.CLEAN,
			null);
	private static final TimestampDependencyAbstractDomain BOTTOM = new TimestampDependencyAbstractDomain(
			null,
			TaintElement.BOTTOM,
			null);

	/**
	 * Builds an initial symbolic stack.
	 */
	public TimestampDependencyAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN, null);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected TimestampDependencyAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory, EVMCFG cfg) {
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
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory, EVMCFG cfg) {
		return new TimestampDependencyAbstractDomain(list, memory, cfg);
	}

}