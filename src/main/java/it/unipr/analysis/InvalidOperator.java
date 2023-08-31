package it.unipr.analysis;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class InvalidOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final InvalidOperator INSTANCE = new InvalidOperator();

	private InvalidOperator() {
	}

	@Override
	public String toString() {
		return "addmod";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
