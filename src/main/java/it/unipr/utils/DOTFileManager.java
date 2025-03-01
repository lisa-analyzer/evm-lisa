package it.unipr.utils;

import java.io.FileWriter;
import java.io.IOException;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class DOTFileManager {
	private static final Logger log = LogManager.getLogger(DOTFileManager.class);
	public static String purpleColor = "\"#A97FB2\"";
	public static String lightGreenColor = "\"#A6EC99\"";
	public static String greenColor = "\"#5F9747\"";
	public static String greyColor = "\"#D3D3D3\"";
	public static String lightRedColor = "\"#EF8683\"";
	public static String redColor = "\"#B70000\"";
	public static String lightOrangeColor = "\"#FFB38A\"";
	public static String orangeColor = "\"#FF9248\"";
	public static String blueColor = "\"#6FA8DC\"";
	public static String blackColor = "\"#000000\"";

	public static void generateDotGraph(JSONArray basicBlocks, String outputPath) {
		StringBuilder dotGraph = new StringBuilder();
		dotGraph.append("digraph CFG {\n");
		dotGraph.append("\trankdir=TB;\n");

		// Nodes
		for (int i = 0; i < basicBlocks.length(); i++) {
			JSONObject block = basicBlocks.getJSONObject(i);
			int id = block.getInt("id");
			String backgroundColor = block.optString("background_color", "white");
			JSONArray instructions = block.getJSONArray("instructions");

			StringBuilder label = new StringBuilder();
			if (block.has("label"))
				label.append(block.getString("label")).append("\\n- - - - - - - - - - - -\\n");

			if (instructions.length() > 5) {
				JSONObject firstInstr = instructions.getJSONObject(0);
				JSONObject secondInstr = instructions.getJSONObject(1);
				JSONObject secondLastInstr = instructions.getJSONObject(instructions.length() - 2);
				JSONObject lastInstr = instructions.getJSONObject(instructions.length() - 1);

				label.append(firstInstr.getInt("pc")).append(": ").append(firstInstr.getString("instruction"))
						.append("\\l");
				label.append(secondInstr.getInt("pc")).append(": ").append(secondInstr.getString("instruction"))
						.append("\\l");
				label.append("...\n");
				label.append(secondLastInstr.getInt("pc")).append(": ").append(secondLastInstr.getString("instruction"))
						.append("\\l");
				label.append(lastInstr.getInt("pc")).append(": ").append(lastInstr.getString("instruction"))
						.append("\\l");
			} else {
				for (int j = 0; j < instructions.length(); j++) {
					JSONObject instr = instructions.getJSONObject(j);
					label.append(instr.getInt("pc")).append(": ")
							.append(instr.getString("instruction")).append("\\l");
				}
			}

			dotGraph.append(String.format(
					"\t%d [label=\"%s\", shape=box, style=filled, fillcolor=%s];\n",
					id, label.toString(), backgroundColor));
		}

		// Edges
		for (int i = 0; i < basicBlocks.length(); i++) {
			JSONObject block = basicBlocks.getJSONObject(i);
			int id = block.getInt("id");
			JSONArray outgoingEdges = block.getJSONArray("outgoing_edges");

			for (int j = 0; j < outgoingEdges.length(); j++) {
				JSONObject edge = outgoingEdges.getJSONObject(j);
				int targetId = edge.getInt("target");
				String color = edge.getString("color");

				// Unreachable jump
				if (color == null || color.isEmpty()) {
					dotGraph.append(String.format(
							"\t%d [label=\"%s\", shape=box, style=filled, fillcolor=%s];\n",
							targetId, targetId + ": Unreachable jump", purpleColor));
					color = purpleColor;
				}

				dotGraph.append(String.format(
						"\t%d -> %d [color=%s];\n", id, targetId, color));
			}
		}

		// Legend
		dotGraph.append("\tsubgraph cluster_legend {\n");
		dotGraph.append("\t\tlabel=\"Legend\";\n");
		dotGraph.append("\t\tstyle=dotted;\n");
		dotGraph.append("\t\tnode [shape=plaintext];\n");
		dotGraph.append(
				"\t\t\"legend\" [label=<<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\" cellborder=\"0\">\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">black edge&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.blackColor).append(">sequential edge</font></td></tr>\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">green edge&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.greenColor).append(">true edge</font></td></tr>\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">red edge&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.redColor).append(">false edge</font></td></tr>\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">orange edge&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.orangeColor).append(">sequential multiple edge</font></td></tr>\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">green background&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.lightGreenColor).append(">correct termination</font></td></tr>\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">red background&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.lightRedColor).append(">error termination</font></td></tr>\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">orange background&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.lightOrangeColor).append(">jump to multiple blocks</font></td></tr>\n");
		dotGraph.append("\t\t\t<tr><td align=\"right\">blue background&nbsp;</td><td align=\"left\"><font color=")
				.append(DOTFileManager.blueColor).append(">function entrypoint</font></td></tr>\n");
		dotGraph.append("\t\t</table>>];\n");
		dotGraph.append("\t}\n");

		dotGraph.append("}\n");

		try (FileWriter writer = new FileWriter(outputPath)) {
			writer.write(dotGraph.toString());
//			log.info(".dot file successfully written in {}", outputPath);
		} catch (IOException e) {
			log.error("Error writing .dot file: {}", e.getMessage());
		}
	}
}
