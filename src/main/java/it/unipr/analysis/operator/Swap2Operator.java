package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Swap2Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Swap2Operator INSTANCE = new Swap2Operator();

	private Swap2Operator() {
	}

	@Override
	public String toString() {
		return "swap2";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
