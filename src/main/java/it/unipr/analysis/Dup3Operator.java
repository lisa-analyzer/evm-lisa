package it.unipr.analysis;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class Dup3Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup3Operator INSTANCE = new Dup3Operator();

	private Dup3Operator() {
	}

	@Override
	public String toString() {
		return "dup3";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
