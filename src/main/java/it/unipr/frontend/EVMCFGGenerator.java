package it.unipr.frontend;

import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.tree.TerminalNode;

import it.unipr.cfg.Stop;
import it.unipr.evm.antlr.EVMBParser.OpcodesContext;
import it.unipr.evm.antlr.EVMBParser.ProgramContext;
import it.unipr.evm.antlr.EVMBParserBaseVisitor;
import it.unive.lisa.program.CompilationUnit;
import it.unive.lisa.program.SourceCodeLocation;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CFGDescriptor;
import it.unive.lisa.program.cfg.Parameter;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.statement.Statement;

public class EVMCFGGenerator extends EVMBParserBaseVisitor<Object> {

	private CFG cfg;
	
	private String filePath;
	
	/**
	 * Yields the line position of a parse rule.
	 * 
	 * @param ctx the parse rule
	 * 
	 * @return yields the line position of a parse rule
	 */
	static protected int getLine(ParserRuleContext ctx) {
		return ctx.getStart().getLine();
	}

	/**
	 * Yields the line position of a terminal node.
	 * 
	 * @param ctx the terminal node
	 * 
	 * @return yields the line position of a terminal node
	 */
	static protected int getLine(TerminalNode ctx) {
		return ctx.getSymbol().getLine();
	}

	/**
	 * Yields the column position of a parse rule.
	 * 
	 * @param ctx the parse rule
	 * 
	 * @return yields the column position of a parse rule
	 */
	static protected int getCol(ParserRuleContext ctx) {
		return ctx.getStop().getCharPositionInLine();
	}

	/**
	 * Yields the column position of a terminal node.
	 * 
	 * @param ctx the terminal node
	 * 
	 * @return yields the column position of a terminal node
	 */
	static protected int getCol(TerminalNode ctx) {
		return ctx.getSymbol().getCharPositionInLine();
	}

	/**
	 * Yields the source code location of a parse rule.
	 * 
	 * @param ctx the parse rule
	 * 
	 * @return yields the source code location of a parse rule
	 */
	protected SourceCodeLocation locationOf(ParserRuleContext ctx) {
		return new SourceCodeLocation(filePath, getLine(ctx), getCol(ctx));
	}

	@Override
	public CFG visitProgram(ProgramContext ctx) {
		CompilationUnit unit = new CompilationUnit(null, null, false);
		CFGDescriptor cfgDesc = new CFGDescriptor(null, unit, false, null, new Parameter[]{});
		this.cfg =  new CFG(cfgDesc);
		
		Statement last = null;
		
		for (int i = 0; i < ctx.opcodes().size(); i++) {
			OpcodesContext opCtx = ctx.opcodes(i);
			Statement st = visitOpcodes(opCtx);
			cfg.addNode(st);
		
			if (last != null)
				cfg.addEdge(new SequentialEdge(last, st));
			else
				cfg.getEntrypoints().add(st);
		}
		
		return cfg;
	}

	@Override
	public Statement visitOpcodes(OpcodesContext ctx) {
		if (ctx.STOP() != null)
			return new Stop(cfg, locationOf(ctx));
		return null;
	}
}
