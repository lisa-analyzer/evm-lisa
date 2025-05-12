package it.unipr.utils;

import java.math.BigInteger;

public class BitManager {
	public static final int SIZE = 256;

	/**
	 * Converts a BigInteger to an array of bits (0s and 1s), MSB first.
	 */
	public static int[] toBitArray(BigInteger value) {
		if (value.signum() < 0) {
			throw new IllegalArgumentException("Negative numbers not supported.");
		}

		String binaryString = value.toString(2); // base 2 string
		int[] bits = new int[SIZE];
		int padding = SIZE - binaryString.length();

		for (int i = 0; i < binaryString.length(); i++) {
			bits[padding + i] = (binaryString.charAt(i) == '1') ? 1 : 0;
		}
		return bits;
	}

	/**
	 * Converts an array of bits (0s and 1s), MSB first, to a BigInteger.
	 */
	public static BigInteger fromBitArray(int[] bits) {
		BigInteger result = BigInteger.ZERO;
		for (int bit : bits) {
			result = result.shiftLeft(1).or(BigInteger.valueOf(bit));
		}
		return result;
	}

	/**
	 * Logical left shift (<<): discards MSBs, fills with 0s at LSBs.
	 */
	public static int[] shiftLeft(int[] bits, int n) {
		if (bits.length != SIZE)
			throw new IllegalArgumentException("Input must be 256 bits");

		int[] result = new int[SIZE];
		if (n >= SIZE)
			return result; // all zeros

		System.arraycopy(bits, n, result, 0, SIZE - n);
		return result;
	}

	/**
	 * Logical right shift (>>>): discards LSBs, fills with 0s at MSBs.
	 */
	public static int[] shiftRight(int[] bits, int n) {
		if (bits.length != SIZE)
			throw new IllegalArgumentException("Input must be 256 bits");

		int[] result = new int[SIZE];
		if (n >= SIZE)
			return result; // all zeros

		System.arraycopy(bits, 0, result, n, SIZE - n);
		return result;
	}

	/**
	 * Arithmetic right shift (>>): discards LSBs, fills with sign bit at MSBs.
	 */
	public static int[] arithmeticShiftRight(int[] bits, int n) {
		if (bits.length != SIZE)
			throw new IllegalArgumentException("Input must be 256 bits");

		int[] result = new int[SIZE];
		int sign = bits[0]; // MSB = sign bit
		if (n >= SIZE) {
			// All bits set to sign
			for (int i = 0; i < SIZE; i++)
				result[i] = sign;
			return result;
		}
		for (int i = 0; i < n; i++)
			result[i] = sign;
		System.arraycopy(bits, 0, result, n, SIZE - n);
		return result;
	}

	public static void print(String label, int[] bits) {
		System.out.print(label + ": ");
		for (int b : bits)
			System.out.print(b);
		System.out.println();
	}
}
