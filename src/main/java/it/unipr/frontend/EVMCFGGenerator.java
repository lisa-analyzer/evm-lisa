package it.unipr.frontend;

import it.unipr.cfg.*;
import it.unipr.cfg.Byte;
import it.unipr.cfg.Number;
import it.unipr.cfg.push.Push;
import it.unipr.cfg.push.Push0;
import it.unipr.cfg.push.Push1;
import it.unipr.cfg.push.Push10;
import it.unipr.cfg.push.Push11;
import it.unipr.cfg.push.Push12;
import it.unipr.cfg.push.Push13;
import it.unipr.cfg.push.Push14;
import it.unipr.cfg.push.Push15;
import it.unipr.cfg.push.Push16;
import it.unipr.cfg.push.Push17;
import it.unipr.cfg.push.Push18;
import it.unipr.cfg.push.Push19;
import it.unipr.cfg.push.Push2;
import it.unipr.cfg.push.Push20;
import it.unipr.cfg.push.Push21;
import it.unipr.cfg.push.Push22;
import it.unipr.cfg.push.Push23;
import it.unipr.cfg.push.Push24;
import it.unipr.cfg.push.Push25;
import it.unipr.cfg.push.Push26;
import it.unipr.cfg.push.Push27;
import it.unipr.cfg.push.Push28;
import it.unipr.cfg.push.Push29;
import it.unipr.cfg.push.Push3;
import it.unipr.cfg.push.Push30;
import it.unipr.cfg.push.Push31;
import it.unipr.cfg.push.Push32;
import it.unipr.cfg.push.Push4;
import it.unipr.cfg.push.Push5;
import it.unipr.cfg.push.Push6;
import it.unipr.cfg.push.Push7;
import it.unipr.cfg.push.Push8;
import it.unipr.cfg.push.Push9;
import it.unipr.evm.antlr.EVMBParser.OpcodesContext;
import it.unipr.evm.antlr.EVMBParser.ProgramContext;
import it.unipr.evm.antlr.EVMBParserBaseVisitor;
import it.unive.lisa.program.ClassUnit;
import it.unive.lisa.program.Program;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.Parameter;
import it.unive.lisa.program.cfg.edge.FalseEdge;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.edge.TrueEdge;
import it.unive.lisa.program.cfg.statement.Ret;
import it.unive.lisa.program.cfg.statement.Statement;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import org.apache.commons.io.FilenameUtils;

/**
 * Provides methods to generate a CFG from a smart contract.
 */
public class EVMCFGGenerator extends EVMBParserBaseVisitor<Object> {

	private CFG cfg;
	private int pc = 0; // Program counter

	private final String filePath;
	private final Program program;

	/**
	 * Default constructor for the EVMCFGGenerator class.
	 *
	 * @param filePath the path of the file containing the smart contract.
	 * @param program  the LiSA program referred to the smart contract.
	 */
	public EVMCFGGenerator(String filePath, Program program) {
		this.filePath = filePath;
		this.program = program;
	}

