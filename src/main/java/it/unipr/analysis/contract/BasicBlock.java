package it.unipr.analysis.contract;

import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Ret;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.*;

/**
 * Represents a basic block in an EVM Control Flow Graph. A basic block is a
 * sequence of statements with a single entry point and a single exit point.
 */
public class BasicBlock {

	/**
	 * Unique identifier for the basic block (Program Counter).
	 */
	private final int _id;

	/**
	 * List of statements contained in this basic block.
	 */
	private final List<Statement> _statements;

	/**
	 * Set of identifiers for blocks that can be reached from this block.
	 */
	private final Set<Integer> _outgoingEdges;

	/**
	 * Type of this basic block based on its terminating statement.
	 */
	private BlockType _blockType;

	/**
	 * Enum defining the possible types of basic blocks.
	 */
	public enum BlockType {
		JUMP,
		JUMPI,
		STOP,
		RETURN,
		REVERT,
		SELFDESTRUCT,
		RET,
		JUMPDEST,
		INVALID,
		UNKNOWN,
		SPLITTED,
		FUNCTION,
		EVENT
	}

	/**
	 * Constructs a basic block with the specified identifier.
	 *
	 * @param id The unique identifier (program counter) for this block.
	 */
	public BasicBlock(int id) {
		this._id = id;
		this._statements = new ArrayList<>();
		this._outgoingEdges = new HashSet<>();
	}

	/**
	 * Constructs a basic block with the specified identifier and block type.
	 *
	 * @param id        The unique identifier (program counter) for this block.
	 * @param blockType The type of this basic block.
	 */
	public BasicBlock(int id, BlockType blockType) {
		this._id = id;
		this._statements = new ArrayList<>();
		this._outgoingEdges = new HashSet<>();
		this._blockType = blockType;
	}

	/**
	 * Returns the identifier of this basic block.
	 *
	 * @return The program counter (PC) of this block.
	 */
	public int getId() {
		return _id;
	}

	/**
	 * Returns the list of statements in this basic block.
	 *
	 * @return List of statements contained in this block.
	 */
	public List<Statement> getStatements() {
		return _statements;
	}

	/**
	 * Returns the set of outgoing edge target identifiers.
	 *
	 * @return Set of identifiers for blocks that can be reached from this
	 *             block.
	 */
	public Set<Integer> getOutgoingEdges() {
		return _outgoingEdges;
	}

	/**
	 * Returns the type of this basic block.
	 *
	 * @return The block type.
	 */
	public BlockType getBlockType() {
		return _blockType;
	}

	/**
	 * Adds a statement to this basic block.
	 *
	 * @param statement The statement to add.
	 */
	public void addStatement(Statement statement) {
		_statements.add(statement);
	}

	/**
	 * Adds an outgoing edge to the specified target block.
	 *
	 * @param targetBlockId The identifier of the target block.
	 */
	public void addEdge(int targetBlockId) {
		_outgoingEdges.add(targetBlockId);
	}

	/**
	 * Sets the type of this basic block.
	 *
	 * @param blockType The block type to set.
	 */
	public void setBlockType(BlockType blockType) {
		this._blockType = blockType;
	}

	/**
	 * Determines the block type based on a statement of a block.
	 *
	 * @param stmt The statement in a basic block.
	 * 
	 * @return The appropriate block type for the given statement.
	 */
	public static BlockType getBlockType(Statement stmt) {
		if (stmt instanceof Jump)
			return BasicBlock.BlockType.JUMP;
		else if (stmt instanceof Jumpi)
			return BasicBlock.BlockType.JUMPI;
		else if (stmt instanceof Stop)
			return BasicBlock.BlockType.STOP;
		else if (stmt instanceof Revert)
			return BasicBlock.BlockType.REVERT;
		else if (stmt instanceof Selfdestruct)
			return BasicBlock.BlockType.SELFDESTRUCT;
		else if (stmt instanceof Return)
			return BasicBlock.BlockType.RETURN;
		else if (stmt instanceof Jumpdest)
			return BasicBlock.BlockType.JUMPDEST;
		else if (stmt instanceof Invalid)
			return BasicBlock.BlockType.INVALID;
		else if (stmt instanceof Ret)
			return BasicBlock.BlockType.RET;
		return BasicBlock.BlockType.UNKNOWN;
	}

