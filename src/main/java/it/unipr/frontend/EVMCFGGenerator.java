package it.unipr.frontend;

import it.unipr.cfg.*;
import it.unipr.cfg.Byte;
import it.unipr.cfg.Number;
import it.unipr.cfg.push.Push;
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
		CodeMemberDescriptor cfgDesc = new CodeMemberDescriptor(new ProgramCounterLocation(-1, -1), unit, false,
				filePath, new Parameter[] {});

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
				map.put(st,((Push) last).getInt());
			if (last instanceof Jumpi) {
				cfg.addEdge(new FalseEdge(last, st));
			} else {
				cfg.addEdge(new SequentialEdge(last, st));
			}

			last = st;
		}

		for (Statement node : cfg.getNodes())
			for (Entry<Statement, BigInteger> entry : map.entrySet())
				if (((ProgramCounterLocation) node.getLocation()).getPc() == entry.getValue().intValue())
					cfg.addEdge(new TrueEdge(entry.getKey(), node));
		
		// The last statement of the CFG is a Ret statement.
		Ret ret = new Ret(cfg, new ProgramCounterLocation(pc++, -1));
		cfg.addNode(ret);
		cfg.addEdge(new SequentialEdge(st, ret));

		unit.addCodeMember(cfg);

		return cfg;
	}

	/**
	 * Helper method to retrieve the line of the program where the opcode is
	 */
	private static int getLine(OpcodesContext ctx) {
		return ctx.getStart().getLine();
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
		if (ctx.STOP() != null)
			return new Stop(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.ADD() != null)
			return new Add(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.MUL() != null)
			return new Mul(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SUB() != null)
			return new Sub(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DIV() != null)
			return new Div(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SDIV() != null)
			return new Sdiv(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.MOD() != null)
			return new Mod(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SMOD() != null)
			return new Smod(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.ADDMOD() != null)
			return new Addmod(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.MULMOD() != null)
			return new Mulmod(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.EXP() != null)
			return new Exp(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SIGNEXTEND() != null)
			return new Signextend(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.LT() != null)
			return new Lt(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.GT() != null)
			return new Gt(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SLT() != null)
			return new Slt(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SGT() != null)
			return new Sgt(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.EQ() != null)
			return new Eq(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.ISZERO() != null)
			return new Iszero(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.AND() != null)
			return new And(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.OR() != null)
			return new Or(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.XOR() != null)
			return new Xor(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.NOT() != null)
			return new Not(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.BYTE() != null)
			return new Byte(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SHL() != null)
			return new Shl(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SHR() != null)
			return new Shr(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SAR() != null)
			return new Sar(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SHA3() != null)
			return new Sha3(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.ADDRESS() != null)
			return new Address(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.BALANCE() != null)
			return new Balance(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.ORIGIN() != null)
			return new Origin(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALLER() != null)
			return new Caller(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALLVALUE() != null)
			return new Callvalue(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CODECOPY() != null)
			return new Codecopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALLDATALOAD() != null)
			return new Calldataload(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALLDATASIZE() != null)
			return new Calldatasize(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALLDATACOPY() != null)
			return new Calldatacopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CODESIZE() != null)
			return new Codesize(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.GASPRICE() != null)
			return new Gasprice(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.EXTCODESIZE() != null)
			return new Extcodesize(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.EXTCODECOPY() != null)
			return new Extcodecopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.RETURNDATASIZE() != null)
			return new Returndatasize(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.RETURNDATACOPY() != null)
			return new Returndatacopy(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.EXTCODEHASH() != null)
			return new Extcodehash(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.BLOCKHASH() != null)
			return new Blockhash(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.COINBASE() != null)
			return new Coinbase(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.TIMESTAMP() != null)
			return new Timestamp(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.NUMBER() != null)
			return new Number(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DIFFICULTY() != null)
			return new Difficulty(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.GASLIMIT() != null)
			return new Gaslimit(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CHAINID() != null)
			return new Chainid(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SELFBALANCE() != null)
			return new Selfbalance(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.BASEFEE() != null)
			return new Basefee(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.POP() != null)
			return new Pop(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.MLOAD() != null)
			return new Mload(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.MSTORE() != null)
			return new Mstore(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.MSTORE8() != null)
			return new Mstore8(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SLOAD() != null)
			return new Sload(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SSTORE() != null)
			return new Sstore(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.JUMP() != null)
			return new Jump(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.JUMPI() != null)
			return new Jumpi(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.PC() != null)
			return new Pc(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.MSIZE() != null)
			return new Msize(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.GAS() != null)
			return new Gas(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.JUMPDEST() != null)
			return new Jumpdest(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP1() != null)
			return new Dup1(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP2() != null)
			return new Dup2(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP3() != null)
			return new Dup3(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP1() != null)
			return new Dup1(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP4() != null)
			return new Dup4(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP5() != null)
			return new Dup5(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP6() != null)
			return new Dup6(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP7() != null)
			return new Dup7(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP8() != null)
			return new Dup8(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP9() != null)
			return new Dup9(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP10() != null)
			return new Dup10(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP11() != null)
			return new Dup11(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP12() != null)
			return new Dup12(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP13() != null)
			return new Dup13(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP14() != null)
			return new Dup14(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP15() != null)
			return new Dup15(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DUP16() != null)
			return new Dup16(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP1() != null)
			return new Swap1(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP2() != null)
			return new Swap2(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP3() != null)
			return new Swap3(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP4() != null)
			return new Swap4(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP5() != null)
			return new Swap5(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP6() != null)
			return new Swap6(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP7() != null)
			return new Swap7(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP8() != null)
			return new Swap8(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP9() != null)
			return new Swap9(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP10() != null)
			return new Swap10(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP11() != null)
			return new Swap11(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP12() != null)
			return new Swap12(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP13() != null)
			return new Swap13(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP14() != null)
			return new Swap14(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP15() != null)
			return new Swap15(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SWAP16() != null)
			return new Swap16(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.LOG0() != null)
			return new Log0(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.LOG1() != null)
			return new Log1(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.LOG2() != null)
			return new Log2(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.LOG3() != null)
			return new Log3(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.LOG4() != null)
			return new Log4(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.JUMPTO() != null)
			return new Jumpto(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.JUMPIF() != null)
			return new Jumpif(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.JUMPSUB() != null)
			return new Jumpsub(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.JUMPSUBV() != null)
			return new Jumpsubv(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.BEGINSUB() != null)
			return new Beginsub(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.BEGINDATA() != null)
			return new Begindata(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.RETURNSUB() != null)
			return new Returnsub(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.PUTLOCAL() != null)
			return new Putlocal(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.GETLOCA() != null)
			return new Getloca(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SLOADBYTES() != null)
			return new Sloadbytes(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SSTOREBYTES() != null)
			return new Sstorebytes(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SSIZE() != null)
			return new Ssize(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CREATE() != null)
			return new Create(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALL() != null)
			return new Call(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALLCODE() != null)
			return new Callcode(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.RETURN() != null)
			return new Return(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.DELEGATECALL() != null)
			return new Delegatecall(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CALLBLACKBOX() != null)
			return new Callblackbox(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.STATICCALL() != null)
			return new Staticcall(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.CREATE2() != null)
			return new Create2(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.TXEXECGAS() != null)
			return new Txexecgas(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.REVERT() != null)
			return new Revert(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.INVALID() != null)
			return new Invalid(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));
		else if (ctx.SELFDESTRUCT() != null)
			return new Selfdestruct(cfg, new ProgramCounterLocation(pc++, getLine(ctx)));

		else if (ctx.PUSH1() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH1().getText().substring(ctx.PUSH1().getText().indexOf("0x")));
			Statement st = new Push1(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 2;
			return st;
		} else if (ctx.PUSH2() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH2().getText().substring(ctx.PUSH2().getText().indexOf("0x")));
			Statement st = new Push2(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 3;
			return st;
		} else if (ctx.PUSH3() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH3().getText().substring(ctx.PUSH3().getText().indexOf("0x")));
			Statement st = new Push3(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 4;
			return st;
		} else if (ctx.PUSH4() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH4().getText().substring(ctx.PUSH4().getText().indexOf("0x")));
			Statement st = new Push4(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 5;
			return st;
		} else if (ctx.PUSH5() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH5().getText().substring(ctx.PUSH5().getText().indexOf("0x")));
			Statement st = new Push5(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 6;
			return st;
		} else if (ctx.PUSH6() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH6().getText().substring(ctx.PUSH6().getText().indexOf("0x")));
			Statement st = new Push6(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 7;
			return st;
		} else if (ctx.PUSH7() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH7().getText().substring(ctx.PUSH7().getText().indexOf("0x")));
			Statement st = new Push7(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 8;
			return st;
		} else if (ctx.PUSH8() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH8().getText().substring(ctx.PUSH8().getText().indexOf("0x")));
			Statement st = new Push8(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 9;
			return st;
		} else if (ctx.PUSH9() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH9().getText().substring(ctx.PUSH9().getText().indexOf("0x")));
			Statement st = new Push9(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 10;
			return st;
		} else if (ctx.PUSH10() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH10().getText().substring(ctx.PUSH10().getText().indexOf("0x")));
			Statement st = new Push10(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 11;
			return st;
		} else if (ctx.PUSH11() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH11().getText().substring(ctx.PUSH11().getText().indexOf("0x")));
			Statement st = new Push11(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 12;
			return st;
		} else if (ctx.PUSH12() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH12().getText().substring(ctx.PUSH12().getText().indexOf("0x")));
			Statement st = new Push12(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 13;
			return st;
		} else if (ctx.PUSH13() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH13().getText().substring(ctx.PUSH13().getText().indexOf("0x")));
			Statement st = new Push13(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 14;
			return st;
		} else if (ctx.PUSH14() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH14().getText().substring(ctx.PUSH14().getText().indexOf("0x")));
			Statement st = new Push14(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 15;
			return st;
		} else if (ctx.PUSH15() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH15().getText().substring(ctx.PUSH15().getText().indexOf("0x")));
			Statement st = new Push15(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 16;
			return st;
		} else if (ctx.PUSH16() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH16().getText().substring(ctx.PUSH16().getText().indexOf("0x")));
			Statement st = new Push16(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 17;
			return st;
		} else if (ctx.PUSH17() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH17().getText().substring(ctx.PUSH17().getText().indexOf("0x")));
			Statement st = new Push17(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 18;
			return st;
		} else if (ctx.PUSH18() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH18().getText().substring(ctx.PUSH18().getText().indexOf("0x")));
			Statement st = new Push18(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 19;
			return st;
		} else if (ctx.PUSH19() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH19().getText().substring(ctx.PUSH19().getText().indexOf("0x")));
			Statement st = new Push19(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 20;
			return st;
		} else if (ctx.PUSH20() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH20().getText().substring(ctx.PUSH20().getText().indexOf("0x")));
			Statement st = new Push20(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 21;
			return st;
		} else if (ctx.PUSH21() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH21().getText().substring(ctx.PUSH21().getText().indexOf("0x")));
			Statement st = new Push21(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 22;
			return st;
		} else if (ctx.PUSH22() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH22().getText().substring(ctx.PUSH22().getText().indexOf("0x")));
			Statement st = new Push22(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 23;
			return st;
		} else if (ctx.PUSH23() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH23().getText().substring(ctx.PUSH23().getText().indexOf("0x")));
			Statement st = new Push23(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 24;
			return st;
		} else if (ctx.PUSH24() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH24().getText().substring(ctx.PUSH24().getText().indexOf("0x")));
			Statement st = new Push24(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 25;
			return st;
		} else if (ctx.PUSH25() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH25().getText().substring(ctx.PUSH25().getText().indexOf("0x")));
			Statement st = new Push25(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 26;
			return st;
		} else if (ctx.PUSH26() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH26().getText().substring(ctx.PUSH26().getText().indexOf("0x")));
			Statement st = new Push26(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 27;
			return st;
		} else if (ctx.PUSH27() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH27().getText().substring(ctx.PUSH27().getText().indexOf("0x")));
			Statement st = new Push27(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 28;
			return st;
		} else if (ctx.PUSH28() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH28().getText().substring(ctx.PUSH28().getText().indexOf("0x")));
			Statement st = new Push28(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 29;
			return st;
		} else if (ctx.PUSH29() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH29().getText().substring(ctx.PUSH29().getText().indexOf("0x")));
			Statement st = new Push29(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 30;
			return st;
		} else if (ctx.PUSH30() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH30().getText().substring(ctx.PUSH30().getText().indexOf("0x")));
			Statement st = new Push30(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 31;
			return st;
		} else if (ctx.PUSH31() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH31().getText().substring(ctx.PUSH31().getText().indexOf("0x")));
			Statement st = new Push31(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 32;
			return st;
		} else if (ctx.PUSH32() != null) {
			HexDecimalLiteral hex = new HexDecimalLiteral(cfg, new ProgramCounterLocation(pc, getLine(ctx)),
					ctx.PUSH32().getText().substring(ctx.PUSH32().getText().indexOf("0x")));
			Statement st = new Push32(cfg, new ProgramCounterLocation(pc, getLine(ctx)), hex);
			pc += 33;
			return st;
		}

		throw new UnsupportedOperationException(ctx.getText());
	}
}
