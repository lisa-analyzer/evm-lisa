package it.unipr.frontend;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

public class BytecodeToOpcode {
	private static BufferedWriter writer;
	
	public BytecodeToOpcode(String filepath) {
		try {
			writer = new BufferedWriter(new FileWriter(filepath));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	public static void translate(String bytecode) throws IOException {
		for(int i = 2; i < bytecode.length(); i += 2) {
			String opcode = bytecode.substring(i, i + 2);
			if(pushTest(opcode) != 0) {
				String push = bytecode.substring(i + 2, (i + 2 + 2*pushTest(opcode)));
				System.out.println(push);
				addPush(push, pushTest(opcode));
				i += 2*pushTest(opcode);
			}
			System.out.println((opcode));
		}
		writer.close();
	}
	
	private static void addPush(String push, int n) throws IOException {
		for(int i = 0; i < push.length(); i += 2) {
			if(i == 0) {
				writer.write("PUSH" + n + " " + "0x");
			}
			String code = push.substring(i, i + 2);
			writer.write(code);
		}
		writer.write("\n");
	}
	
	private static int pushTest(String opcode) {
		switch(opcode) {
		case "60" : return 1;
		case "61" : return 2;
		case "62" : return 3;
		case "63" : return 4;
		case "64" : return 5;
		case "65" : return 6;
		case "66" : return 7;
		case "67" : return 8;
		case "68" : return 9;
		case "69" : return 10;
		case "6a" : return 11;
		case "6b" : return 12;
		case "6c" : return 13;
		case "6d" : return 14;
		case "6e" : return 15;
		case "6f" : return 16;
		case "70" : return 17;
		case "71" : return 18;
		case "72" : return 19;
		case "73" : return 20;
		case "74" : return 21;
		case "75" : return 22;
		case "76" : return 23;
		case "77" : return 24;
		case "78" : return 25;
		case "79" : return 26;
		case "7a" : return 27;
		case "7b" : return 28;
		case "7c" : return 29;
		case "7d" : return 30;
		case "7e" : return 31;
		case "7f" : return 31;
			default : return 0;
		}
	}
}
