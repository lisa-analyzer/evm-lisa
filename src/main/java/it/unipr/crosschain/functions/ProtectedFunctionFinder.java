package it.unipr.crosschain.functions;

import it.unipr.analysis.contract.Signature;
import it.unipr.analysis.contract.SmartContract;
import it.unipr.cfg.*;
import it.unipr.crosschain.taint.RelationalTaintAbstractDomain;
import it.unipr.crosschain.taint.RelationalTaintElement;
import it.unive.lisa.analysis.AnalysisState;
import it.unive.lisa.analysis.AnalyzedCFG;
import it.unive.lisa.analysis.SemanticException;
import it.unive.lisa.analysis.SimpleAbstractState;
import it.unive.lisa.analysis.heap.MonolithicHeap;
import it.unive.lisa.analysis.nonrelational.value.TypeEnvironment;
import it.unive.lisa.analysis.types.InferredTypes;
import it.unive.lisa.checks.semantic.CheckToolWithAnalysisResults;
import it.unive.lisa.checks.semantic.SemanticCheck;
import it.unive.lisa.program.cfg.CFG;
import it.unive.lisa.program.cfg.statement.Statement;
import java.util.HashSet;
import java.util.Set;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class ProtectedFunctionFinder implements
		SemanticCheck<
				SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

	private static final Logger log = LogManager.getLogger(ProtectedFunctionFinder.class);
	private final SmartContract contract;

	public ProtectedFunctionFinder(SmartContract contract) {
		this.contract = contract;
	}

	@Override
	public boolean visit(
			CheckToolWithAnalysisResults<
					SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
							TypeEnvironment<InferredTypes>>> tool,
			CFG graph, Statement node) {

		EVMCFG cfg = ((EVMCFG) graph);

		if (node instanceof Jumpi)
			for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
					TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
				AnalysisState<SimpleAbstractState<MonolithicHeap, RelationalTaintAbstractDomain,
						TypeEnvironment<InferredTypes>>> analysisResult = null;

				try {
					analysisResult = result.getAnalysisStateBefore(node);
				} catch (SemanticException e1) {
					log.error("(ProtectedFunctionFinder): {}", e1.getMessage());
				}

				RelationalTaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

				if (taintedStack.isBottom() || taintedStack.isTop())
					continue;

				RelationalTaintElement elem1 = taintedStack.getElementAtPosition(1);
				RelationalTaintElement elem2 = taintedStack.getElementAtPosition(2);

				if (RelationalTaintElement.isAtLeastOneTainted(elem1, elem2)) {
					// Track program points sanitized by this specific Jumpi
					Set<Integer> jumpiPps = new HashSet<>();
					if (elem1.isTaint()) {
						jumpiPps.addAll(elem1.getProgramPoints());
					}
					if (elem2.isTaint()) {
						jumpiPps.addAll(elem2.getProgramPoints());
					}
					checkForProtection(node, cfg, jumpiPps);
				}
			}

		return true;
	}

	private void checkForProtection(Statement sink, EVMCFG cfg, Set<Integer> jumpiPps) {
		Set<Signature> functionsSignature = contract.getFunctionsSignature();

		for (Signature functionSignature : functionsSignature) {
			log.debug("Checking: {} that has {} entrypoints", functionSignature.getFullSignature(),
					functionSignature.getEntryPoints().size());

			for (Statement functionEntryPoint : functionSignature.getEntryPoints()) {
				Statement source = cfg.getClosestStatementOfType(functionEntryPoint, Caller.class);

				log.debug("Source {} at pc {} line {}",
						source,
						((ProgramCounterLocation) source.getLocation()).getPc(),
						((ProgramCounterLocation) source.getLocation()).getSourceCodeLine());

				if (cfg.reachableFromWithDepthLimit(source, sink, 10)
						&& jumpiPps.contains(((ProgramCounterLocation) source.getLocation()).getPc())) {
					log.debug("Sink {} at pc {} line {}",
							sink,
							((ProgramCounterLocation) sink.getLocation()).getPc(),
							((ProgramCounterLocation) sink.getLocation()).getSourceCodeLine());

					functionSignature.setProtected(true);
					log.info("Function {} is protected", functionSignature.getFullSignature());

				}
			}
		}

	}
}
