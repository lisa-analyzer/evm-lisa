package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.Calldatacopy;
import it.unipr.cfg.Calldataload;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class UncheckedExternalInfluenceAbstractDomain extends TaintAbstractDomain {

	private static final UncheckedExternalInfluenceAbstractDomain TOP = new UncheckedExternalInfluenceAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final UncheckedExternalInfluenceAbstractDomain BOTTOM = new UncheckedExternalInfluenceAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public UncheckedExternalInfluenceAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	protected UncheckedExternalInfluenceAbstractDomain(TaintElement[] stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Calldataload
				|| stmt instanceof Calldatacopy;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
		return new UncheckedExternalInfluenceAbstractDomain(array, memory);
	}

	@Override
	public UncheckedExternalInfluenceAbstractDomain top() {
		return TOP;
	}

	@Override
	public UncheckedExternalInfluenceAbstractDomain bottom() {
		return BOTTOM;
	}
}
