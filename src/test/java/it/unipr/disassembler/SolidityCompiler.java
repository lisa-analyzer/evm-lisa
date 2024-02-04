package it.unipr.disassembler;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * SolidityCompiler is a class that facilitates the compilation of Solidity
 * contracts into bytecode. It uses the Solidity compiler (`solc`) installed on
 * the device to generate the compiled bytecode from a given Solidity file.
 * <p>
 * Prerequisite: Ensure that `solc` is installed on the device. Installation
 * steps for macOS can be found at: <a href=
 * "https://89devs.com/solidity/install-macOS/">https://89devs.com/solidity/install-macOS/</a>
 * <p>
 * The SolidityCompiler class requires the path to the Solidity file
 * (solidityFilePath) and the path to the `solc` executable (solcPath). The
 * compile method executes the Solidity compiler as a process, reads the output,
 * and returns the compiled bytecode.
 */
public class SolidityCompiler {
	private String solidityFilePath;
	private String solcPath;
	private String command;

	public SolidityCompiler(String solidityFilePath, String solcPath) {
		this.solidityFilePath = solidityFilePath;
		this.solcPath = solcPath;
		this.command = solcPath + " --bin --optimize " + solidityFilePath;
	}

	public String compile() {
		try {
			// Print the executed command to the console
			System.out.println("Command executed:\n\t" + command);

			// Execute the Solidity compiler as a process
			Process process = Runtime.getRuntime().exec(command);
			System.out.println("Process:\n\t" + process);

			// Read the output of the process
			BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
			String line;
			String bytecode = "";
			StringBuilder bytecodeBuilder = new StringBuilder();

			// Read each line of the process output
			while ((line = reader.readLine()) != null) {
				bytecodeBuilder.append(line).append("\n");

				// The bytecode is the last line of the result
				bytecode = line;
			}
			bytecode = "0x" + bytecode;

			// Wait for the process to finish
			int exitCode = process.waitFor();

			// Check if the process exited successfully
			if (exitCode == 0) {
				// Print the bytecode
				// System.out.println("Contract bytecode:\n" +
				// bytecodeBuilder.toString());
				return bytecode;
			} else {
				// Print an error message if the process did not exit
				// successfully
				System.err.println("Error during contract compilation. ExitCode=" + exitCode);
			}
		} catch (IOException | InterruptedException e) {
			e.printStackTrace();
		}

		return null;
	}

}
