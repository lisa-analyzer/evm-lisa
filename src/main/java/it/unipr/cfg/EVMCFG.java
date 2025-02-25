package it.unipr.cfg;

import it.unipr.EVMLiSA;
import it.unipr.analysis.BasicBlock;
import it.unipr.analysis.MyCache;
import it.unipr.analysis.Number;
import it.unipr.cfg.push.Push;
import it.unive.lisa.analysis.AbstractState;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.AnalyzedCFG;
import it.unive.lisa.analysis.OptimizedAnalyzedCFG;
import it.unive.lisa.analysis.StatementStore;
import it.unive.lisa.analysis.heap.HeapDomain;
import it.unive.lisa.analysis.type.TypeDomain;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.conf.FixpointConfiguration;
import it.unive.lisa.conf.LiSAConfiguration.DescendingPhaseType;
import it.unive.lisa.interprocedural.InterproceduralAnalysis;
import it.unive.lisa.interprocedural.ScopeId;
import it.unive.lisa.program.ProgramValidationException;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.fixpoints.CFGFixpoint.CompoundState;
import it.unive.lisa.program.cfg.fixpoints.OptimizedFixpoint;
import it.unive.lisa.program.cfg.statement.Ret;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.util.collections.workset.WorkingSet;
import it.unive.lisa.util.datastructures.graph.algorithms.Fixpoint;
import it.unive.lisa.util.datastructures.graph.algorithms.FixpointException;
import it.unive.lisa.util.datastructures.graph.code.NodeList;

import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.stream.Collectors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONObject;

public class EVMCFG extends CFG {
	private static final Logger log = LogManager.getLogger(EVMCFG.class);

	private Set<Statement> jumpDestsNodes;
	private Set<Statement> jumpNodes;
	private Set<Statement> pushedJumps;
	private Set<Statement> sstores;
	private Set<Number> jumpDestsNodesLocations;
	private Set<BasicBlock> basicBlocks;

	/**
	 * Builds a EVMCFG starting from its description.
	 *
	 * @param cfgDesc the EVMCFG description
	 */
	public EVMCFG(CodeMemberDescriptor cfgDesc) {
		super(cfgDesc);
	}

	public void computeHotspotNodes() {
		this.jumpDestsNodes = new HashSet<Statement>();
		this.jumpNodes = new HashSet<Statement>();
		this.pushedJumps = new HashSet<Statement>();
		this.sstores = new HashSet<Statement>();

		NodeList<CFG, Statement, Edge> cfgNodeList = this.getNodeList();

		for (Statement statement : cfgNodeList.getNodes()) {
			if (statement instanceof Sstore)
				sstores.add(statement);
			else if (statement instanceof Jumpdest)
				jumpDestsNodes.add(statement);
			else if ((statement instanceof Jump) || (statement instanceof Jumpi)) {
				jumpNodes.add(statement);
			}

		}

		for (Edge edge : cfgNodeList.getEdges())
			if ((edge.getDestination() instanceof Jump || edge.getDestination() instanceof Jumpi)
					&& (edge.getSource() instanceof Push))
				pushedJumps.add(edge.getDestination());
	}

	/**
	 * Returns a set of all the SSTORE statements in the CFG. SSTORE
	 *
	 * @return a set of all the SSTORE statements in the CFG
	 */
	public Set<Statement> getAllSstore() {
		return sstores;
	}

	/**
	 * Returns a set of all the JUMPDEST statements in the CFG.
	 *
	 * @return a set of all the JUMPDEST statements in the CFG
	 */
	public Set<Statement> getAllJumpdest() {
		return jumpDestsNodes;
	}

	/**
	 * Yields the program counters of all JUMPDEST statements.
	 *
	 * @return the program counters of all JUMPDEST statements
	 */
	public Set<Number> getAllJumpdestLocations() {
		if (jumpDestsNodesLocations == null)
			return jumpDestsNodesLocations = this.jumpDestsNodes.stream()
					.map(j -> new Number(((ProgramCounterLocation) j.getLocation()).getPc()))
					.collect(Collectors.toSet());
		else
			return jumpDestsNodesLocations;

	}

