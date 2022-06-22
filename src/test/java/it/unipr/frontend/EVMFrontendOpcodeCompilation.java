package it.unipr.frontend;

import static org.junit.Assert.assertEquals;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;

public class EVMFrontendOpcodeCompilation {

	private final String path = "evm-testcases/opcode-compilation/";
	private final String output = "evm-output/opcode-compilation/";

	@Test
	public void sm001() throws IOException {
		String address = "0xe592427a0aece92de3edee1f18e0157c05861564";
		EVMFrontend.parseContractFromEtherscan(address, output + "/" + address + "/compiled.op");

		List<String> expected = new ArrayList<>();
		BufferedReader isExp = new BufferedReader(new FileReader(new File(path + address + "/compiled.op")));

		String line = isExp.readLine();
		while (line != null) {
			expected.add(line);
			line = isExp.readLine();
		}

		List<String> actual = new ArrayList<>();

		BufferedReader isAct = new BufferedReader(new FileReader(new File(output + address + "/compiled.op")));
		line = isAct.readLine();
		while (line != null) {
			actual.add(line);
			line = isAct.readLine();
		}

		isExp.close();
		isAct.close();

		for (int i = 0; i < expected.size(); i++)
			assertEquals("Position: " + i, expected.get(i), actual.get(i));
	}
}
