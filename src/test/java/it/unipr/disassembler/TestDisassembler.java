package it.unipr.disassembler;

import java.io.FileWriter;
import java.io.IOException;

/**
 * TestDisassembler is a program that demonstrates the usage of the Ethereum
 * Disassembler. It compiles a Solidity contract using the SolidityCompiler
 * class, disassembles the bytecode using the Disassembler class, and writes the
 * disassembled code to a file.
 * <p>
 * The source code for the Ethereum Disassembler can be found at: <a href=
 * "https://github.com/fergarrui/ethereum-disassembler">https://github.com/fergarrui/ethereum-disassembler</a>
 * <p>
 * The Solidity contract is specified by the solidityFilePath variable, and the
 * Solidity compiler executable is specified by the solcPath variable. The
 * compiled bytecode is obtained using the SolidityCompiler class, and then the
 * Disassembler class is used to disassemble the bytecode into human-readable
 * opcodes. The resulting opcodes are then written to a file specified by the
 * fileResultPath variable.
 */
public class TestDisassembler {
	private String solidityFilePath = "./src/test/java/it/unipr/disassembler/dummy.sol";
	private String solcPath = "/opt/homebrew/bin/solc"; // `which solc` in
														// Terminal to know the
														// path
	private String fileResultPath = "./src/test/java/it/unipr/disassembler/compiled.op";

	public void go() {
		SolidityCompiler compiler = new SolidityCompiler(solidityFilePath, solcPath);

		String bytecode = compiler.compile();
		System.out.println("Bytecode:\n\t" + bytecode);

		Disassembler d = new Disassembler(bytecode);

		String opcode = d.getDisassembledCode();
		// System.out.println("Opcode:\n" + opcode);

		/**
		 * The try-with-resources statement in Java is used to automatically
		 * close resources. This helps in improving code readability and reduces
		 * the chances of resource leaks.
		 */
		try (FileWriter writer = new FileWriter(fileResultPath)) {

			writer.write(opcode);
			System.out.println("Opcode written successfully in " + fileResultPath);

		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public static void main(String[] args) {
		new TestDisassembler().go();
	}
}
