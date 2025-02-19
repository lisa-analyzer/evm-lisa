package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Log3Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Log3Operator INSTANCE = new Log3Operator();

	private Log3Operator() {
	}

	@Override
	public String toString() {
		return "log3";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
