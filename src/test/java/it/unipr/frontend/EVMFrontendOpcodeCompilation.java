package it.unipr.frontend;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;

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
		String address = "0x251f752b85a9f7e1b3c42d802715b5d7a8da3165";
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

		for (int i = 0; i < expected.size(); i++) {
			
			if(actual.get(i).equals("INVALID") && expected.get(i).equals("'fe'(Unknown Opcode)"))
				assertNotEquals("Position: " + i, expected.get(i), actual.get(i));
			else
				assertEquals("Position: " + i, expected.get(i), actual.get(i));
		}
	}
}
