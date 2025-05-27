package it.unipr.utils;

import it.unipr.EVMLiSA;
import it.unipr.analysis.contract.BasicBlock;
import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.Jumpdest;
import it.unipr.cfg.Jumpi;
import it.unipr.cfg.ProgramCounterLocation;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class JSONManager {
	private static final Logger log = LogManager.getLogger(JSONManager.class);

	/**
	 * Loads a JSON object from a file.
	 *
	 * @param filePath the path of the JSON file
	 * 
	 * @return the JSON object parsed from the file, or an empty JSON object in
	 *             case of failure
	 */
	public static JSONObject loadJsonFromFile(Path filePath) {
		try {
			String content = new String(Files.readAllBytes(filePath));

			return new JSONObject(content);
		} catch (IOException e) {
			log.error("Error while reading JSON file {}", filePath, e);
			return new JSONObject();
		}
	}

	/**
	 * Reads statistics from a JSON file and returns them as a set of
	 * StatisticsObject instances.
	 *
	 * @param filePath the path of the JSON file
	 * 
	 * @return a set of StatisticsObject containing the extracted statistics
	 */
	public static Set<StatisticsObject<?>> readStatsFromJSON(Path filePath) {
		Set<StatisticsObject<?>> groundTruthData = new HashSet<>();

		JSONObject groundTruthDataJson = JSONManager.loadJsonFromFile(filePath);
		JSONArray contracts = (JSONArray) groundTruthDataJson.get("smart_contracts");

		for (Object obj : contracts) {
			JSONObject contract = (JSONObject) obj;
			String address = (String) contract.get("address");
			JSONObject statistics;

			try {
				statistics = (JSONObject) contract.get("statistics");
			} catch (Exception e) {
				log.error("There are no statistics for: {}", address);
				continue;
			}

			if (EVMLiSA.isInPaperMode())
				groundTruthData.add(PaperStatisticsObject.newStatisticsObject()
						.address(address)
						.totalOpcodes(statistics.getInt("total_opcodes"))
						.totalJumps(statistics.getInt("total_jumps"))
						.totalEdges(statistics.getInt("total_edges"))
						.resolved(statistics.getInt("resolved_jumps"))
						.unreachable(statistics.getInt("unreachable_jumps"))
						.unknown(statistics.getInt("unknown_jumps"))
						.erroneous(statistics.getInt("erroneous_jumps"))
						.build());

			else
				groundTruthData.add(StandardStatisticsObject.newStatisticsObject()
						.address(address)
						.totalOpcodes(statistics.getInt("total_opcodes"))
						.totalJumps(statistics.getInt("total_jumps"))
						.totalEdges(statistics.getInt("total_edges"))
						.resolvedJumps(statistics.getInt("resolved_jumps"))
						.definitelyUnreachableJumps(statistics.getInt("definitely_unreachable_jumps"))
						.maybeUnreachableJumps(statistics.getInt("maybe_unreachable_jumps"))
						.maybeUnsoundJumps(statistics.getInt("maybe_unsound_jumps"))
						.unsoundJumps(statistics.getInt("unsound_jumps"))
						.build());
		}
		return groundTruthData;
	}

	/**
	 * Aggregates a list of smart contracts into a single JSON object.
	 *
	 * @param contracts the list of smart contracts to aggregate
	 * 
	 * @return a JSON object containing the aggregated contracts
	 */
	public static JSONObject aggregateSmartContractsToJson(List<SmartContract> contracts) {
		JSONObject aggregatedJson = new JSONObject();
		JSONArray contractsArray = new JSONArray();

		for (SmartContract contract : contracts)
			if (contract != null)
				contractsArray.put(contract.toJson());

		aggregatedJson.put("smart_contracts", contractsArray);
		return aggregatedJson;
	}

	/**
	 * Converts the basic blocks of a smart contract into a JSON representation.
	 *
	 * @param contract the smart contract containing the basic blocks
	 * 
	 * @return a JSON array representing the basic blocks
	 */
	public static JSONArray basicBlocksToJson(SmartContract contract) {
		if (contract.getFunctionsSignature() == null) {
			log.warn("Unable to generate CFG with Basic Blocks (contract.getFunctionsSignature() is null)");
			return new JSONArray();
		}
		if (contract.getEventsSignature() == null) {
			log.warn("Unable to generate CFG with Basic Blocks (contract.getEventsSignature() is null)");
			return new JSONArray();
		}

		JSONArray blocksArray = new JSONArray();

		for (BasicBlock block : contract.getBasicBlocks()) {
			JSONObject blockJson = new JSONObject();
			blockJson.put("id", block.getId());

			JSONArray instructionsArray = new JSONArray();
			for (Statement stmt : block.getStatements()) {
				JSONObject instructionJson = new JSONObject();
				int pc = ((ProgramCounterLocation) stmt.getLocation()).getPc();
				instructionJson.put("pc", pc);
				instructionJson.put("instruction", stmt.toString());
				instructionsArray.put(instructionJson);
			}
			blockJson.put("instructions", instructionsArray);

			// Labels
			for (Signature function : contract.getFunctionsSignature())
				for (Statement entryPoint : function.getEntryPoints())
					if (block.contains(entryPoint)) {
						blockJson.put("label", "Function " + function.getSelector());
						block.setBlockType(BasicBlock.BlockType.FUNCTION);
					}
			for (Signature event : contract.getEventsSignature())
				for (Statement entryPoint : event.getEntryPoints())
					if (block.contains(entryPoint)) {
						blockJson.put("label", "Event " + event.getSelector());
						block.setBlockType(BasicBlock.BlockType.EVENT);
					}
			for (Statement entryPoint : contract.getCFG().getEntrypoints())
				if (block.contains(entryPoint))
					blockJson.put("label", "Entry point " + entryPoint.getLocation());

			// Edges
			JSONArray outgoingEdgesArray = new JSONArray();
			for (Integer edgeId : block.getOutgoingEdges()) {
				String color = DOTFileManager.blackColor;
				Statement source = block.getStatements().get(block.getStatements().size() - 1);

				for (BasicBlock b : contract.getBasicBlocks()) {
					if (b.getId() == edgeId) {
						Statement dest = b.getStatements().get(0);
						int sourcePc = ((ProgramCounterLocation) source.getLocation()).getPc();
						int destPc = ((ProgramCounterLocation) dest.getLocation()).getPc();
						if (source instanceof Jumpi
								&& dest instanceof Jumpdest
								&& ((sourcePc + 1) != destPc)) // jumpdest as
																// first opcode
																// in jumpi's
																// false branch
							color = DOTFileManager.greenColor;
						else if (source instanceof Jumpi)
							color = DOTFileManager.redColor;
						else if (block.getBlockType() == BasicBlock.BlockType.JUMP
								&& block.getOutgoingEdges().size() > 1)
							color = DOTFileManager.orangeColor;

						JSONObject edgeJson = new JSONObject();
						edgeJson.put("target", edgeId);
						edgeJson.put("color", color);
						outgoingEdgesArray.put(edgeJson);
						break;
					}
				}
			}
			blockJson.put("outgoing_edges", outgoingEdgesArray);

			// Background color
			BasicBlock.BlockType bbt = block.getBlockType();
			if (bbt == BasicBlock.BlockType.FUNCTION)
				blockJson.put("background_color", DOTFileManager.blueColor);
			else if (bbt == BasicBlock.BlockType.EVENT)
				blockJson.put("background_color", DOTFileManager.purpleColor);
			else {
				block.setBlockType(
						BasicBlock.getBlockType(block.getStatements().get(block.getStatements().size() - 1)));
				bbt = block.getBlockType();
				if (bbt == BasicBlock.BlockType.STOP || bbt == BasicBlock.BlockType.RETURN)
					blockJson.put("background_color", DOTFileManager.lightGreenColor);
				else if (bbt == BasicBlock.BlockType.REVERT || bbt == BasicBlock.BlockType.SELFDESTRUCT
						|| bbt == BasicBlock.BlockType.INVALID)
					blockJson.put("background_color", DOTFileManager.lightRedColor);
				else if (bbt == BasicBlock.BlockType.JUMP && block.getOutgoingEdges().size() > 1)
					blockJson.put("background_color", DOTFileManager.lightOrangeColor);
				else
					blockJson.put("background_color", DOTFileManager.greyColor);
			}

			blockJson.put("last_instruction", block.getBlockType());
			blocksArray.put(blockJson);
		}

		return blocksArray;
	}

	public static JSONObject throwNewError(String error) {
		JSONObject errorJson = new JSONObject();
		errorJson.put("error", error);
		return errorJson;
	}

	public static JSONObject throwNewError(String error, String notes) {
		JSONObject errorJson = new JSONObject();
		errorJson.put("error", error);
		errorJson.put("notes", notes);
		return errorJson;
	}

	public static JSONObject throwNewError(String error, JSONObject notes) {
		JSONObject errorJson = new JSONObject();
		errorJson.put("error", error);
		errorJson.put("notes", notes);
		return errorJson;
	}
}
