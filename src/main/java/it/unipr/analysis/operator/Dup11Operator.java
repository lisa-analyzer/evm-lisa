package it.unipr.analysis.operator;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class Dup11Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup11Operator INSTANCE = new Dup11Operator();

	private Dup11Operator() {
	}

	@Override
	public String toString() {
		return "dup11";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
