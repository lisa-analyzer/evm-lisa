package it.unipr.analysis;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class Log2Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Log2Operator INSTANCE = new Log2Operator();

	private Log2Operator() {
	}

	@Override
	public String toString() {
		return "log2";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
