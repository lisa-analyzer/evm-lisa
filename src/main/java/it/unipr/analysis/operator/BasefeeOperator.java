package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

/**
 * The BASEFEE symbolic operator.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 */
public class BasefeeOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final BasefeeOperator INSTANCE = new BasefeeOperator();

	private BasefeeOperator() {
	}

	@Override
	public String toString() {
		return "basefee";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}