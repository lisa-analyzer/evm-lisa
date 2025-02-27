package it.unipr.utils;

import java.util.regex.Pattern;

public class EthereumUtils {
	private static final Pattern EVM_ADDRESS_PATTERN = Pattern.compile("^0x[a-fA-F0-9]{40}$");

	public static boolean isValidEVMAddress(String address) {
		return address != null && EVM_ADDRESS_PATTERN.matcher(address).matches();
	}

	public static void main(String[] args) {
		String test1 = "0x4e9ce36E442e55EcD9025B9a6E0D88485d628A67"; // Valid
		String test2 = "0xZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; // Invalid
		String test3 = "4e9ce36E442e55EcD9025B9a6E0D88485d628A67"; // Invalid

		System.out.println(test1 + " -> " + isValidEVMAddress(test1)); // true
		System.out.println(test2 + " -> " + isValidEVMAddress(test2)); // false
		System.out.println(test3 + " -> " + isValidEVMAddress(test3)); // false
	}
}