package it.unipr.analysis.operator;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class Swap12Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap12Operator INSTANCE = new Swap12Operator();

	private Swap12Operator() {
	}

	@Override
	public String toString() {
		return "swap12";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
