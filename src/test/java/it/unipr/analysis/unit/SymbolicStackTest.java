package it.unipr.analysis.unit;

import static org.junit.Assert.assertEquals;

import java.util.ArrayDeque;

import org.junit.Test;

import it.unipr.analysis.SymbolicStack;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.numeric.Interval;

public class SymbolicStackTest {


	private final SymbolicStack top = new SymbolicStack().top();
	private final SymbolicStack bottom = new SymbolicStack().bottom();
	
	@Test
	public void testLub() throws SemanticException {
		// top/bottom testcases
		assertEquals(top.lub(bottom), top);
		assertEquals(top.lub(top), top);
		assertEquals(bottom.lub(top), top);
		assertEquals(bottom.lub(bottom), bottom);
		
		// top/bottom with other symbolic stack
		SymbolicStack s1 = buildSymbolicStack(1, 2, 3);

		assertEquals(bottom.lub(s1), s1);
		assertEquals(s1.lub(bottom), s1);
		assertEquals(top.lub(s1), top);
		assertEquals(s1.lub(top), top);
	
	}
	
	private SymbolicStack buildSymbolicStack(Integer... values) {
		ArrayDeque<Interval> stack = new ArrayDeque<>();
		for (int i = values.length -1; i >= 0; i--)
			stack.push(new Interval(values[i], values[i]));
		return new SymbolicStack(stack);
	}
}
