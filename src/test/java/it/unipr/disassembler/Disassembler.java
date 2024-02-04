package it.unipr.disassembler;

import it.unipr.disassembler.iterators.StringTwoCharIterator;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * The Disassembler class is responsible for disassembling Ethereum bytecode
 * into human-readable opcodes. It parses the bytecode and provides information
 * about each opcode, including its definition and parameters.
 * <p>
 * The Disassembler class includes functionality to clean the input bytecode,
 * load opcodes, and print information about unknown opcodes at the end of the
 * disassembly. It uses the Opcodes and Opcode classes to represent opcode
 * definitions and instances.
 * <p>
 * The class provides methods to retrieve the original bytecode, contract
 * metadata, disassembled code, and a list of opcodes. Additionally, it exposes
 * the ability to print information about unknown opcodes encountered during the
 * disassembly process.
 */
public class Disassembler {
	private static final String CONTRACT_METADATA_PREFIX = "a165627a7a72305820";
	private String code;
	private String contractMetadata;
	private String disassembledCode = "";
	private final List<Opcode> opcodes = new ArrayList<>();
	private final Set<String> unknownOpcodes = new HashSet<>();

	public Disassembler(String code) {
		String[] codeStripped = cleanData(code);
		this.code = codeStripped[0];
		if (codeStripped.length > 1) {
			this.contractMetadata = CONTRACT_METADATA_PREFIX + codeStripped[1];
		}
		loadOpcodes();
	}

	public static String[] cleanData(String code) {
		if (code.startsWith("0x")) {
			code = code.substring(2);
		}
		return code.split(CONTRACT_METADATA_PREFIX);
	}

	private void loadOpcodes() {
		StringTwoCharIterator iterator = new StringTwoCharIterator(code);
		StringBuilder disassembledCodeBuilder = new StringBuilder();
		int offset = 0;

		while (iterator.hasNext()) {
			String nextByte = iterator.next();
			Opcode opcode = new Opcode();
			opcode.setOffset(offset);

			// System.out.println("nextByte: " + nextByte);

			Integer opcodeHex = Integer.valueOf(nextByte, 16);
			Opcodes opcodeDefinition = Opcodes.getOpcode(opcodeHex);

			if (opcodeDefinition == null) {
				// System.out.println("Unknown opcode (in Hex): " + nextByte);
				unknownOpcodes.add(nextByte);
				opcode.setOpcode(Opcodes.UNKNOWN);
			} else {
				opcode.setOpcode(opcodeDefinition);
				Integer parametersNum = opcodeDefinition.getParametersNum();

				if (parametersNum > 0) {
					offset += parametersNum;

					String opParameter = getParameter(parametersNum, iterator);
					String parameterString = opParameter.replaceAll("0x", "");

					if ("".equals(parameterString)) {
						opcode.setOpcode(Opcodes.UNKNOWN);
					} else {
						opcode.setParameter(new BigInteger(parameterString, 16));
					}
				}
			}
			offset++;
			opcodes.add(opcode);
			disassembledCodeBuilder.append(opcode.toString()).append(System.lineSeparator());
		}
		this.disassembledCode = disassembledCodeBuilder.toString();

		printUnknownOpcodes();
	}

	public String getCode() {
		return code;
	}

	public String getContractMetadata() {
		return contractMetadata;
	}

	public String getDisassembledCode() {
		return disassembledCode;
	}

	public List<Opcode> getOpcodes() {
		return opcodes;
	}

	private static String getParameter(int parametersNum, StringTwoCharIterator iterator) {
		StringBuilder sb = new StringBuilder("0x");
		int i = 0;
		while (i < parametersNum && iterator.hasNext()) {
			String next = iterator.next();
			sb.append(next);
			i++;
		}
		return sb.toString();
	}

	public void printUnknownOpcodes() {
		if (unknownOpcodes.size() > 0) {
			System.out.println("Unknown opcodes (in Hex):");
			for (String unknownOpcode : unknownOpcodes)
				System.out.println("\t opcode: " + unknownOpcode);
		}
	}
}