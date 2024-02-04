package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class Dup16Operator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final Dup16Operator INSTANCE = new Dup16Operator();

	private Dup16Operator() {
	}

	@Override
	public String toString() {
		return "dup16";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
