package it.unipr.frontend;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import it.unipr.evm.antlr.EVMBParser;
import it.unipr.evm.antlr.EVMBLexer;

public class EVMFrontend {
	
	public static void main(String[] args) throws IOException {
		String result = SMAddress.parseSMAddress("0xcc5ab3f04704620d6f20a0cf2e772d6a81f42c4b");
		@SuppressWarnings("unused")
		BytecodeToOpcode trad = new BytecodeToOpcode("evm-testcases/sm.sol");
		BytecodeToOpcode.translate(result);
		parseContract("evm-testcases/sm.sol");
		System.out.println(result);
	}
	
	public static void parseContract(String filePath) throws IOException {
		InputStream is = new FileInputStream(filePath);
		EVMBLexer lexer = new EVMBLexer(CharStreams.fromStream(is, StandardCharsets.UTF_8));
		EVMBParser parser = new EVMBParser(new CommonTokenStream(lexer));

		parser.program();

		is.close();
	}
	
	/**
	 * Yields the EVM bytecode of a smart contract stored at the address {@code address} 
	 * and stores the result in {@code output}.
	 * 
	 * @param address the address of the smart contract to be parsed
	 * @param output  the directory where the EMV bytecode corresponding to the smart contract
	 * stored at {@code address} is stored
	 */
	public static void parseContractFromEtherscan(String address, String output) {
		// TODO
	}
}
