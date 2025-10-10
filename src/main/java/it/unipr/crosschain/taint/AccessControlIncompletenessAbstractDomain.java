package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class AccessControlIncompletenessAbstractDomain extends TaintAbstractDomain {
	private static final AccessControlIncompletenessAbstractDomain TOP = new AccessControlIncompletenessAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final AccessControlIncompletenessAbstractDomain BOTTOM = new AccessControlIncompletenessAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public AccessControlIncompletenessAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and memory
	 * taint level.
	 *
	 * @param stack  the stack of values
	 * @param memory the taint associated with linear memory
	 */
	protected AccessControlIncompletenessAbstractDomain(TaintElement[] stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Calldataload
				|| stmt instanceof Calldatacopy
				|| stmt instanceof Calldatasize
				|| stmt instanceof Caller
				|| stmt instanceof Origin
				|| stmt instanceof Callvalue;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public AccessControlIncompletenessAbstractDomain top() {
		return TOP;
	}

	@Override
	public AccessControlIncompletenessAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] stack, TaintElement memory) {
		return new AccessControlIncompletenessAbstractDomain(stack, memory);
	}
}
