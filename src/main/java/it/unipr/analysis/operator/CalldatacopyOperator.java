package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

/**
 * The CALLDATACOPY symbolic operator.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 */
public class CalldatacopyOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final CalldatacopyOperator INSTANCE = new CalldatacopyOperator();

	private CalldatacopyOperator() {
	}

	@Override
	public String toString() {
		return "calldatacopy";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
