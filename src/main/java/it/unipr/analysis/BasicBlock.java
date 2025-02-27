package it.unipr.analysis;

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