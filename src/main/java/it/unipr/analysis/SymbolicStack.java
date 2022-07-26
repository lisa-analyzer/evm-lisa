package it.unipr.analysis;

import it.unive.lisa.analysis.ScopeToken;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.representation.DomainRepresentation;
import it.unive.lisa.analysis.representation.StringRepresentation;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.SymbolicExpression;
import it.unive.lisa.symbolic.value.Constant;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.UnaryExpression;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.symbolic.value.operator.unary.UnaryOperator;
import java.util.ArrayDeque;
import java.util.Objects;

public class SymbolicStack implements ValueDomain<SymbolicStack> {

	private final ArrayDeque<Integer> stack;

	public SymbolicStack() {
		this(new ArrayDeque<>());
	}

	private SymbolicStack(ArrayDeque<Integer> stack) {
		this.stack = stack;
	}

	@Override
	public SymbolicStack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public SymbolicStack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof PushOperator) {
				ArrayDeque<Integer> result = stack.clone();
				result.push(toInteger(un.getExpression()));
				return new SymbolicStack(result);
			}
		}

		return this;
	}

	@Override
	public SymbolicStack assume(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack forgetIdentifier(Identifier id) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// TODO Auto-generated method stub
		return Satisfiability.UNKNOWN;
	}

	@Override
	public SymbolicStack pushScope(ScopeToken token) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack popScope(ScopeToken token) throws SemanticException {
		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public DomainRepresentation representation() {
		return new StringRepresentation(stack);
	}

	@Override
	public SymbolicStack lub(SymbolicStack other) throws SemanticException {
		if (isBottom())
			return other;
		if (other.isBottom())
			return this;

		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public SymbolicStack widening(SymbolicStack other) throws SemanticException {
		if (isBottom())
			return other;
		if (other.isBottom())
			return this;

		// TODO Auto-generated method stub
		return this;
	}

	@Override
	public boolean lessOrEqual(SymbolicStack other) throws SemanticException {
		// TODO Auto-generated method stub
		return true;
	}

	@Override
	public SymbolicStack top() {
		return new SymbolicStack();
	}

	@Override
	public SymbolicStack bottom() {
		return new SymbolicStack(null);
	}

	@Override
	public boolean isBottom() {
		return stack == null;
	}

	private Integer toInteger(SymbolicExpression expression) {
		Constant c = (Constant) expression;
		String hex = (String) c.getValue();
		String hexadecimal = hex.substring(2);
		return Integer.parseInt(hexadecimal, 16);
	}

	@Override
	public int hashCode() {
		return Objects.hash(stack);
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		SymbolicStack other = (SymbolicStack) obj;
		return Objects.equals(stack, other.stack);
	}

}