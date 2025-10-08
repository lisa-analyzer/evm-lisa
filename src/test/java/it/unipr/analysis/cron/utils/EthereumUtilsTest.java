package it.unipr.analysis.cron.utils;

import it.unipr.utils.EthereumUtils;
import org.junit.Test;

public class EthereumUtilsTest {
	@Test
	public void test01() {
		String test1 = "0x4e9ce36E442e55EcD9025B9a6E0D88485d628A67"; // Valid
		String test2 = "0xZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"; // Invalid
		String test3 = "4e9ce36E442e55EcD9025B9a6E0D88485d628A67"; // Invalid

		assert EthereumUtils.isValidEVMAddress(test1);
		assert !EthereumUtils.isValidEVMAddress(test2);
		assert !EthereumUtils.isValidEVMAddress(test3);
	}
}
