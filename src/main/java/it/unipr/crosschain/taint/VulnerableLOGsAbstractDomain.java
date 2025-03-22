package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unipr.cfg.Number;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class VulnerableLOGsAbstractDomain extends TaintAbstractDomain {

	private static final VulnerableLOGsAbstractDomain TOP = new VulnerableLOGsAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final VulnerableLOGsAbstractDomain BOTTOM = new VulnerableLOGsAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public VulnerableLOGsAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	public VulnerableLOGsAbstractDomain(EVMCFG cfg) {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN, cfg);
	}

	protected VulnerableLOGsAbstractDomain(TaintElement[] stack, TaintElement memory) {
		this(stack, memory, null);
	}

	/**
	 * Builds a taint abstract stack.
	 *
	 * @param stack the stack of values
	 */
	protected VulnerableLOGsAbstractDomain(TaintElement[] stack, TaintElement memory, EVMCFG cfg) {
		super(stack, memory, cfg);
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
	public TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory) {
		return mk(stack, memory, null);
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory, EVMCFG cfg) {
		return new VulnerableLOGsAbstractDomain(stack, memory, cfg);
	}

	@Override
	public VulnerableLOGsAbstractDomain top() {
		return TOP;
	}

	@Override
	public VulnerableLOGsAbstractDomain bottom() {
		return BOTTOM;
	}
}