	/**
	 * {@inheritDoc} Given a program context, retrieves the opcodes and creates
	 * statements for each of them to build the CFG of the program.
	 * 
	 * @param ctx the context of the program.
	 * 
	 * @return the CFG of the program.
	 */
	@Override
	public CFG visitProgram(ProgramContext ctx) {
		// Create a descriptor for the initial CFG.
		ClassUnit unit = new ClassUnit(new ProgramCounterLocation(-1, -1), program, "program", false);
		String normalizedFilePath = FilenameUtils.separatorsToUnix(filePath);
		CodeMemberDescriptor cfgDesc = new CodeMemberDescriptor(new ProgramCounterLocation(-1, -1), unit, false,
				normalizedFilePath, new Parameter[] {});

		// Save the CFG in the class variable.
		this.cfg = new EVMCFG(cfgDesc);

		Statement last = null;

		// Create a list to store the statements of the CFG.
		// Retrieve the first statement (entrypoint) of the CFG.
		ArrayList<Statement> stm = new ArrayList<>();
		OpcodesContext opCtx = ctx.opcodes(0);
		Statement st = this.visitOpcodes(opCtx);
		stm.add(st);
		cfg.addNode(st);
		cfg.getEntrypoints().add(st);
		last = st;

		Map<Statement, BigInteger> map = new HashMap<>();

		// For each opcode of the program, create a statement and add it to the
		// CFG.
		for (int i = 1; i < ctx.opcodes().size(); i++) {
			opCtx = ctx.opcodes(i);
			st = this.visitOpcodes(opCtx);

			cfg.addNode(st);
			stm.add(st);

			/*
			 * If the actual statement is a JUMPI, a conditional edge
			 * (FalseEdge) is created between the last statement and the actual
			 * one. Otherwise, a sequential edge (SequentialEdge) is created.
			 */

			if (st instanceof Jumpi && last instanceof Push)
				map.put(st, ((Push) last).getInt());

			if (st instanceof Jump && last instanceof Push)
				map.put(st, ((Push) last).getInt());

			if (last instanceof Jumpi)
				cfg.addEdge(new FalseEdge(last, st));

			if (!(last instanceof Revert)
					&& !(last instanceof Return)
					&& !(last instanceof Stop)
					&& !(last instanceof Selfdestruct)
					&& !(last instanceof Invalid)
					&& !(last instanceof Jump)
					&& !(last instanceof Jumpi))
				cfg.addEdge(new SequentialEdge(last, st));

			last = st;
		}

		for (Statement node : cfg.getNodes())
			for (Entry<Statement, BigInteger> entry : map.entrySet())
				if (((ProgramCounterLocation) node.getLocation()).getPc() == entry.getValue().intValue())
					if (entry.getKey() instanceof Jumpi)
						cfg.addEdge(new TrueEdge(entry.getKey(), node));
					else
						cfg.addEdge(new SequentialEdge(entry.getKey(), node));

		// The last statement of the CFG is a return statement
		Ret ret = new Ret(cfg, new ProgramCounterLocation(pc++, -1));
		cfg.addNode(ret);
		cfg.addEdge(new SequentialEdge(st, ret));

		// REVERT nodes must be linked to return statement
		for (Statement stmt : cfg.getNodes()) {
			if (stmt instanceof Revert
					|| stmt instanceof Return
					|| stmt instanceof Stop
					|| stmt instanceof Selfdestruct
					|| stmt instanceof Invalid)
				cfg.addEdge(new SequentialEdge(stmt, ret));
		}

		unit.addCodeMember(cfg);

		return cfg;
	}

	/**
	 * Helper method to retrieve the line of the program where the opcode is
	 */
	private static int getLine(OpcodesContext ctx) {
		return ctx.getStart().getLine();
	}

	public static String getFirstToken(String input) {
		String[] tokens = input.split(" ");
		return tokens[0];
	}