	/**
	 * Extracts basic blocks from an EVM CFG. Performs a depth-first traversal
	 * to identify basic blocks and handles splitting blocks at jump
	 * destinations.
	 *
	 * @param cfg The EVM control flow graph to analyze.
	 * 
	 * @return A set of basic blocks extracted from the CFG, or an empty set if
	 *             no entry point found.
	 */
	public static Set<BasicBlock> getBasicBlocks(EVMCFG cfg) {
		Statement start = cfg.getEntrypoints().stream().findFirst().orElse(null);
		if (start == null)
			return Collections.emptySet();

		Set<Statement> visited = new HashSet<>();
		Deque<Statement> stack = new ArrayDeque<>();
		stack.push(start);
		Set<BasicBlock> basicBlocks = new HashSet<>();

		while (!stack.isEmpty()) {
			Statement current = stack.pop();
			if (visited.contains(current))
				continue;

			List<Statement> statements = new ArrayList<>();
			Statement blockStart = current;

			while (true) {
				if (current instanceof Jumpdest && !statements.isEmpty()) {
					stack.push(current);
					break;
				}

				statements.add(current);
				visited.add(current);

				Collection<Edge> outgoingEdges = cfg.getOutgoingEdges(current);

				// Terminate block if current statement is an ending type
				if (current instanceof Jump || current instanceof Jumpi ||
						current instanceof Invalid || current instanceof Stop ||
						current instanceof Revert || current instanceof Selfdestruct) {
					for (Edge edge : outgoingEdges) {
						stack.push(edge.getDestination());
					}
					break;
				}

				if (outgoingEdges.isEmpty()) {
					break;
				}

				boolean foundNext = false;
				for (Edge edge : outgoingEdges) {
					Statement next = edge.getDestination();

					if (next == current) {
						continue; // Preserve self-loops
					}

					if (next instanceof Jumpdest) {
						stack.push(next);
						break;
					}

					current = next;
					foundNext = true;
					break;
				}

				if (!foundNext) {
					break;
				}
			}

			int startPc = ((ProgramCounterLocation) blockStart.getLocation()).getPc();
			BasicBlock.BlockType blockType = getBlockType(current);

			BasicBlock basicBlock = new BasicBlock(startPc, blockType);
			for (Statement stmt : statements) {
				basicBlock.addStatement(stmt);
			}

			for (Edge edge : cfg.getOutgoingEdges(current)) {
				int endPc = ((ProgramCounterLocation) edge.getDestination().getLocation()).getPc();
				basicBlock.addEdge(endPc);
				stack.push(edge.getDestination());
			}
			basicBlocks.add(basicBlock);
		}
		
		List<BasicBlock> sortedBlocks = new ArrayList<>(basicBlocks);
		sortedBlocks.sort(Comparator.comparingInt(BasicBlock::getId));
		return new LinkedHashSet<>(sortedBlocks);
	}

	/**
	 * Converts a set of basic blocks to a list of start-end PC pairs.
	 *
	 * @param basicBlocks The set of basic blocks to convert.
	 * 
	 * @return A list of arrays where each array contains [startPC, endPC].
	 */
	public static List<Long[]> basicBlocksToLongArray(Set<BasicBlock> basicBlocks) {
		List<Long[]> bbToLong = new ArrayList<>();
		for (BasicBlock bb : basicBlocks)
			for (Integer end : bb.getOutgoingEdges())
				bbToLong.add(new Long[] { (long) bb.getId(), (long) end });
		return bbToLong;
	}

	/**
	 * Converts a list of start-end PC pairs to a string representation.
	 *
	 * @param bb The list of PC pairs to convert.
	 * 
	 * @return A string representation of the basic block connections.
	 */
	public static String basicBlocksToLongArrayToString(List<Long[]> bb) {
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

	/**
	 * Checks if this basic block contains the specified statement.
	 *
	 * @param stmt The statement to check for.
	 * 
	 * @return true if the statement is present in this block, false otherwise.
	 */
	public boolean contains(Statement stmt) {
		return _statements.contains(stmt);
	}

	@Override
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (o == null || getClass() != o.getClass())
			return false;
		BasicBlock that = (BasicBlock) o;
		return _id == that._id
				&& Objects.equals(_statements, that._statements)
				&& Objects.equals(_outgoingEdges, that._outgoingEdges)
				&& _blockType == that._blockType;
	}

	@Override
	public int hashCode() {
		return Objects.hash(_id, _statements, _outgoingEdges, _blockType);
	}

	@Override
	public String toString() {
		return "BasicBlock{" +
				"id=" + _id +
				", statements=" + _statements +
				", outgoingEdges=" + _outgoingEdges +
				", blockType=" + _blockType +
				'}';
	}
}