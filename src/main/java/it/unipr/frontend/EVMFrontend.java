package it.unipr.frontend;

import it.unipr.evm.antlr.EVMBLexer;
import it.unipr.evm.antlr.EVMBParser;
import it.unipr.evm.antlr.EVMBParser.ProgramContext;
import it.unive.lisa.AnalysisException;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.CFG;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Writer;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;

/**
 * Frontend for EVMLiSA that handles both obtaining the bytecode of a contract
 * via Etherscan (@see <a href="https://etherscan.io/apis">Etherscan API</a>)
 * and the parsing of the bytecode to generate the control flow graph of the
 * contract. Ehterscan API key must be stored in the environment variable:
 * ETHERSCAN_API_KEY.
 */
public class EVMFrontend {

	/**
	 * TODO: Refactor these strings and understand if they are still needed.
	 */
	private static String FROM_0417_TO_058 = "a165627a7a72305820";
	private static String FROM_0417_TO_058_EXPERIMENTAL = "a265627a7a72305820";
	private static String FROM_059_TO_0511 = "a265627a7a72305820";
	private static String FROM_059_TO_0511_EXPERIMENTAL = "a365627a7a72305820";
	private static String FROM_0512_TO_0515 = "a265627a7a72315820";
	private static String FROM_0512_TO_0515_EXPERIMENTAL = "a365627a7a72315820";
	private static String FROM_060_TO_061 = "a264697066735822";
	private static String FROM_062_TO_LATEST = "a264697066735822";

	/**
	 * Verifies the syntactic correctness of the smart contract bytecode stored
	 * in {@code filePath} and returns its {@code ProgramContext}.
	 * 
	 * @param filePath the path where the smart contract bytecode is stored
	 * 
	 * @return the {@code ProgramContext} of the smart contract bytecode
	 * 
	 * @throws IOException
	 */
	public static ProgramContext parseContract(String filePath) throws IOException {
		InputStream fileInputStream = new FileInputStream(filePath);

		EVMBLexer lexer = new EVMBLexer(CharStreams.fromStream(fileInputStream, StandardCharsets.UTF_8));
		EVMBParser parser = new EVMBParser(new CommonTokenStream(lexer));

		try {
			return parser.program();
		} finally {
			fileInputStream.close();
		}
	}

	/**
	 * Yields the EVM bytecode of a smart contract stored at {@code address} and
	 * stores the result in {@code output}.
	 * 
	 * @param address the address of the smart contract to be parsed.
	 * @param output  the directory where the EMV bytecode that correlates with
	 *                    the smart contract stored at {@code address} is
	 *                    stored.
	 * 
	 * @return {@code true} if the bytecode was successfully downloaded and
	 *             stored, false otherwise.
	 * 
	 * @throws IOException
	 */
	public static boolean parseContractFromEtherscan(String address, String output) throws IOException {
		String bytecodeRequest = etherscanRequest("proxy", "eth_getCode", address);

		if (bytecodeRequest == null || bytecodeRequest.isEmpty()) {
			System.err.println("ERROR: couldn't download contract's bytecode, output file won't be created.");
			return false;
		}

		String[] test = bytecodeRequest.split("\"");
		String bytecode = test[9];

		BufferedWriter writer = new BufferedWriter(new FileWriter(output));

		for (int i = 2; i < bytecode.length(); i += 2) {

			if (bytecode.substring(i, (i + 18)).equals(FROM_0417_TO_058)
					|| bytecode.substring(i, (i + 18)).equals(FROM_0417_TO_058_EXPERIMENTAL)
					|| bytecode.substring(i, (i + 18)).equals(FROM_059_TO_0511)
					|| bytecode.substring(i, (i + 18)).equals(FROM_059_TO_0511_EXPERIMENTAL)
					|| bytecode.substring(i, (i + 18)).equals(FROM_0512_TO_0515)
					|| bytecode.substring(i, (i + 18)).equals(FROM_0512_TO_0515_EXPERIMENTAL)
					|| bytecode.substring(i, (i + 16)).equals(FROM_060_TO_061)
					|| bytecode.substring(i, (i + 16)).equals(FROM_062_TO_LATEST)) {

				writer.close();
				return true;
			}

			String opcode = bytecode.substring(i, i + 2);

			int t = pushTest(opcode);

			if (t != 0) {
				String push = bytecode.substring(i + 2, (i + 2 + 2 * t));

				for (int j = i + 2; j < (i + 2 + 2 * t); j += 2) {

					if (bytecode.substring(j, (j + 18)).equals(FROM_0417_TO_058)
							|| bytecode.substring(j, (j + 18)).equals(FROM_0417_TO_058_EXPERIMENTAL)
							|| bytecode.substring(j, (j + 18)).equals(FROM_059_TO_0511)
							|| bytecode.substring(j, (j + 18)).equals(FROM_059_TO_0511_EXPERIMENTAL)
							|| bytecode.substring(j, (j + 18)).equals(FROM_0512_TO_0515)
							|| bytecode.substring(j, (j + 18)).equals(FROM_0512_TO_0515_EXPERIMENTAL)
							|| bytecode.substring(j, (j + 16)).equals(FROM_060_TO_061)
							|| bytecode.substring(j, (j + 16)).equals(FROM_062_TO_LATEST)) {

						writer.close();
						return true;
					}
				}

				addPush(push, t, writer);
				i += 2 * t;
			}

			else {
				addOpcode(opcode, writer);
			}
		}

		writer.close();

		System.out.println(writer);

		return true;
	}

