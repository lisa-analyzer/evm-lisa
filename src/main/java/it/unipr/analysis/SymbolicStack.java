package it.unipr.analysis;

import java.util.ArrayDeque;
import java.util.Objects;

import it.unive.lisa.analysis.Lattice;
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

/**
 * Semantic domain of the execution stack of the contract.
 */
public class SymbolicStack implements ValueDomain<SymbolicStack> {

	private static final SymbolicStack TOP = new SymbolicStack();
	private static final SymbolicStack BOTTOM = new SymbolicStack(null);

	private final ArrayDeque<Integer> stack;
	private final boolean isTop;

	/**
	 * Constructor of the SymbolicStack class.
	 */
	public SymbolicStack() {
		this(true);
	}

	private SymbolicStack(boolean isTop) {
		this.isTop = isTop;
		this.stack = new ArrayDeque<Integer>();
	}

	private SymbolicStack(ArrayDeque<Integer> stack) {
		this.stack = stack;
		this.isTop = false;
	}

	@Override
	public SymbolicStack assign(Identifier id, ValueExpression expression, ProgramPoint pp) throws SemanticException {
		// nothing to do here
		return this;
	}

	@Override
	public SymbolicStack smallStepSemantics(ValueExpression expression, ProgramPoint pp) throws SemanticException {
		if (expression instanceof Constant) {
			return this;
		} else if (expression instanceof UnaryExpression) {
			UnaryExpression un = (UnaryExpression) expression;
			UnaryOperator op = un.getOperator();

			if (op instanceof PushOperator) { // PUSH
				ArrayDeque<Integer> result = stack.clone();
				
				result.push(toInteger(un.getExpression()));
				
				return new SymbolicStack(result);
			} else if (op instanceof AddOperator) { // ADD
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				
				result.push(opnd_1 + opnd_2);
				
				return new SymbolicStack(result);
			} else if (op instanceof SubOperator) { // SUB
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				
				result.push(opnd_1 - opnd_2);
				
				return new SymbolicStack(result);
			} else if (op instanceof MulOperator) { // MUL
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				
				result.push(opnd_1 * opnd_2);
				
				return new SymbolicStack(result);
			} else if ((op instanceof DivOperator) || (op instanceof SdivOperator)) { // DIV, SDIV
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				
				if (opnd_2 == 0) {
					result.push(0);
				} else {
					result.push(opnd_1 / opnd_2);
				}
				
				return new SymbolicStack(result);
			} else if ((op instanceof ModOperator) || (op instanceof SmodOperator)) { // MOD, SMOD
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				
				if (opnd_2 == 0) {
					result.push(0);
				} else {
					result.push(opnd_1 % opnd_2);
				}
				
				return new SymbolicStack(result);
			} else if (op instanceof AddmodOperator) { // ADDMOD
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				Integer opnd_3 = result.pop();
				
				if (opnd_3 == 0) {
					result.push(0);
				} else {
					result.push((opnd_1 + opnd_2) % opnd_3);
				}
				
				return new SymbolicStack(result);
			} else if (op instanceof MulmodOperator) { // MULMOD
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				Integer opnd_3 = result.pop();
				
				if (opnd_3 == 0) {
					result.push(0);
				} else {
					result.push((opnd_1 * opnd_2) % opnd_3);
				}
				
				return new SymbolicStack(result);
			} else if (op instanceof ExpOperator) { // EXP
				ArrayDeque<Integer> result = stack.clone();
				Integer opnd_1 = result.pop();
				Integer opnd_2 = result.pop();
				
				result.push((int)(Math.pow(opnd_1, opnd_2)));
				
				return new SymbolicStack(result);
			}
		}

		return top();
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
		if (isBottom())
			return Lattice.BOTTOM_REPR;
		else if (isTop())
			return Lattice.TOP_REPR;
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
		return TOP;
	}

	@Override
	public SymbolicStack bottom() {
		return BOTTOM;
	}

	@Override
	public boolean isBottom() {
		return stack == null;
	}

	@Override
	public boolean isTop() {
		return isTop;
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