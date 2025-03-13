package it.unipr.analysis.cron.semantics.sanitizer;

import it.unipr.analysis.operator.*;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unive.lisa.symbolic.value.Operator;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

public class SanitizerAbstractDomain extends TaintAbstractDomain {
	private static final SanitizerAbstractDomain TOP = new SanitizerAbstractDomain(
			new ArrayList<>(Collections.nCopies(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM)),
			TaintElement.CLEAN);
	private static final SanitizerAbstractDomain BOTTOM = new SanitizerAbstractDomain(null,
			TaintElement.BOTTOM);

	/**
	 * Builds an initial symbolic stack.
	 */
	public SanitizerAbstractDomain() {
		this(new ArrayList<>(Collections.nCopies(STACK_LIMIT, TaintElement.BOTTOM)), TaintElement.CLEAN);
	}

	/**
	 * Builds a taint abstract stack starting from a given stack and a list of
	 * elements that push taint.
	 *
	 * @param stack the stack of values
	 */
	protected SanitizerAbstractDomain(ArrayList<TaintElement> stack, TaintElement memory) {
		super(stack, memory);
	}

	@Override
	public Set<Operator> getTaintedOpcode() {
		Set<Operator> taintedOpcode = new HashSet<>();
		taintedOpcode.add(TimestampOperator.INSTANCE);
		taintedOpcode.add(BlockhashOperator.INSTANCE);
		taintedOpcode.add(DifficultyOperator.INSTANCE);
		taintedOpcode.add(BalanceOperator.INSTANCE);
		return taintedOpcode;
	}

	@Override
	public Set<Operator> getSanitizedOpcode() {
		Set<Operator> sanitizedOpcode = new HashSet<>();
		sanitizedOpcode.add(AddOperator.INSTANCE);
		sanitizedOpcode.add(AddressOperator.INSTANCE);
		return sanitizedOpcode;
	}

	@Override
	public SanitizerAbstractDomain top() {
		return TOP;
	}

	@Override
	public SanitizerAbstractDomain bottom() {
		return BOTTOM;
	}

	@Override
	public TaintAbstractDomain mk(ArrayList<TaintElement> list, TaintElement memory) {
		return new SanitizerAbstractDomain(list, memory);
	}

}