package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.BasicBlock;
import it.unipr.analysis.contract.SmartContract;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

public class EVMoleComparator {
	private static final Logger log = LogManager.getLogger(EVMoleComparator.class);

	/*
	 * Contract: 0x903fa079b93d2bb222eafcf1f59d0a9b628d354a
	 */
	@Test
	public void testComparator() throws Exception {
		int stackSize = 32;
		int stackSetSize = 8;

		String bytecode = "0x608060405234801561001057600080fd5b50600436106100415760003560e01c80630ff49b90146100465780632a3126371461006f578063f19371b714610082575b600080fd5b6100596100543660046102a3565b6100a2565b6040516100669190610366565b60405180910390f35b61005961007d36600461026f565b610144565b61009561009036600461024e565b610165565b60405161006691906102e5565b6100aa6101fe565b6100b2610169565b336001600160a01b0316639f43ddd26040518163ffffffff1660e01b815260040160206040518083038186803b1580156100eb57600080fd5b505afa1580156100ff573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061012391906102cd565b82101561013b576101346002610196565b905061013e565b50815b92915050565b61014c6101fe565b610154610169565b61015e6001610196565b9392505050565b5090565b60005460ff166101945760405162461bcd60e51b815260040161018b9061032f565b60405180910390fd5b565b61019e6101fe565b6040805160208101909152806101bc84670de0b6b3a76400006101c4565b905292915050565b6000826101d35750600061013e565b828202828482816101e057fe5b041461015e5760405162461bcd60e51b815260040161018b906102ee565b6040518060200160405280600081525090565b600060208284031215610222578081fd5b6040516020810181811067ffffffffffffffff82111715610241578283fd5b6040529135825250919050565b60008060408385031215610260578182fd5b50508035926020909101359150565b60008060408385031215610281578182fd5b61028b8484610211565b915061029a8460208501610211565b90509250929050565b600080604083850312156102b5578182fd5b6102bf8484610211565b946020939093013593505050565b6000602082840312156102de578081fd5b5051919050565b90815260200190565b60208082526021908201527f536166654d6174683a206d756c7469706c69636174696f6e206f766572666c6f6040820152607760f81b606082015260800190565b6020808252601f908201527f5265656e7472616e637947756172643a207265656e7472616e742063616c6c00604082015260600190565b905181526020019056fea26469706673582212200ac6554b1051bc58204626570bf67f9dc0add0f946e4ecc591b9f8343ad58e7064736f6c634300060c0033";
		String edgesEVMole = "[(0, 16), (0, 12), (16, 65), (16, 26), (26, 70), (26, 43), (43, 111), (43, 54), (54, 130), (54, 65), (70, 675), (84, 162), (89, 870), (111, 623), (125, 324), (130, 590), (144, 357), (149, 741), (162, 510), (170, 361), (178, 235), (178, 231), (235, 255), (235, 246), (255, 717), (291, 315), (291, 299), (299, 406), (308, 318), (315, 318), (318, 89), (318, 444), (318, 89), (324, 510), (332, 361), (340, 406), (350, 444), (350, 89), (357, 149), (361, 404), (361, 372), (372, 815), (404, 178), (404, 340), (406, 510), (414, 452), (444, 308), (444, 350), (452, 467), (452, 460), (460, 318), (467, 480), (467, 479), (480, 350), (480, 487), (487, 750), (510, 170), (510, 332), (510, 414), (529, 546), (529, 543), (546, 577), (546, 574), (577, 651), (577, 703), (577, 666), (590, 608), (590, 605), (608, 144), (623, 641), (623, 638), (641, 529), (651, 529), (666, 125), (675, 693), (675, 690), (693, 529), (703, 84), (717, 734), (717, 731), (734, 291), (741, 102), (750, 395), (815, 395), (870, 102)]";

		List<Long[]> evmole = parseLongArrayList(edgesEVMole);

		SmartContract sc = new SmartContract().setBytecode(bytecode);
		EVMLiSA.setStackLimit(stackSize);
		EVMLiSA.setStackSetSize(stackSetSize);
		EVMLiSA.analyzeContract(sc);
		List<Long[]> evmlisa = BasicBlock.basicBlocksToLongArray(BasicBlock.getBasicBlocks(sc.getCFG()));

		log.info("Bytecode: {}", bytecode);
		log.info("stack size: {}", stackSize);
		log.info("stack set size: {}", stackSetSize);

		compareLists(evmlisa, evmole);
	}

	public static void compareLists(List<Long[]> evmlisa, List<Long[]> evmole) {
		Set<String> setEvmole = new HashSet<>();
		Set<String> setEvmlisa = new HashSet<>();

		log.debug("EVMLiSA bb: {}", BasicBlock.basicBlocksToLongArrayToString(evmlisa));
		log.debug("EVMole bb: {}", BasicBlock.basicBlocksToLongArrayToString(evmole));

		for (Long[] arr : evmole) {
			setEvmole.add(Arrays.toString(arr));
		}
		for (Long[] arr : evmlisa) {
			setEvmlisa.add(Arrays.toString(arr));
		}

		for (String arr : setEvmlisa) {
			if (!setEvmole.contains(arr)) {
				System.out.println("Missing in evmole: " + arr);
			}
		}
		for (String arr : setEvmole) {
			if (!setEvmlisa.contains(arr)) {
				System.out.println("Missing in evmlisa: " + arr);
			}
		}

		log.debug("EVMLiSA edges: {}", setEvmlisa.size());
		log.debug("EVMole edges: {}", setEvmole.size());
	}

	public List<Long[]> parseLongArrayList(String input) {
		List<Long[]> result = new ArrayList<>();
		Pattern pattern = Pattern.compile("\\((\\d+),\\s*(\\d+)\\)");
		Matcher matcher = pattern.matcher(input);

		while (matcher.find()) {
			long first = Long.parseLong(matcher.group(1));
			long second = Long.parseLong(matcher.group(2));
			result.add(new Long[] { first, second });
		}

		return result;
	}
}
