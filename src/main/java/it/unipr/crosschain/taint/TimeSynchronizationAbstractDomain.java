package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unipr.cfg.Number;
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

	protected TimeSynchronizationAbstractDomain(TaintElement[] circularArray, TaintElement memory) {
		super(circularArray, memory, null);
	}

	/**
	 * Builds a taint abstract stack.
	 *
	 * @param circularArray the stack of values
	 */
	protected TimeSynchronizationAbstractDomain(TaintElement[] circularArray, TaintElement memory, EVMCFG cfg) {
		super(circularArray, memory, cfg);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Timestamp
				|| stmt instanceof Number
				|| stmt instanceof Difficulty
				|| stmt instanceof Gaslimit
				|| stmt instanceof Gasprice
				|| stmt instanceof Basefee
				|| stmt instanceof Coinbase
				|| stmt instanceof Blockhash;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
		return mk(array, memory, null);
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory, EVMCFG cfg) {
		return new TimeSynchronizationAbstractDomain(array, memory, cfg);
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
