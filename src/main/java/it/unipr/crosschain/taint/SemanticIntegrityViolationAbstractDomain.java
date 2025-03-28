package it.unipr.crosschain.taint;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.Calldatacopy;
import it.unipr.cfg.Calldataload;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.Set;

public class SemanticIntegrityViolationAbstractDomain extends TaintAbstractDomain {

	private static final SemanticIntegrityViolationAbstractDomain TOP = new SemanticIntegrityViolationAbstractDomain(
			createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	private static final SemanticIntegrityViolationAbstractDomain BOTTOM = new SemanticIntegrityViolationAbstractDomain(
			null, TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public SemanticIntegrityViolationAbstractDomain() {
		this(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
	}

	protected SemanticIntegrityViolationAbstractDomain(TaintElement[] stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public boolean isTainted(Statement stmt) {
		return stmt instanceof Calldataload ||
				stmt instanceof Calldatacopy;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		return Set.of();
	}

	@Override
	public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
		return new SemanticIntegrityViolationAbstractDomain(array, memory);
	}

	@Override
	public SemanticIntegrityViolationAbstractDomain top() {
		return TOP;
	}

	@Override
	public SemanticIntegrityViolationAbstractDomain bottom() {
		return BOTTOM;
	}
}