	/**
	 * Yelds the EVM bytecode of a smart contract stored at the address
	 * {@code contractAddress} and generates its CFG as a {@code Program}.
	 * 
	 * @param contractAddress the address of the smart contract of interest
	 * 
	 * @return a LiSA {@code Program} representing the generated CFG
	 * 
	 * @throws IOException
	 * @throws AnalysisException
	 */
	public static Program generateCfgFromContraOutputctAddress(String contractAddress)
			throws IOException, AnalysisException {
		final String BYTECODE_OUTFILE_PATH = "evm-outputs/tmp/" + contractAddress + "_bytecode.sol";

		// Get bytecode from Etherscan
		new File(BYTECODE_OUTFILE_PATH).getParentFile().mkdirs();

		boolean parseResult = EVMFrontend.parseContractFromEtherscan(contractAddress, BYTECODE_OUTFILE_PATH);

		if (!parseResult) {
			return null;
		}

		// Parse bytecode to generate CFG
		return EVMFrontend.generateCfgFromFile(BYTECODE_OUTFILE_PATH);
	}

	/**
	 * Takes the smart contract bytecode stored in {@code filePath} and
	 * generates its control flow graph which is then returned as a LiSA
	 * {@code Program}.
	 * 
	 * @param filePath the path where the smart contract bytecode is stored
	 * 
	 * @return a LiSA {@code Program} representing the generated control flow
	 *             graph
	 * 
	 * @throws IOException
	 */
	public static Program generateCfgFromFile(String filePath) throws IOException {
		Program program = new Program(new EVMFeatures(), new EVMTypeSystem());
		EVMCFGGenerator cfggenerator = new EVMCFGGenerator(filePath, program);
		ProgramContext programContext = EVMFrontend.parseContract(filePath);

		CFG cfg = cfggenerator.visitProgram(programContext);
		program.addCodeMember(cfg);

		return program;
	}

