package it.unipr.crosschain.checker;

import static org.junit.Assert.assertEquals;

import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.Caller;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Jumpi;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.cfg.Sstore;
import it.unipr.crosschain.xEVMLiSA;
import it.unipr.utils.CustomPolicy;
import it.unive.lisa.program.ClassUnit;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.edge.SequentialEdge;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Path;
import java.util.Map;
import java.util.Set;
import org.junit.Test;

public class AccessControlIncompletenessCheckerTest {

	@Test
	public void preservesDepthFirstGuardDiscoveryOrder() {
		ProgramCounterLocation start = new ProgramCounterLocation(0, 0);
		EVMCFG cfg = cfg(start);
		Statement source = new Caller(cfg, start);
		Statement first = new Sstore(cfg, new ProgramCounterLocation(1, 1));
		Statement second = new Sstore(cfg, new ProgramCounterLocation(2, 2));
		Statement guard = new Jumpi(cfg, new ProgramCounterLocation(3, 3));
		Statement unreachable = new Sstore(cfg, new ProgramCounterLocation(4, 4));
		for (Statement node : Set.of(source, first, second, guard, unreachable))
			cfg.addNode(node);
		cfg.addEdge(new SequentialEdge(source, first));
		cfg.addEdge(new SequentialEdge(first, second));
		cfg.addEdge(new SequentialEdge(first, guard));
		cfg.addEdge(new SequentialEdge(second, source));
		AccessControlIncompletenessChecker checker = new AccessControlIncompletenessChecker(new SmartContract());

		assertEquals(Set.of(first), checker.findUnguardedSinks(cfg, source, Map.of(guard, Set.of(0))));
		assertEquals(Set.of(first, second), checker.findUnguardedSinks(cfg, source, Map.of(guard, Set.of(1))));
	}

	@Test
	public void localDependencyDoesNotConfigureLiSAForAnEmptyPolicy() {
		SmartContract contract = new SmartContract() {
			@Override
			public Path getWorkingDirectory() {
				throw new AssertionError("An empty policy cannot produce local dependency warnings");
			}
		};
		contract.setCFG(cfg(new ProgramCounterLocation(0, 0)));
		xEVMLiSA.runLocalDependencyChecker(contract, new CustomPolicy());
	}

	private static EVMCFG cfg(ProgramCounterLocation start) {
		ClassUnit unit = new ClassUnit(start, null, "contract", false);
		return new EVMCFG(new CodeMemberDescriptor(start, unit, false, "contract"));
	}
}
