package it.unipr.analysis;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class CallvalueOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final CallvalueOperator INSTANCE = new CallvalueOperator();

	private CallvalueOperator() {
	}

	@Override
	public String toString() {
		return "callvalue";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
