package it.unipr.disassembler.iterators;

import java.util.Iterator;

public class StringTwoCharIterator implements Iterator<String> {

	private final String str;
	private int pos = 0;

	public StringTwoCharIterator(String str) {
		this.str = str;
	}

	public boolean hasNext() {
		return pos + 2 <= str.length();
	}

	public String next() {
		String substring = str.substring(pos, pos + 2);
		pos = pos + 2;
		return substring;
	}

	public void remove() {
		throw new UnsupportedOperationException();
	}
}