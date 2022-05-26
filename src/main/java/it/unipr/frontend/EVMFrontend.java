package it.unipr.frontend;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
//import org.antlr.v4.runtime.tree.ParseTree;

import it.unipr.evm.antlr.EVMBLexer;
import it.unipr.evm.antlr.EVMBParser;

public class EVMFrontend {
	
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
