package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Mstore8Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Mstore8Operator INSTANCE = new Mstore8Operator();

	private Mstore8Operator() {
	}

	@Override
	public String toString() {
		return "mstore8";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
