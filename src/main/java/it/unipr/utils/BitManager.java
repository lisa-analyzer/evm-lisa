package it.unipr.utils;

import java.math.BigInteger;

public class BitManager {
	public static final int SIZE = 256;
	private static final BigInteger TWO = BigInteger.valueOf(2);
	private static final BigInteger MOD = TWO.pow(SIZE);

	/**
	 * Converts the given BigInteger into an array of integers (0s and 1s),
	 * representing the binary representation of the number aligned to a fixed
	 * size.
	 *
	 * @param value the BigInteger to be converted. Must be non-negative.
	 * 
	 * @return an array of integers representing the binary bits of the input
	 *             value, aligned to the fixed size.
	 * 
	 * @throws IllegalArgumentException if the input value is negative.
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
	 * Converts an array of bits (0s and 1s) into a BigInteger. Each bit in the
	 * input array is treated as a binary digit, starting from the most
	 * significant bit.
	 *
	 * @param bits an array of integers, where each element must be either 0 or
	 *                 1, representing the bits of the number in binary. The
	 *                 most significant bit is the first element of the array.
	 * 
	 * @return a BigInteger representing the value of the input bit array.
	 */
	public static BigInteger fromBitArray(int[] bits) {
		BigInteger result = BigInteger.ZERO;
		for (int bit : bits) {
			result = result.shiftLeft(1).or(BigInteger.valueOf(bit));
		}
		return result;
	}

	/**
	 * Shifts the binary representation of a 256-bit array to the left by a
	 * specified number of positions. The bits shifted out of the array are
	 * discarded, and the vacated positions on the right are filled with zeros.
	 *
	 * @param bits an array of integers representing the binary data to be
	 *                 shifted. The input array must have a length of 256.
	 * @param n    the number of positions to shift the bits to the left. If n
	 *                 is greater than or equal to 256, the result will be an
	 *                 array of zeros.
	 * 
	 * @return a new array of integers representing the binary data after being
	 *             shifted to the left by n positions.
	 * 
	 * @throws IllegalArgumentException if the input array does not have a
	 *                                      length of 256.
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
	 * Shifts the bits in the input array to the right by a specified number of
	 * positions. The resulting array will have zeros in the most significant
	 * positions vacated by the shift.
	 *
	 * @param bits an array of integers where each element must be either 0 or
	 *                 1, representing the bits to be shifted. The array must
	 *                 have a length equal to 256.
	 * @param n    the number of positions to shift the bits to the right.
	 * 
	 * @return a new array of integers representing the result of the right
	 *             shift. The array length will be 256.
	 * 
	 * @throws IllegalArgumentException if the input array does not have a
	 *                                      length of 256.
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
	 * Performs an arithmetic right shift on a 256-bit array in two's complement
	 * representation. The method shifts the bits to the right by the specified
	 * number of positions, preserving the sign (most significant bit) for the
	 * shifted positions.
	 *
	 * @param bits an array of integers representing 256 bits (0s and 1s) in
	 *                 two's complement format. The array must have a length of
	 *                 256.
	 * @param n    the number of positions to shift the bits to the right. If n
	 *                 is greater than or equal to the size of the array (256),
	 *                 the result will be an array filled with the sign bit.
	 * 
	 * @return a 256-bit array of integers representing the result of the
	 *             arithmetic right shift, with the sign extended for shifted
	 *             positions.
	 * 
	 * @throws IllegalArgumentException if the input array does not have a
	 *                                      length of 256.
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

	/**
	 * Converts an array of bits (0s and 1s), representing a 256-bit number in
	 * two's complement form, into a signed BigInteger.
	 *
	 * @param bits an array of integers where each element must be either 0 or
	 *                 1, representing the bits of the number in two's
	 *                 complement format. The array must have a length equal to
	 *                 256.
	 * 
	 * @return a BigInteger representing the signed value of the input bit
	 *             array.
	 * 
	 * @throws IllegalArgumentException if the input array does not have a
	 *                                      length of 256.
	 */
	public static BigInteger toSignedBigInteger(int[] bits) {
		if (bits.length != SIZE)
			throw new IllegalArgumentException("Input must be 256 bits");

		BigInteger unsigned = BigInteger.ZERO;
		for (int i = 0; i < SIZE; i++)
			unsigned = unsigned.shiftLeft(1).or(BigInteger.valueOf(bits[i]));

		if (bits[0] == 1)
			return unsigned.subtract(MOD);
		else
			return unsigned;
	}

	/**
	 * Converts a given BigInteger to its 256-bit two's complement binary
	 * representation as an array of integers (0s and 1s), with the most
	 * significant bit (MSB) first. If the BigInteger is out of range for a
	 * 256-bit two's complement, an exception is thrown.
	 *
	 * @param value the BigInteger to be converted to two's complement. Must be
	 *                  within the range of -2^255 to 2^255 - 1.
	 * 
	 * @return an array of integers representing the 256-bit two's complement
	 *             binary representation of the input value, where each element
	 *             is either 0 or 1.
	 * 
	 * @throws IllegalArgumentException if the value is out of range for 256-bit
	 *                                      two's complement.
	 * @throws IllegalStateException    if the binary representation exceeds 256
	 *                                      bits.
	 */
	public static int[] toTwosComplement(BigInteger value) {
		if (value.compareTo(TWO.pow(SIZE - 1).negate()) < 0
				|| value.compareTo(TWO.pow(SIZE - 1).subtract(BigInteger.ONE)) > 0)
			throw new IllegalArgumentException("Value out of range for 256-bit two's complement");

		BigInteger unsigned;
		if (value.signum() < 0)
			unsigned = value.add(MOD);
		else
			unsigned = value;

		String bin = unsigned.toString(2);
		if (bin.length() > SIZE)
			throw new IllegalStateException("Unexpected: unsigned representation longer than 256 bits");

		int pad = SIZE - bin.length();
		int[] bits = new int[SIZE];
		for (int i = 0; i < bin.length(); i++)
			bits[pad + i] = (bin.charAt(i) == '1') ? 1 : 0;

		return bits;
	}

	/**
	 * Performs signed division of two arrays of bits representing integers in
	 * two's complement format.
	 *
	 * @param a the dividend represented as an array of bits (two's complement)
	 * @param b the divisor represented as an array of bits (two's complement)
	 * 
	 * @return the quotient of the division, represented as an array of bits
	 *             (two's complement)
	 * 
	 * @throws ArithmeticException if the divisor is zero
	 */
	public static int[] sdiv(int[] a, int[] b) {
		BigInteger ai = toSignedBigInteger(a);
		BigInteger bi = toSignedBigInteger(b);

		if (bi.equals(BigInteger.ZERO))
			throw new ArithmeticException("Division by zero");

		BigInteger qi = ai.divide(bi);
		return toTwosComplement(qi);
	}

	/**
	 * Prints the label followed by an array of bits (0s and 1s) as a string,
	 * and then moves to the next line.
	 *
	 * @param label the label to be printed before the bit array
	 * @param bits  the array of bits (0s and 1s) to be printed
	 */
	public static void print(String label, int[] bits) {
		System.out.print(label + ": ");
		for (int b : bits)
			System.out.print(b);
		System.out.println();
	}
}
