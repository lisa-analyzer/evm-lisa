package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.utils.MyCache;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class TimeSynchronizationAbstractDomain extends TaintAbstractDomain {

	private static final TimeSynchronizationAbstractDomain TOP = new TimeSynchronizationAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final TimeSynchronizationAbstractDomain BOTTOM = new TimeSynchronizationAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public TimeSynchronizationAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack.
	 *
	 * @param stack the stack of values
	 */
	protected TimeSynchronizationAbstractDomain(TaintElement[] stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return MyCache.getInstance().isTaintedCallDataLoad(stmt);
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory) {
		return mk(stack, memory);
	}

	@Override
	public TimeSynchronizationAbstractDomain top() {
		return TOP;
	}

	@Override
	public TimeSynchronizationAbstractDomain bottom() {
		return BOTTOM;
	}
}
