package it.unipr.utils;

import it.unipr.analysis.BasicBlock;
import it.unipr.analysis.SmartContract;
import it.unipr.cfg.Jumpdest;
import it.unipr.cfg.Jumpi;
import it.unipr.cfg.ProgramCounterLocation;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.List;
import java.util.Set;
import org.json.JSONArray;
import org.json.JSONObject;

public class JSONManager {
	public static JSONObject aggregateSmartContractsToJson(List<SmartContract> contracts) {
		JSONObject aggregatedJson = new JSONObject();
		JSONArray contractsArray = new JSONArray();

		for (SmartContract contract : contracts)
			if (contract != null)
				contractsArray.put(contract.toJson());

		aggregatedJson.put("smart_contracts", contractsArray);
		return aggregatedJson;
	}

	public static JSONArray basicBlocksToJson(Set<BasicBlock> basicBlocks) {
		String lightGreenColor = "\"#A6EC99\"";
		String greyColor = "\"#D3D3D3\"";
		String lightRed = "\"#EF8683\"";
		JSONArray blocksArray = new JSONArray();

		for (BasicBlock block : basicBlocks) {
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

			// Edges
			JSONArray outgoingEdgesArray = new JSONArray();
			for (Integer edgeId : block.getOutgoingEdges()) {
				String color = "black";
				Statement source = block.getStatements().get(block.getStatements().size() - 1);

				for (BasicBlock b : basicBlocks) {
					if (b.getId() == edgeId) {
						Statement dest = b.getStatements().get(0);

						if (source instanceof Jumpi && dest instanceof Jumpdest)
							color = lightGreenColor;
						else if (source instanceof Jumpi)
							color = lightRed;

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
			block.setBlockType(BasicBlock.getBlockType(block.getStatements().get(block.getStatements().size() - 1))); // update
			BasicBlock.BlockType bbt = block.getBlockType();
			if (bbt == BasicBlock.BlockType.STOP || bbt == BasicBlock.BlockType.RETURN)
				blockJson.put("background_color", lightGreenColor);
			else if (bbt == BasicBlock.BlockType.REVERT
					|| bbt == BasicBlock.BlockType.SELFDESTRUCT
					|| bbt == BasicBlock.BlockType.INVALID)
				blockJson.put("background_color", lightRed);
			else
				blockJson.put("background_color", greyColor);

			blockJson.put("last_instruction", block.getBlockType());

			blocksArray.put(blockJson);
		}

		JSONObject basicBlocksJson = new JSONObject();
		basicBlocksJson.put("basic_blocks", blocksArray);

		return blocksArray;
	}

}