	/**
	 * Helper method that maps the EVM opcodes to their corresponding
	 * instruction.
	 * 
	 * @param opcode
	 * @param writer
	 * 
	 * @throws IOException
	 */
	private static void addOpcode(String opcode, Writer writer) throws IOException {
		switch (opcode) {
		case "00":
			writer.write("STOP\n");
			break;
		case "01":
			writer.write("ADD\n");
			break;
		case "02":
			writer.write("MUL\n");
			break;
		case "03":
			writer.write("SUB\n");
			break;
		case "04":
			writer.write("DIV\n");
			break;
		case "05":
			writer.write("SDIV\n");
			break;
		case "06":
			writer.write("MOD\n");
			break;
		case "07":
			writer.write("SMOD\n");
			break;
		case "08":
			writer.write("ADDMOD\n");
			break;
		case "09":
			writer.write("MULMOD\n");
			break;
		case "0a":
			writer.write("EXP\n");
			break;
		case "0b":
			writer.write("SIGNEXTEND\n");
			break;
		case "10":
			writer.write("LT\n");
			break;
		case "11":
			writer.write("GT\n");
			break;
		case "12":
			writer.write("SLT\n");
			break;
		case "13":
			writer.write("SGT\n");
			break;
		case "14":
			writer.write("EQ\n");
			break;
		case "15":
			writer.write("ISZERO\n");
			break;
		case "16":
			writer.write("AND\n");
			break;
		case "17":
			writer.write("OR\n");
			break;
		case "18":
			writer.write("XOR\n");
			break;
		case "19":
			writer.write("NOT\n");
			break;
		case "1a":
			writer.write("BYTE\n");
			break;
		case "1b":
			writer.write("SHL\n");
			break;
		case "1c":
			writer.write("SHR\n");
			break;
		case "1d":
			writer.write("SAR\n");
			break;
		case "20":
			writer.write("SHA3\n");
			break;
		case "30":
			writer.write("ADDRESS\n");
			break;
		case "31":
			writer.write("BALANCE\n");
			break;
		case "32":
			writer.write("ORIGIN\n");
			break;
		case "33":
			writer.write("CALLER\n");
			break;
		case "34":
			writer.write("CALLVALUE\n");
			break;
		case "35":
			writer.write("CALLDATALOAD\n");
			break;
		case "36":
			writer.write("CALLDATASIZE\n");
			break;
		case "37":
			writer.write("CALLDATACOPY\n");
			break;
		case "38":
			writer.write("CODESIZE\n");
			break;
		case "39":
			writer.write("CODECOPY\n");
			break;
		case "3a":
			writer.write("GASPRICE\n");
			break;
		case "3b":
			writer.write("EXTCODESIZE\n");
			break;
		case "3c":
			writer.write("EXTCODECOPY\n");
			break;
		case "3d":
			writer.write("RETURNDATASIZE\n");
			break;
		case "3e":
			writer.write("RETURNDATACOPY\n");
			break;
		case "3f":
			writer.write("EXTCODEHASH\n");
			break;
		case "40":
			writer.write("BLOCKHASH\n");
			break;
		case "41":
			writer.write("COINBASE\n");
			break;
		case "42":
			writer.write("TIMESTAMP\n");
			break;
		case "43":
			writer.write("NUMBER\n");
			break;
		case "44":
			writer.write("DIFFICULTY\n");
			break;
		case "45":
			writer.write("GASLIMIT\n");
			break;
		case "46":
			writer.write("CHAINID\n");
			break;
		case "47":
			writer.write("SELFBALANCE\n");
			break;
		case "48":
			writer.write("BASEFEE\n");
			break;
		case "49":
		case "4f":
			writer.write("INVALID\n");
			break;
		case "50":
			writer.write("POP\n");
			break;
		case "51":
			writer.write("MLOAD\n");
			break;
		case "52":
			writer.write("MSTORE\n");
			break;
		case "53":
			writer.write("MSTORE8\n");
			break;
		case "54":
			writer.write("SLOAD\n");
			break;
		case "55":
			writer.write("SSTORE\n");
			break;
		case "56":
			writer.write("JUMP\n");
			break;
		case "57":
			writer.write("JUMPI\n");
			break;
		case "58":
			writer.write("PC\n");
			break;
		case "59":
			writer.write("MSIZE\n");
			break;
		case "5a":
			writer.write("GAS\n");
			break;
		case "5b":
			writer.write("JUMPDEST\n");
			break;
		case "5f":
			writer.write("PUSH0\n");
			break;
		case "80":
			writer.write("DUP1\n");
			break;
		case "81":
			writer.write("DUP2\n");
			break;
		case "82":
			writer.write("DUP3\n");
			break;
		case "83":
			writer.write("DUP4\n");
			break;
		case "84":
			writer.write("DUP5\n");
			break;
		case "85":
			writer.write("DUP6\n");
			break;
		case "86":
			writer.write("DUP7\n");
			break;
		case "87":
			writer.write("DUP8\n");
			break;
		case "88":
			writer.write("DUP9\n");
			break;
		case "89":
			writer.write("DUP10\n");
			break;
		case "8a":
			writer.write("DUP11\n");
			break;
		case "8b":
			writer.write("DUP12\n");
			break;
		case "8c":
			writer.write("DUP13\n");
			break;
		case "8d":
			writer.write("DUP14\n");
			break;
		case "8e":
			writer.write("DUP15\n");
			break;
		case "8f":
			writer.write("DUP16\n");
			break;
		case "90":
			writer.write("SWAP1\n");
			break;
		case "91":
			writer.write("SWAP2\n");
			break;
		case "92":
			writer.write("SWAP3\n");
			break;
		case "93":
			writer.write("SWAP4\n");
			break;
		case "94":
			writer.write("SWAP5\n");
			break;
		case "95":
			writer.write("SWAP6\n");
			break;
		case "96":
			writer.write("SWAP7\n");
			break;
		case "97":
			writer.write("SWAP8\n");
			break;
		case "98":
			writer.write("SWAP9\n");
			break;
		case "99":
			writer.write("SWAP10\n");
			break;
		case "9a":
			writer.write("SWAP11\n");
			break;
		case "9b":
			writer.write("SWAP12\n");
			break;
		case "9c":
			writer.write("SWAP13\n");
			break;
		case "9d":
			writer.write("SWAP14\n");
			break;
		case "9e":
			writer.write("SWAP15\n");
			break;
		case "9f":
			writer.write("SWAP16\n");
			break;
		case "a0":
			writer.write("LOG0\n");
			break;
		case "a1":
			writer.write("LOG1\n");
			break;
		case "a2":
			writer.write("LOG2\n");
			break;
		case "a3":
			writer.write("LOG3\n");
			break;
		case "a4":
			writer.write("LOG4\n");
			break;
		case "f0":
			writer.write("CREATE\n");
			break;
		case "f1":
			writer.write("CALL\n");
			break;
		case "f2":
			writer.write("CALLCODE\n");
			break;
		case "f3":
			writer.write("RETURN\n");
			break;
		case "f4":
			writer.write("DELEGATECALL\n");
			break;
		case "f5":
			writer.write("CREATE2\n");
			break;
		case "fa":
			writer.write("STATICCALL\n");
			break;
		case "fd":
			writer.write("REVERT\n");
			break;
		case "fe":
			writer.write("INVALID\n");
			break;
		case "ff":
			writer.write("SELFDESTRUCT\n");
			break;
		default:
			writer.write("'" + opcode + "'" + "(Unknown Opcode)\n");
			break;
		}
	}

