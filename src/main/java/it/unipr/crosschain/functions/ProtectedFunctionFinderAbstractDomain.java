package it.unipr.crosschain.functions;

import it.unipr.cfg.Caller;
import it.unipr.crosschain.taint.RelationalTaintAbstractDomain;
import it.unipr.crosschain.taint.RelationalTaintElement;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class ProtectedFunctionFinderAbstractDomain extends RelationalTaintAbstractDomain {

	private static final ProtectedFunctionFinderAbstractDomain TOP = new ProtectedFunctionFinderAbstractDomain(
			createFilledArray(RelationalTaintAbstractDomain.STACK_LIMIT, RelationalTaintElement.BOTTOM),
			0,
			0,
			RelationalTaintElement.CLEAN);
	private static final ProtectedFunctionFinderAbstractDomain BOTTOM = new ProtectedFunctionFinderAbstractDomain(
			null,
			0,
			0,
			RelationalTaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public ProtectedFunctionFinderAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, RelationalTaintElement.BOTTOM), 0, 0, RelationalTaintElement.CLEAN);
	}

	protected ProtectedFunctionFinderAbstractDomain(RelationalTaintElement[] stack, int head, int tail,
			RelationalTaintElement memory) {
		super(stack, head, tail, memory);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Caller;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public RelationalTaintAbstractDomain mk(RelationalTaintElement[] stack, int head, int tail,
			RelationalTaintElement memory) {
		return new ProtectedFunctionFinderAbstractDomain(stack, head, tail, memory);
	}

	@Override
	public RelationalTaintAbstractDomain top() {
		return TOP;
	}

	@Override
	public RelationalTaintAbstractDomain bottom() {
		return BOTTOM;
	}
}
