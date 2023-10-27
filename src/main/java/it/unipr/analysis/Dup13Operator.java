package it.unipr.analysis;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Dup13Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup13Operator INSTANCE = new Dup13Operator();

	private Dup13Operator() {
	}

	@Override
	public String toString() {
		return "dup13";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
