package it.unipr.analysis;

import java.util.LinkedList;
import java.util.List;

import it.unive.lisa.analysis.numeric.Interval;

public class StackTest {
	private AbstractStack dupX(int x, AbstractStack stack) {
		List<Interval> clone = stack.clone().getStack();
	    
	    if(stack.size() < x || x < 1)
	    	return stack.clone();
	    
	    Object[] obj = clone.toArray();
	    
	    int first;
	    if(stack.size() < 32)
	    	first = 32;
	    else
	    	first = clone.size();
	    
	    Interval tmp = (Interval) obj[first - x];
	    
	    LinkedList<Interval> result = new LinkedList<>();
	    
	    for(int i = 0; i < clone.size(); i++)
	    	result.add((Interval) obj[i]);
	    
	    result.add(tmp);
	    result.remove(0);
	    
	    return new AbstractStack(result);
	}
	
	private void testDup() {
		AbstractStack s = new AbstractStack();
		
		for(int i = 0; i < 32; i++)
			s.push(new Interval(32 - i, 32 - i));
		
//		s.push(new Interval(2,2));
//		s.push(new Interval(1,1));
		
		System.out.printf("Stack iniziale con 32 elementi reali (size: %s): \n%s \n", s.size(), s);
		System.out.println("dup10: \n" + dupX(10, s));
		
		System.out.println();
		
		s = new AbstractStack();
		for(int i = 0; i < 10; i++)
			s.push(new Interval(10 - i, 10 - i));
		System.out.printf("Stack iniziale con 10 elementi reali (size: %s): \n%s \n", s.size(), s);
		System.out.println("dup32: \n" + dupX(32, s));
		System.out.println("dup15: \n" + dupX(15, s));
		System.out.println("dup10: \n" + dupX(10, s));
		System.out.println("dup9: \n" + dupX(9, s));
		System.out.println("dup2: \n" + dupX(2, s));
		
		System.out.println();
		
		s = new AbstractStack();
		for(int i = 0; i < 32; i++)
			s.push(new Interval(32 - i, 32 - i));
		System.out.printf("Stack iniziale con 32 elementi reali (size: %s): \n%s \n", s.size(), s);
		for(int i = 0; i < 16; i++)
			s.pop();
		System.out.printf("Poppo 16 elementi (size: %s): \n%s \n", s.size(), s);
		System.out.println("dup32: \n" + dupX(32, s));
		System.out.println("dup16: \n" + dupX(16, s));
		System.out.println("dup15: \n" + dupX(15, s));
		System.out.println("dup9: \n" + dupX(9, s));
		System.out.println("dup2: \n" + dupX(2, s));
	}

	private AbstractStack swapX(int x, AbstractStack stack) {
	    List<Interval> clone = stack.clone().getStack();
	    
	    if(stack.size() < x + 1 || x < 1)
	    	return stack.clone();
	    
	    Object[] obj = clone.toArray();
	    int first;
	    
	    if(stack.size() < 32)
	    	first = 32 - 1;
	    else
	    	first = clone.size() - 1;
	    
	    Object tmp = obj[first];
	    obj[first] = obj[first - x];
	    obj[first - x] = tmp;
	    
	    LinkedList<Interval> result = new LinkedList<>();
	    
	    for(int i = 0; i < clone.size(); i++)
	    	result.add((Interval) obj[i]);
	    
	    return new AbstractStack(result);
	}
	
	private void testSwap() {
		AbstractStack s = new AbstractStack();
		
		for(int i = 0; i < 32; i++)
			s.push(new Interval(32 - i, 32 - i));
		
//		s.push(new Interval(2,2));
//		s.push(new Interval(1,1));
		
		System.out.printf("Stack iniziale con 32 elementi reali (size: %s): \n%s \n", s.size(), s);
		System.out.println("swap10: \n" + swapX(10, s));
		
		System.out.println();
		
		s = new AbstractStack();
		for(int i = 0; i < 10; i++)
			s.push(new Interval(10 - i, 10 - i));
		System.out.printf("Stack iniziale con 10 elementi reali (size: %s): \n%s \n", s.size(), s);
		System.out.println("swap32: \n" + swapX(32, s));
		System.out.println("swap15: \n" + swapX(15, s));
		System.out.println("swap10: \n" + swapX(10, s));
		System.out.println("swap9: \n" + swapX(9, s));
		System.out.println("swap2: \n" + swapX(2, s));
		
		System.out.println();
		
		s = new AbstractStack();
		for(int i = 0; i < 32; i++)
			s.push(new Interval(32 - i, 32 - i));
		System.out.printf("Stack iniziale con 32 elementi reali (size: %s): \n%s \n", s.size(), s);
		for(int i = 0; i < 16; i++)
			s.pop();
		System.out.printf("Poppo 16 elementi (size: %s): \n%s \n", s.size(), s);
		System.out.println("swap32: \n" + swapX(32, s));
		System.out.println("swap16: \n" + swapX(16, s));
		System.out.println("swap15: \n" + swapX(15, s));
		System.out.println("swap9: \n" + swapX(9, s));
		System.out.println("swap2: \n" + swapX(2, s));
	}
	
	public static void main(String[] args) {
		new StackTest().testSwap();
	}
}
