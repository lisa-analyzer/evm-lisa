package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

/**
 * The MCOPY symbolic operator.
 */
public class McopyOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final McopyOperator INSTANCE = new McopyOperator();

	private McopyOperator() {
	}

	@Override
	public String toString() {
		return "mcopy";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
