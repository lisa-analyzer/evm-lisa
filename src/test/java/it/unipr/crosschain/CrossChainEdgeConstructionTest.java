package it.unipr.crosschain;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.cfg.Return;
import it.unive.lisa.program.ClassUnit;
import it.unive.lisa.program.cfg.CodeMemberDescriptor;
import it.unive.lisa.program.cfg.statement.Statement;
import java.nio.file.Path;
import java.util.Collections;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

public class CrossChainEdgeConstructionTest {
	@Rule
	public TemporaryFolder temporaryFolder = new TemporaryFolder();

	/**
	 * Verifies that CLI edge skipping leaves the public graph-building API
	 * intact.
	 */
	@Test
	public void cliCanSkipEdgesWhileApiStillBuildsThem() throws Exception {
		Path bytecodeDirectory = temporaryFolder.newFolder("bytecode").toPath();
		Path abiDirectory = temporaryFolder.newFolder("abi").toPath();
		Bridge bridge = new Bridge(bytecodeDirectory, abiDirectory);
		SmartContract source = contract("source", "00");
		SmartContract destination = contract("destination", "01");

		Signature event = signature("Deposit", "event");
		event.addExitPoint(source.getCFG().getEntrypoints().iterator().next());
		source.getEventsSignature().add(event);

		Signature function = signature("Deposit", "function");
		function.addEntryPoint(destination.getCFG().getEntrypoints().iterator().next());
		destination.getFunctionsSignature().add(function);
		bridge.getSmartContracts().add(source);
		bridge.getSmartContracts().add(destination);

		assertEquals(1, xEVMLiSA.getCrossChainEdgesUsingPolicy(bridge).size());
		assertTrue(xEVMLiSA.getCrossChainEdgesUsingPolicy(bridge, false).isEmpty());
	}

	/**
	 * Creates a contract with one CFG entrypoint for edge-construction checks.
	 */
	private static SmartContract contract(String name, String bytecode) {
		SmartContract contract = new SmartContract().setName(name).setBytecode(bytecode);
		ProgramCounterLocation location = new ProgramCounterLocation(0, 0);
		ClassUnit unit = new ClassUnit(location, null, name, false);
		EVMCFG cfg = new EVMCFG(new CodeMemberDescriptor(location, unit, false, name));
		Statement entryPoint = new Return(cfg, location);
		cfg.addNode(entryPoint);
		cfg.getEntrypoints().add(entryPoint);
		contract.setCFG(cfg);
		return contract;
	}

	/** Creates an event or function signature with the given name. */
	private static Signature signature(String name, String type) {
		return new Signature(name, type, Collections.emptyList(), Collections.emptyList(), name + "()", name);
	}
}
