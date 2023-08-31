package it.unipr.analysis;

import java.util.Collections;
import java.util.Set;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;

public class AddressOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final AddressOperator INSTANCE = new AddressOperator();

	private AddressOperator() {
	}

	@Override
	public String toString() {
		return "address";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
