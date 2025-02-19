package it.unipr.analysis.operator;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class Dup7Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup7Operator INSTANCE = new Dup7Operator();

	private Dup7Operator() {
	}

	@Override
	public String toString() {
		return "dup7";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