	/**
	 * Returns a set of all the JUMP and JUMPI statements in the CFG.
	 *
	 * @return a set of all the JUMP and JUMPI statements in the CFG
	 */
	public Set<Statement> getAllJumps() {
		return jumpNodes;
	}

	public int getOpcodeCount() {
		// -1 for the return statement, that it does not correspond to an actual
		// statement of the smart contract, but it is added by EVMLiSA
		return this.getNodesCount() - 1;
	}

	/**
	 * Returns a set of all the JUMP statements preceded by a PUSH statement in
	 * the CFG.
	 *
	 * @return a set of all the JUMP statements preceded by a PUSH statement in
	 *             the CFG
	 */
	public Set<Statement> getAllPushedJumps() {
		return pushedJumps;
	}

	@Override
	public <A extends AbstractState<A>> AnalyzedCFG<A> fixpoint(
			AnalysisState<A> singleton, Map<Statement, AnalysisState<A>> startingPoints,
			InterproceduralAnalysis<A> interprocedural, WorkingSet<Statement> ws,
			FixpointConfiguration conf,
			ScopeId id) throws FixpointException {
		// we disable optimizations for ascending phases if there is a
		// descending one: the latter will need full results to start applying
		// glbs/narrowings from a post-fixpoint
		boolean isOptimized = conf.optimize && conf.descendingPhaseType == DescendingPhaseType.NONE;
		Fixpoint<CFG, Statement, Edge, CompoundState<A>> fix = isOptimized
				? new OptimizedFixpoint<>(this, false, conf.hotspots)
				: new Fixpoint<>(this, false);
		EVMAscendingFixpoint<A> asc = new EVMAscendingFixpoint<>(this, interprocedural,
				conf.wideningThreshold);

		Map<Statement, CompoundState<A>> starting = new HashMap<>();
		StatementStore<A> bot = new StatementStore<>(singleton.bottom());
		startingPoints.forEach((st, state) -> starting.put(st, CompoundState.of(state, bot)));
		Map<Statement, CompoundState<A>> ascending = fix.fixpoint(starting, ws, asc);

		if (conf.descendingPhaseType == DescendingPhaseType.NONE)
			return flatten(isOptimized, singleton, startingPoints, interprocedural, id, ascending);

		fix = conf.optimize ? new OptimizedFixpoint<>(this, true, conf.hotspots) : new Fixpoint<>(this, true);
		Map<Statement, CompoundState<A>> descending;
		switch (conf.descendingPhaseType) {
		case GLB:
			// DescendingGLBFixpoint<A> dg = new DescendingGLBFixpoint<>(this,
			// conf.glbThreshold,
			// interprocedural);
			// descending = fix.fixpoint(starting, ws, dg, ascending);
			// break;
		case NARROWING:
			// DescendingNarrowingFixpoint<A> dn = new
			// DescendingNarrowingFixpoint<>(this, interprocedural);
			// descending = fix.fixpoint(starting, ws, dn, ascending);
			// break;
		case NONE:
		default:
			// should never happen
			descending = ascending;
			break;
		}

		return flatten(conf.optimize, singleton, startingPoints, interprocedural, id, descending);
	}

