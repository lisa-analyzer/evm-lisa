package it.unipr.utils;

import it.unipr.analysis.BasicBlock;
import it.unipr.analysis.Signature;
import it.unipr.analysis.SmartContract;
import it.unipr.cfg.Jumpdest;
import it.unipr.cfg.Jumpi;
import it.unipr.cfg.ProgramCounterLocation;
import it.unive.lisa.program.cfg.statement.Statement;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class JSONManager {
	private static final Logger log = LogManager.getLogger(JSONManager.class);

	public static JSONObject loadJsonFromFile(Path filePath) {
		try {
			String content = new String(Files.readAllBytes(filePath));

			return new JSONObject(content);
		} catch (IOException e) {
			log.error("Error while reading JSON file {}", filePath, e);
			return new JSONObject();
		}
	}

	public static JSONObject aggregateSmartContractsToJson(List<SmartContract> contracts) {
		JSONObject aggregatedJson = new JSONObject();
		JSONArray contractsArray = new JSONArray();

		for (SmartContract contract : contracts)
			if (contract != null)
				contractsArray.put(contract.toJson());

		aggregatedJson.put("smart_contracts", contractsArray);
		return aggregatedJson;
	}

	public static JSONArray basicBlocksToJson(SmartContract contract) {
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
			for (Statement entryPoint : contract.getCFG().getEntrypoints())
				if (block.contains(entryPoint))
					blockJson.put("label", "Entry point " + entryPoint.getLocation());

			// Edges
			JSONArray outgoingEdgesArray = new JSONArray();
			for (Integer edgeId : block.getOutgoingEdges()) {
				String color = "black";
				Statement source = block.getStatements().get(block.getStatements().size() - 1);

				for (BasicBlock b : contract.getBasicBlocks()) {
					if (b.getId() == edgeId) {
						Statement dest = b.getStatements().get(0);
						if (source instanceof Jumpi && dest instanceof Jumpdest)
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
}
