package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Create2Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Create2Operator INSTANCE = new Create2Operator();

	private Create2Operator() {
	}

	@Override
	public String toString() {
		return "create2";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
