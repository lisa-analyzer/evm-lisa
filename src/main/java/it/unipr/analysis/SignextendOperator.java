package it.unipr.analysis;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

public class SignextendOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final SignextendOperator INSTANCE = new SignextendOperator();

	private SignextendOperator() {
	}

	@Override
	public String toString() {
		return "signextend";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}

}
