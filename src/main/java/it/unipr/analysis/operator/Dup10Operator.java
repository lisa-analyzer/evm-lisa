package it.unipr.analysis.operator;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class Dup10Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup10Operator INSTANCE = new Dup10Operator();

	private Dup10Operator() {
	}

	@Override
	public String toString() {
		return "dup10";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
