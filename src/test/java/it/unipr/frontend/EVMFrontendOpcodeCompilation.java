package it.unipr.frontend;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;

public class EVMFrontendOpcodeCompilation {

	private final String OUTPUT_DIR = "evm-outputs/opcode-compilation/";
	private final String CONTRACT_ADDRESS = "0x251f752b85a9f7e1b3c42d802715b5d7a8da3165";
	private final String OUTPUT_FILE = OUTPUT_DIR + CONTRACT_ADDRESS + "/compiled.sol";

	@Test
	public void sm001() throws IOException {
		Files.createDirectories(Paths.get(OUTPUT_DIR + CONTRACT_ADDRESS));

		EVMFrontend.parseContractFromEtherscan(CONTRACT_ADDRESS, OUTPUT_FILE);

		List<String> expected = new ArrayList<>();
		BufferedReader isExp = new BufferedReader(new FileReader(new File(OUTPUT_FILE)));

		String line = isExp.readLine();
		while (line != null) {
			expected.add(line);
			line = isExp.readLine();
		}

		List<String> actual = new ArrayList<>();

		BufferedReader isAct = new BufferedReader(new FileReader(new File(OUTPUT_FILE)));
		line = isAct.readLine();
		while (line != null) {
			actual.add(line);
			line = isAct.readLine();
		}

		isExp.close();
		isAct.close();

		for (int i = 0; i < expected.size(); i++) {

			if (actual.get(i).equals("INVALID") && expected.get(i).equals("'fe'(Unknown Opcode)"))
				assertNotEquals("Position: " + i, expected.get(i), actual.get(i));
			else
				assertEquals("Position: " + i, expected.get(i), actual.get(i));
		}
	}
}
