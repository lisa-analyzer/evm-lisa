package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Swap4Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap4Operator INSTANCE = new Swap4Operator();

	private Swap4Operator() {
	}

	@Override
	public String toString() {
		return "swap4";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