	private <V extends ValueDomain<V>,
			T extends TypeDomain<T>,
			A extends AbstractState<A>,
			H extends HeapDomain<H>> AnalyzedCFG<A> flatten(
					boolean isOptimized, AnalysisState<A> singleton,
					Map<Statement, AnalysisState<A>> startingPoints,
					InterproceduralAnalysis<A> interprocedural, ScopeId id,
					Map<Statement, CompoundState<A>> fixpointResults) {
		Map<Statement, AnalysisState<A>> finalResults = new HashMap<>(fixpointResults.size());
		for (Entry<Statement, CompoundState<A>> e : fixpointResults.entrySet()) {
			finalResults.put(e.getKey(), e.getValue().postState);
			for (Entry<Statement, AnalysisState<A>> ee : e.getValue().intermediateStates)
				finalResults.put(ee.getKey(), ee.getValue());
		}

		return isOptimized
				? new OptimizedAnalyzedCFG<A>(this, id, singleton, startingPoints, finalResults,
						interprocedural)
				: new AnalyzedCFG<>(this, id, singleton, startingPoints, finalResults);
	}

	@Override
	public void validate() throws ProgramValidationException {
		try {
			list.validate(entrypoints);
		} catch (ProgramValidationException e) {
			// we allow having nodes without incoming edges to not be entry
			// points
			if (!e.getMessage().contains("Unreachable node that is not marked as entrypoint:"))
				throw new ProgramValidationException("The matrix behind " + this + " is invalid", e);
		}

		// all entrypoints should be within the cfg
		if (!list.getNodes().containsAll(entrypoints))
			throw new ProgramValidationException(this + " has entrypoints that are not part of the graph: "
					+ new HashSet<>(entrypoints).retainAll(list.getNodes()));
	}

	/**
	 * Checks if the target statement is reachable from the start statement
	 * using depth-first search (DFS). Caches results to avoid redundant
	 * computations.
	 *
	 * @param start  The starting statement.
	 * @param target The target statement.
	 * 
	 * @return True if the target is reachable from the start, false otherwise.
	 */
	public boolean reachableFrom(Statement start, Statement target) {
		String key = this.hashCode() + "" + start.hashCode() + "" + target.hashCode();
		if (MyCache.getInstance().existsInReachableFrom(key)) {
			return MyCache.getInstance().isReachableFrom(key);
		}

		boolean result = dfs(start, target, new HashSet<>());
		MyCache.getInstance().addReachableFrom(key, result);
		return result;
	}

	/**
	 * Performs a depth-first search (DFS) to determine if the target statement
	 * is reachable from the start statement.
	 *
	 * @param start   The starting statement.
	 * @param target  The target statement.
	 * @param visited A set of visited statements to avoid cycles.
	 * 
	 * @return True if the target is reachable from the start, false otherwise.
	 */
	private boolean dfs(Statement start, Statement target, Set<Statement> visited) {
		Deque<Statement> stack = new ArrayDeque<>();
		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (current.equals(target))
				return true;

			if (visited.add(current)) {
				for (Edge edge : list.getOutgoingEdges(current)) {
					Statement next = edge.getDestination();
					if (!visited.contains(next))
						stack.push(next);
				}
			}
		}

