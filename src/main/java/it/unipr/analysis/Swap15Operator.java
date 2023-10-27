package it.unipr.analysis;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Swap15Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap15Operator INSTANCE = new Swap15Operator();

	private Swap15Operator() {
	}

	@Override
	public String toString() {
		return "swap15";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
