package it.unipr.analysis.operator;

import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import it.unive.lisa.type.Type;
import it.unive.lisa.type.TypeSystem;
import it.unive.lisa.type.Untyped;
import java.util.Collections;
import java.util.Set;

/**
 * The EXTCODEHASH symbolic operator.
 * 
 * @author <a href="mailto:vincenzo.arceri@unipr.it">Vincenzo Arceri</a>
 */
public class ExtcodehashOperator implements UnaryOperator {

	/**
	 * The singleton instance of this class.
	 */
	public static final ExtcodehashOperator INSTANCE = new ExtcodehashOperator();

	private ExtcodehashOperator() {
	}

	@Override
	public String toString() {
		return "extcodehash";
	}

	@Override
	public Set<Type> typeInference(TypeSystem types, Set<Type> argument) {
		return Collections.singleton(Untyped.INSTANCE);
	}
}