		return false;
	}

	/**
	 * Finds the furthest reachable SSTORE statements from a given start
	 * statement using BFS.
	 *
	 * @param start The starting statement.
	 * 
	 * @return A set of the furthest reachable SSTORE statements.
	 */
	public Set<Statement> getFurthestSstores(Statement start) {
		Deque<Statement> queue = new ArrayDeque<>();
		Set<Statement> visited = new HashSet<>();
		Set<Statement> last = new HashSet<>();

		queue.add(start);
		visited.add(start);

		while (!queue.isEmpty()) {
			Statement current = queue.poll();
			if (current instanceof Sstore) {
				last.add(current);
			}

			for (Edge edge : list.getOutgoingEdges(current)) {
				Statement next = edge.getDestination();
				if (visited.add(next)) {
					queue.add(next);
				}
			}
		}
		return last;
	}

	/**
	 * Checks if the target statement is reachable from the start statement
	 * following only sequential edges. Ignores jumps.
	 *
	 * @param start  The starting statement.
	 * @param target The target statement.
	 * 
	 * @return True if the target is sequentially reachable from the start,
	 *             false otherwise.
	 */
	public boolean reachableFromSequentially(Statement start, Statement target) {
		String key = this.hashCode() + "" + start.hashCode() + "" + target.hashCode() + "sequentially";
		if (MyCache.getInstance().existsInReachableFrom(key)) {
			return MyCache.getInstance().isReachableFrom(key);
		}

		boolean result = dfsSequential(start, target, new HashSet<>());
		MyCache.getInstance().addReachableFrom(key, result);
		return result;
	}

	/**
	 * Performs a depth-first search (DFS) to determine if the target statement
	 * is sequentially reachable from the start statement. Ignores jumps.
	 *
	 * @param start   The starting statement.
	 * @param target  The target statement.
	 * @param visited A set of visited statements to avoid cycles.
	 * 
	 * @return True if the target is sequentially reachable from the start,
	 *             false otherwise.
	 */
	private boolean dfsSequential(Statement start, Statement target, Set<Statement> visited) {
		Deque<Statement> stack = new ArrayDeque<>();
		stack.push(start);

		while (!stack.isEmpty()) {
			Statement current = stack.pop();

			if (current.equals(target))
				return true;

			if (visited.add(current)) {
				for (Edge edge : list.getOutgoingEdges(current)) {
					if (edge.getSource() instanceof Jumpi || edge.getSource() instanceof Jump)
						continue;
					Statement next = edge.getDestination();
					if (!visited.contains(next))
						stack.push(next);
				}
			}
		}

		return false;
	}

	public static String bbToString(List<Long[]> bb) {
		StringBuilder sb = new StringBuilder();
		sb.append("[");

		boolean first = true;
		for (Long[] l : bb) {
			if (!first)
				sb.append(", ");

			sb.append("(").append(l[0]).append(", ").append(l[1]).append(")");
			first = false;
		}

		sb.append("]");
		return sb.toString();
	}

	public List<Long[]> basicBlocksToLongArray(){
		basicBlocks = basicBlocks();
		List<Long[]> bbToLong = new ArrayList<>();
		for (BasicBlock bb : basicBlocks)
			for(Integer end : bb.getOutgoingEdges())
				bbToLong.add(new Long[]{(long) bb.getId(), (long) end});
		return bbToLong;
	}

	public Set<BasicBlock> basicBlocks() {
		Statement start = this.getEntrypoints().stream().findFirst().orElse(null);
		if (start == null)
			return null;

		Set<Statement> visited = new HashSet<>();
		Deque<Statement> stack = new ArrayDeque<>();
		stack.push(start);
		basicBlocks = new HashSet<>();

		while (!stack.isEmpty()) {
			Statement current = stack.pop();
			if (visited.contains(current))
				continue;

			Statement blockStart = current;
			Statement blockEnd = current;
			List<Statement> statements = new ArrayList<>();

			while (true) {
				statements.add(blockEnd);
				Collection<Edge> outgoingEdges = list.getOutgoingEdges(blockEnd);

				if (outgoingEdges.isEmpty()
						|| blockEnd instanceof Jump
						|| blockEnd instanceof Jumpi
						|| blockEnd instanceof Invalid
						|| blockEnd instanceof Stop
						|| blockEnd instanceof Revert
						|| blockEnd instanceof Selfdestruct
						|| blockEnd instanceof Ret) {
					break;
				}

				Statement next = outgoingEdges.iterator().next().getDestination();
				if (visited.contains(next))
					break;

				visited.add(next);

				if(next instanceof Ret)
					break;

				blockEnd = next;

			}

			int startPc = ((ProgramCounterLocation) blockStart.getLocation()).getPc();
			BasicBlock.BlockType blockType = getBlockType(blockEnd);

			if(blockType.equals(BasicBlock.BlockType.RET))
				continue;

			BasicBlock basicBlock = new BasicBlock(startPc, blockType);

			for (Statement stmt : statements) {
				basicBlock.addStatement(stmt);
			}

			for (Edge edge : getOutgoingEdges(blockEnd)) {
				int endPc = ((ProgramCounterLocation) edge.getDestination().getLocation()).getPc();
				if (startPc != endPc
						&& !(edge.getDestination() instanceof Ret)) {
					basicBlock.addEdge(endPc);
				}
			}

			basicBlocks.add(basicBlock);

			for (Edge edge : list.getOutgoingEdges(blockEnd)) {
				stack.push(edge.getDestination());
			}
		}

		// Split basic blocks on jumpdest
		Set<BasicBlock> modifiedBlocks = new HashSet<>();
		for (BasicBlock block : basicBlocks) {
			List<Statement> statements = block.getStatements();
			List<Integer> splitIndexes = new ArrayList<>();

			for (int i = 1; i < statements.size() - 1; i++) {
				if (statements.get(i) instanceof Jumpdest) {
					splitIndexes.add(i);
				}
			}

			if (!splitIndexes.isEmpty()) {
				BasicBlock currentBlock = new BasicBlock(block.getId(), block.getBlockType());
				modifiedBlocks.add(currentBlock);

				for (int i = 0; i < statements.size(); i++) {
					if (splitIndexes.contains(i)) {
						int newBlockId = ((ProgramCounterLocation) statements.get(i).getLocation()).getPc();
						BasicBlock newBlock = new BasicBlock(newBlockId, block.getBlockType());
						modifiedBlocks.add(newBlock);

						currentBlock.addEdge(newBlockId);

						currentBlock = newBlock;
					}

					currentBlock.addStatement(statements.get(i));
				}

				currentBlock.getOutgoingEdges().addAll(block.getOutgoingEdges());
			} else {
				modifiedBlocks.add(block);
			}
		}

		basicBlocks = modifiedBlocks;

		// Remove basic blocks with only an instruction
		Set<BasicBlock> newBlocks = new HashSet<>();
		for (BasicBlock block : basicBlocks) {
			log.debug("id: {} {}", block.getId(), block.getStatements().size());
			if(block.getStatements().size() > 1)
				newBlocks.add(block);
		}

		basicBlocks = newBlocks;
		return basicBlocks;
	}

	private BasicBlock.BlockType getBlockType(Statement lastStatement) {
		if (lastStatement instanceof Jump)
			return BasicBlock.BlockType.JUMP;
		else if (lastStatement instanceof Jumpi)
			return BasicBlock.BlockType.JUMPI;
		else if (lastStatement instanceof Stop)
			return BasicBlock.BlockType.STOP;
		else if (lastStatement instanceof Revert)
			return BasicBlock.BlockType.REVERT;
		else if (lastStatement instanceof Selfdestruct)
			return BasicBlock.BlockType.SELFDESTRUCT;
		else if (lastStatement instanceof Return)
			return BasicBlock.BlockType.RETURN;
		else if (lastStatement instanceof Jumpdest)
			return BasicBlock.BlockType.JUMPDEST;
		else return BasicBlock.BlockType.RET;
	}

	public JSONArray basicBlocksToJson() {
		String lightGreenColor = "\"#A6EC99\"";
		String greyColor = "\"#D3D3D3\"";
		String lightRed = "\"#EF8683\"";
		basicBlocks = basicBlocks();
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

			JSONArray outgoingEdgesArray = new JSONArray();
			for (Integer edgeId : block.getOutgoingEdges()) {
				outgoingEdgesArray.put(edgeId);
			}
			blockJson.put("outgoing_edges", outgoingEdgesArray);

			BasicBlock.BlockType bbt = block.getBlockType();
			if (bbt == BasicBlock.BlockType.STOP
					|| bbt == BasicBlock.BlockType.RETURN)
				blockJson.put("background_color", lightGreenColor);
			else if (bbt == BasicBlock.BlockType.REVERT
					|| bbt == BasicBlock.BlockType.SELFDESTRUCT)
				blockJson.put("background_color", lightRed);
			else
				blockJson.put("background_color", greyColor);

			blockJson.put("last_instruction", block.getBlockType());

			String edgeColor = lightRed;
			if (block.getStatements().get(0) instanceof Jumpdest)
				edgeColor = lightGreenColor;

			for (BasicBlock prevBlock : basicBlocks) {
				if (prevBlock.getOutgoingEdges().contains(block.getId())) {
					Statement lastStatement = prevBlock.getStatements().get(prevBlock.getStatements().size() - 1);
					if (lastStatement instanceof Jump) {
						edgeColor = "black";
						break;
					}
				}
			}
			blockJson.put("ingoing_edge_color", edgeColor);

			blocksArray.put(blockJson);
		}

		JSONObject basicBlocksJson = new JSONObject();
		basicBlocksJson.put("basic_blocks", blocksArray);

		return blocksArray;
	}

	public static void generateDotGraph(JSONArray basicBlocks, String outputPath) {
		String purpleColor = "\"#A97FB2\"";
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
			if (instructions.length() > 5) {
				JSONObject firstInstr = instructions.getJSONObject(0);
				JSONObject secondInstr = instructions.getJSONObject(1);
				JSONObject secondLastInstr = instructions.getJSONObject(instructions.length() - 2);
				JSONObject lastInstr = instructions.getJSONObject(instructions.length() - 1);

				label.append(firstInstr.getInt("pc")).append(": ").append(firstInstr.getString("instruction")).append("\\l");
				label.append(secondInstr.getInt("pc")).append(": ").append(secondInstr.getString("instruction")).append("\\l");
				label.append("...\n");
				label.append(secondLastInstr.getInt("pc")).append(": ").append(secondLastInstr.getString("instruction")).append("\\l");
				label.append(lastInstr.getInt("pc")).append(": ").append(lastInstr.getString("instruction")).append("\\l");
			} else {
				for (int j = 0; j < instructions.length(); j++) {
					JSONObject instr = instructions.getJSONObject(j);
					label.append(instr.getInt("pc")).append(": ")
							.append(instr.getString("instruction")).append("\\l");
				}
			}

			dotGraph.append(String.format(
					"\t%d [label=\"%s\", shape=box, style=filled, fillcolor=%s];\n",
					id, label.toString(), backgroundColor
			));
		}

		// Edge color mapping
		Map<Integer, String> colorMapping = new HashMap<>();
		for (int i = 0; i < basicBlocks.length(); i++) {
			JSONObject block = basicBlocks.getJSONObject(i);
			int id = block.getInt("id");
			colorMapping.put(id, block.getString("ingoing_edge_color"));
		}

		// Edges
		for (int i = 0; i < basicBlocks.length(); i++) {
			JSONObject block = basicBlocks.getJSONObject(i);
			int id = block.getInt("id");
			JSONArray outgoingEdges = block.getJSONArray("outgoing_edges");
			String edgeColor = block.optString("ingoing_edge_color", "black");

			for (int j = 0; j < outgoingEdges.length(); j++) {
				int targetId = outgoingEdges.getInt(j);
				String color = colorMapping.get(targetId);

				// Unreachable jump
				if (color == null) {
					dotGraph.append(String.format(
							"\t%d [label=\"%s\", shape=box, style=filled, fillcolor=%s];\n",
							targetId,  targetId + ": Unreachable jump", purpleColor
					));
					color = purpleColor;
				}

				dotGraph.append(String.format(
						"\t%d -> %d [color=%s];\n", id, targetId, color
				));
			}
		}

		dotGraph.append("}\n");

		try (FileWriter writer = new FileWriter(outputPath)) {
			writer.write(dotGraph.toString());
			log.info("DOT file successfully written to {}", outputPath);
		} catch (IOException e) {
			log.error("Error writing DOT file: {}", e.getMessage());
		}
	}
}