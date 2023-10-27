package it.unipr.analysis;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Swap10Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap10Operator INSTANCE = new Swap10Operator();

	private Swap10Operator() {
	}

	@Override
	public String toString() {
		return "swap10";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
