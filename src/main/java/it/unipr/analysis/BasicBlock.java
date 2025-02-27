package it.unipr.analysis;

import it.unipr.cfg.*;
import it.unive.lisa.program.cfg.edge.Edge;
import it.unive.lisa.program.cfg.statement.Ret;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.*;

public class BasicBlock {
	private final int id; // Program Counter (PC)
	private final List<Statement> statements;
	private final Set<Integer> outgoingEdges;
	private BlockType blockType;

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
		SPLITTED
	}

	public BasicBlock(int id) {
		this.id = id;
		this.statements = new ArrayList<>();
		this.outgoingEdges = new HashSet<>();
	}

	public BasicBlock(int id, BlockType blockType) {
		this.id = id;
		this.statements = new ArrayList<>();
		this.outgoingEdges = new HashSet<>();
		this.blockType = blockType;
	}

	public int getId() {
		return id;
	}

	public List<Statement> getStatements() {
		return statements;
	}

	public Set<Integer> getOutgoingEdges() {
		return outgoingEdges;
	}

	public BlockType getBlockType() {
		return blockType;
	}

	public void addStatement(Statement statement) {
		statements.add(statement);
	}

	public void addEdge(int targetBlockId) {
		outgoingEdges.add(targetBlockId);
	}

	public void setBlockType(BlockType blockType) {
		this.blockType = blockType;
	}

	public static BlockType getBlockType(Statement lastStatement) {
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
		else if (lastStatement instanceof Invalid)
			return BasicBlock.BlockType.INVALID;
		else if (lastStatement instanceof Ret)
			return BasicBlock.BlockType.RET;
		return BasicBlock.BlockType.UNKNOWN;
	}

	public static Set<BasicBlock> getBasicBlocks(EVMCFG cfg) {
		Statement start = cfg.getEntrypoints().stream().findFirst().orElse(null);
		if (start == null)
			return null;

		Set<Statement> visited = new HashSet<>();
		Deque<Statement> stack = new ArrayDeque<>();
		stack.push(start);
		Set<BasicBlock> basicBlocks = new HashSet<>();

		while (!stack.isEmpty()) {
			Statement current = stack.pop();
			if (visited.contains(current))
				continue;

			Statement blockStart = current;
			Statement blockEnd = current;
			List<Statement> statements = new ArrayList<>();

			while (true) {
				statements.add(blockEnd);
				Collection<Edge> outgoingEdges = cfg.getOutgoingEdges(blockEnd);

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

				if (next instanceof Ret)
					break;

				blockEnd = next;

			}

			int startPc = ((ProgramCounterLocation) blockStart.getLocation()).getPc();
			BasicBlock.BlockType blockType = BasicBlock.getBlockType(blockEnd);

			if (blockType.equals(BasicBlock.BlockType.RET))
				continue;

			BasicBlock basicBlock = new BasicBlock(startPc, blockType);

			for (Statement stmt : statements) {
				basicBlock.addStatement(stmt);
			}

			for (Edge edge : cfg.getOutgoingEdges(blockEnd)) {
				int endPc = ((ProgramCounterLocation) edge.getDestination().getLocation()).getPc();
				if (startPc != endPc
						&& !(edge.getDestination() instanceof Ret)) {
					basicBlock.addEdge(endPc);
				}
			}

			basicBlocks.add(basicBlock);

			for (Edge edge : cfg.getOutgoingEdges(blockEnd)) {
				stack.push(edge.getDestination());
			}
		}

		// Split basic blocks on jumpdest
		Set<BasicBlock> modifiedBlocks = new HashSet<>();
		for (BasicBlock block : basicBlocks) {
			List<Statement> statements = block.getStatements();
			List<Integer> splitIndexes = new ArrayList<>();

			for (int i = 1; i < statements.size(); i++) { // skip the first
				// opcode of the
				// basic block
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
						BasicBlock newBlock = new BasicBlock(newBlockId, BasicBlock.BlockType.SPLITTED);
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

		// TODO check
		Set<BasicBlock> newBlocks = new HashSet<>();
		for (BasicBlock block : basicBlocks) {
			if (block.getStatements().size() > 1
					|| !(block.getStatements().get(0) instanceof Jumpdest))
				newBlocks.add(block);
		}

		basicBlocks = newBlocks;
		return basicBlocks;
	}

	public static List<Long[]> basicBlocksToLongArray(Set<BasicBlock> basicBlocks) {
		List<Long[]> bbToLong = new ArrayList<>();
		for (BasicBlock bb : basicBlocks)
			for (Integer end : bb.getOutgoingEdges())
				bbToLong.add(new Long[] { (long) bb.getId(), (long) end });
		return bbToLong;
	}

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

	@Override
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (o == null || getClass() != o.getClass())
			return false;
		BasicBlock that = (BasicBlock) o;
		return id == that.id && Objects.equals(statements, that.statements)
				&& Objects.equals(outgoingEdges, that.outgoingEdges) && blockType == that.blockType;
	}

	@Override
	public int hashCode() {
		return Objects.hash(id, statements, outgoingEdges, blockType);
	}

	@Override
	public String toString() {
		return "BasicBlock{" +
				"id=" + id +
				", statements=" + statements +
				", outgoingEdges=" + outgoingEdges +
				", blockType=" + blockType +
				'}';
	}
}