package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class AccessControlIncompletenessAbstractDomain extends RelationalTaintAbstractDomain {
	private static final AccessControlIncompletenessAbstractDomain TOP = new AccessControlIncompletenessAbstractDomain(
			createFilledArray(RelationalTaintAbstractDomain.STACK_LIMIT, RelationalTaintElement.BOTTOM), RelationalTaintElement.CLEAN);
	private static final AccessControlIncompletenessAbstractDomain BOTTOM = new AccessControlIncompletenessAbstractDomain(
			null, RelationalTaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public AccessControlIncompletenessAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, RelationalTaintElement.BOTTOM), RelationalTaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and memory
	 * taint level.
	 *
	 * @param stack  the stack of values
	 * @param memory the taint associated with linear memory
	 */
	protected AccessControlIncompletenessAbstractDomain(RelationalTaintElement[] stack, RelationalTaintElement memory) {
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
	public RelationalTaintAbstractDomain mk(RelationalTaintElement[] stack, RelationalTaintElement memory) {
		return new AccessControlIncompletenessAbstractDomain(stack, memory);
	}
}
