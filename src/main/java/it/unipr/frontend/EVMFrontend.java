package it.unipr.frontend;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
//import org.antlr.v4.runtime.tree.ParseTree;
import it.unipr.evm.antlr.EVMBParser;
import it.unipr.evm.antlr.EVMBLexer;

public class EVMFrontend {
	
	public static void main(String[] args) throws IOException {
		String result = SMAddress.parseSMAddress("0x6f5bB7cC4F3D6628d0095545552757AB377FE15C");
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
	
	public static void parseContractFromEtherscan(String address, String output) {
		// TODO
	}
}