	private static int pushTest(String opcode) {
		switch (opcode) {
		case "60":
			return 1;
		case "61":
			return 2;
		case "62":
			return 3;
		case "63":
			return 4;
		case "64":
			return 5;
		case "65":
			return 6;
		case "66":
			return 7;
		case "67":
			return 8;
		case "68":
			return 9;
		case "69":
			return 10;
		case "6a":
			return 11;
		case "6b":
			return 12;
		case "6c":
			return 13;
		case "6d":
			return 14;
		case "6e":
			return 15;
		case "6f":
			return 16;
		case "70":
			return 17;
		case "71":
			return 18;
		case "72":
			return 19;
		case "73":
			return 20;
		case "74":
			return 21;
		case "75":
			return 22;
		case "76":
			return 23;
		case "77":
			return 24;
		case "78":
			return 25;
		case "79":
			return 26;
		case "7a":
			return 27;
		case "7b":
			return 28;
		case "7c":
			return 29;
		case "7d":
			return 30;
		case "7e":
			return 31;
		case "7f":
			return 32;
		default:
			return 0;
		}
	}

	private static void addPush(String push, int n, Writer writer) throws IOException {
		for (int i = 0; i < push.length(); i += 2) {
			if (i == 0) {
				writer.write("PUSH" + n + " " + "0x");
			}
			String code = push.substring(i, i + 2);
			writer.write(code);
		}
		writer.write("\n");
	}

	private static String etherscanRequest(String module, String action, String address) throws IOException {
		// Get the API key from the environment variable
		final String API_KEY = System.getenv("ETHERSCAN_API_KEY");

		// Check if API key was retrieved correctly from the environment
		// variable
		if (API_KEY == null || API_KEY.isEmpty()) {
			System.err.println("ERROR: couldn't retrieve ETHERSCAN_API_KEY environment variable from your system.");
			return null;
		}

		// Send request to Etherscan
		String request = String.format("https://api.etherscan.io/api?module=%s&action=%s&address=%s&apikey=%s", module,
				action, address, API_KEY);

		URL requestUrl = new URL(request);
		HttpURLConnection connection = (HttpURLConnection) requestUrl.openConnection();
		connection.setRequestMethod("GET");
		connection.setRequestProperty("User-Agent", "Mozilla/5.0");

		if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
			BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
			StringBuilder sb = new StringBuilder();
			String readLine = null;

			while ((readLine = in.readLine()) != null) {
				sb.append(readLine);
			}

			in.close();
			String result = sb.toString();

			// Check for error
			if (errorInResponse(result)) {
				return null;
			} else {
				return result;
			}
		} else {
			return null;
		}
	}

	private static boolean errorInResponse(String content) {
		final String EtherscanGenericErrorMsg = "\"message\":\"NOTOK\"";
		final String EtherscanInvalidAPIKeyErrorMsg = "\"result\":\"Invalid API Key\"";

		if (content.contains(EtherscanGenericErrorMsg)) {
			if (content.contains(EtherscanInvalidAPIKeyErrorMsg)) {
				System.err.println("ERROR: invalid Etherscan API key.");
			} else {
				System.err.println("ERROR: generic Etherscan API error.");
			}

			return true;
		} else {
			return false;
		}
	}
}