	/**
	 * {@inheritDoc} Given an opcode context, creates the corresponding
	 * statement. It takes into account the program counter to set the location
	 * of the statement.
	 * 
	 * @param ctx the context of the opcode.
	 * 
	 * @return the statement corresponding to the opcode.
	 * 
	 * @throws UnsupportedOperationException if the opcode is not supported.
	 */
	@Override
	public Statement visitOpcodes(OpcodesContext ctx) throws UnsupportedOperationException {
		String token = getFirstToken(ctx.start.getText());

		switch (token) {
		case "STOP":
			return new Stop(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "ADD":
			return new Add(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "MUL":
			return new Mul(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SUB":
			return new Sub(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DIV":
			return new Div(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SDIV":
			return new Sdiv(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "MOD":
			return new Mod(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SMOD":
			return new Smod(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "ADDMOD":
			return new Addmod(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "MULMOD":
			return new Mulmod(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "EXP":
			return new Exp(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SIGNEXTEND":
			return new Signextend(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "LT":
			return new Lt(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "GT":
			return new Gt(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SLT":
			return new Slt(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SGT":
			return new Sgt(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "EQ":
			return new Eq(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "ISZERO":
			return new Iszero(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "AND":
			return new And(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "OR":
			return new Or(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "XOR":
			return new Xor(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "NOT":
			return new Not(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "BYTE":
			return new Byte(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SHL":
			return new Shl(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SHR":
			return new Shr(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SAR":
			return new Sar(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SHA3":
			return new Sha3(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "ADDRESS":
			return new Address(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "BALANCE":
			return new Balance(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "ORIGIN":
			return new Origin(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALLER":
			return new Caller(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALLVALUE":
			return new Callvalue(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CODECOPY":
			return new Codecopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALLDATALOAD":
			return new Calldataload(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALLDATASIZE":
			return new Calldatasize(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALLDATACOPY":
			return new Calldatacopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CODESIZE":
			return new Codesize(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "GASPRICE":
			return new Gasprice(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "EXTCODESIZE":
			return new Extcodesize(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "EXTCODECOPY":
			return new Extcodecopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "RETURNDATASIZE":
			return new Returndatasize(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "RETURNDATACOPY":
			return new Returndatacopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "EXTCODEHASH":
			return new Extcodehash(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "BLOCKHASH":
			return new Blockhash(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "COINBASE":
			return new Coinbase(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "TIMESTAMP":
			return new Timestamp(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "NUMBER":
			return new Number(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DIFFICULTY":
			return new Difficulty(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "GASLIMIT":
			return new Gaslimit(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CHAINID":
			return new Chainid(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SELFBALANCE":
			return new Selfbalance(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "BASEFEE":
			return new Basefee(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "POP":
			return new Pop(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "MLOAD":
			return new Mload(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "MSTORE":
			return new Mstore(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "MSTORE8":
			return new Mstore8(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SLOAD":
			return new Sload(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SSTORE":
			return new Sstore(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "JUMP":
			return new Jump(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "JUMPI":
			return new Jumpi(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "PC":
			return new Pc(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "MSIZE":
			return new Msize(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "GAS":
			return new Gas(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "JUMPDEST":
			return new Jumpdest(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP1":
			return new Dup1(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP2":
			return new Dup2(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP3":
			return new Dup3(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP4":
			return new Dup4(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP5":
			return new Dup5(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP6":
			return new Dup6(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP7":
			return new Dup7(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP8":
			return new Dup8(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP9":
			return new Dup9(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP10":
			return new Dup10(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP11":
			return new Dup11(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP12":
			return new Dup12(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP13":
			return new Dup13(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP14":
			return new Dup14(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP15":
			return new Dup15(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DUP16":
			return new Dup16(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP1":
			return new Swap1(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP2":
			return new Swap2(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP3":
			return new Swap3(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP4":
			return new Swap4(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP5":
			return new Swap5(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP6":
			return new Swap6(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP7":
			return new Swap7(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP8":
			return new Swap8(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP9":
			return new Swap9(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP10":
			return new Swap10(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP11":
			return new Swap11(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP12":
			return new Swap12(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP13":
			return new Swap13(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP14":
			return new Swap14(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP15":
			return new Swap15(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SWAP16":
			return new Swap16(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "LOG0":
			return new Log0(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "LOG1":
			return new Log1(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "LOG2":
			return new Log2(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "LOG3":
			return new Log3(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "LOG4":
			return new Log4(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "JUMPTO":
			return new Jumpto(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "JUMPIF":
			return new Jumpif(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "JUMPSUB":
			return new Jumpsub(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "JUMPSUBV":
			return new Jumpsubv(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "BEGINSUB":
			return new Beginsub(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "BEGINDATA":
			return new Begindata(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "RETURNSUB":
			return new Returnsub(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "PUTLOCAL":
			return new Putlocal(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "GETLOCA":
			return new Getloca(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SLOADBYTES":
			return new Sloadbytes(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SSTOREBYTES":
			return new Sstorebytes(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SSIZE":
			return new Ssize(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CREATE":
			return new Create(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALL":
			return new Call(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALLCODE":
			return new Callcode(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "RETURN":
			return new Return(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "DELEGATECALL":
			return new Delegatecall(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CALLBLACKBOX":
			return new Callblackbox(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "STATICCALL":
			return new Staticcall(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "CREATE2":
			return new Create2(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "TXEXECGAS":
			return new Txexecgas(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "REVERT":
			return new Revert(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "INVALID":
			return new Invalid(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "SELFDESTRUCT":
			return new Selfdestruct(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "PUSH0":
			return new Push0(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
		case "PUSH1": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH1().getText().substring(ctx.PUSH1().getText().indexOf("0x")));
			Statement st = new Push1(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 2;
			return st;
		}
		case "PUSH2": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH2().getText().substring(ctx.PUSH2().getText().indexOf("0x")));
			Statement st = new Push2(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 3;
			return st;
		}
		case "PUSH3": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH3().getText().substring(ctx.PUSH3().getText().indexOf("0x")));
			Statement st = new Push3(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 4;
			return st;
		}
		case "PUSH4": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH4().getText().substring(ctx.PUSH4().getText().indexOf("0x")));
			Statement st = new Push4(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 5;
			return st;
		}
		case "PUSH5": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH5().getText().substring(ctx.PUSH5().getText().indexOf("0x")));
			Statement st = new Push5(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 6;
			return st;
		}
		case "PUSH6": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH6().getText().substring(ctx.PUSH6().getText().indexOf("0x")));
			Statement st = new Push6(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 7;
			return st;
		}
		case "PUSH7": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH7().getText().substring(ctx.PUSH7().getText().indexOf("0x")));
			Statement st = new Push7(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 8;
			return st;
		}
		case "PUSH8": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH8().getText().substring(ctx.PUSH8().getText().indexOf("0x")));
			Statement st = new Push8(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 9;
			return st;
		}
		case "PUSH9": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH9().getText().substring(ctx.PUSH9().getText().indexOf("0x")));
			Statement st = new Push9(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 10;
			return st;
		}
		case "PUSH10": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH10().getText().substring(ctx.PUSH10().getText().indexOf("0x")));
			Statement st = new Push10(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 11;
			return st;
		}
		case "PUSH11": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH11().getText().substring(ctx.PUSH11().getText().indexOf("0x")));
			Statement st = new Push11(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 12;
			return st;
		}
		case "PUSH12": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH12().getText().substring(ctx.PUSH12().getText().indexOf("0x")));
			Statement st = new Push12(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 13;
			return st;
		}
		case "PUSH13": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH13().getText().substring(ctx.PUSH13().getText().indexOf("0x")));
			Statement st = new Push13(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 14;
			return st;
		}
		case "PUSH14": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH14().getText().substring(ctx.PUSH14().getText().indexOf("0x")));
			Statement st = new Push14(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 15;
			return st;
		}
		case "PUSH15": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH15().getText().substring(ctx.PUSH15().getText().indexOf("0x")));
			Statement st = new Push15(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 16;
			return st;
		}
		case "PUSH16": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH16().getText().substring(ctx.PUSH16().getText().indexOf("0x")));
			Statement st = new Push16(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 17;
			return st;
		}
		case "PUSH17": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH17().getText().substring(ctx.PUSH17().getText().indexOf("0x")));
			Statement st = new Push17(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 18;
			return st;
		}
		case "PUSH18": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH18().getText().substring(ctx.PUSH18().getText().indexOf("0x")));
			Statement st = new Push18(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 19;
			return st;
		}
		case "PUSH19": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH19().getText().substring(ctx.PUSH19().getText().indexOf("0x")));
			Statement st = new Push19(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 20;
			return st;
		}
		case "PUSH20": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH20().getText().substring(ctx.PUSH20().getText().indexOf("0x")));
			Statement st = new Push20(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 21;
			return st;
		}
		case "PUSH21": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH21().getText().substring(ctx.PUSH21().getText().indexOf("0x")));
			Statement st = new Push21(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 22;
			return st;
		}
		case "PUSH22": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH22().getText().substring(ctx.PUSH22().getText().indexOf("0x")));
			Statement st = new Push22(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 23;
			return st;
		}
		case "PUSH23": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH23().getText().substring(ctx.PUSH23().getText().indexOf("0x")));
			Statement st = new Push23(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 24;
			return st;
		}
		case "PUSH24": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH24().getText().substring(ctx.PUSH24().getText().indexOf("0x")));
			Statement st = new Push24(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 25;
			return st;
		}
		case "PUSH25": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH25().getText().substring(ctx.PUSH25().getText().indexOf("0x")));
			Statement st = new Push25(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 26;
			return st;
		}
		case "PUSH26": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH26().getText().substring(ctx.PUSH26().getText().indexOf("0x")));
			Statement st = new Push26(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 27;
			return st;
		}
		case "PUSH27": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH27().getText().substring(ctx.PUSH27().getText().indexOf("0x")));
			Statement st = new Push27(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 28;
			return st;
		}
		case "PUSH28": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH28().getText().substring(ctx.PUSH28().getText().indexOf("0x")));
			Statement st = new Push28(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 29;
			return st;
		}
		case "PUSH29": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH29().getText().substring(ctx.PUSH29().getText().indexOf("0x")));
			Statement st = new Push29(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 30;
			return st;
		}
		case "PUSH30": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH30().getText().substring(ctx.PUSH30().getText().indexOf("0x")));
			Statement st = new Push30(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 31;
			return st;
		}
		case "PUSH31": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH31().getText().substring(ctx.PUSH31().getText().indexOf("0x")));
			Statement st = new Push31(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 32;
			return st;
		}
		case "PUSH32": {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg,
					new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()),
					ctx.PUSH32().getText().substring(ctx.PUSH32().getText().indexOf("0x")));
			Statement st = new Push32(cfg, new ProgramCounterLocation(pc, getLine(ctx), this.cfg.hashCode()), hex);
			pc += 33;
			return st;
		}
		}

		return new Invalid(cfg, new ProgramCounterLocation(pc++, getLine(ctx), this.cfg.hashCode()));
	}
}
