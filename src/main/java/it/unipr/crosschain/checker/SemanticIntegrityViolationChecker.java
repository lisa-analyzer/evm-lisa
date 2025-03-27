package it.unipr.crosschain.checker;

import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.*;
import it.unipr.utils.MyCache;
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
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.HashSet;
import java.util.Set;

public class SemanticIntegrityViolationChecker implements 
        SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {

    private static final Logger log = LogManager.getLogger(SemanticIntegrityViolationChecker.class);

    private final Set<Statement> taintedJumpi = new HashSet<>();


    @Override
    public boolean visit(
            CheckToolWithAnalysisResults<
                    SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
            CFG graph, Statement node) {
        if (node instanceof Log0 ||
                node instanceof Log1 ||
                node instanceof Log2 ||
                node instanceof Log3 ||
                node instanceof Log4 ) {
            EVMCFG cfg = ((EVMCFG) graph);

            for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
                    TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {

                AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
                        TypeEnvironment<InferredTypes>>> analysisResult = null;

                try {
                    analysisResult = result.getAnalysisStateBefore(node);
                } catch (SemanticException e1) {
                    log.error("(UncheckedExternalInfluenceChecker): {}", e1.getMessage());
                }

                TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

                if (taintedStack.isBottom())
                    // Nothing to do
                    continue;
                else {
                    // Checks if either first or second element in the
                    // stack is tainted
                    if (TaintElement.isTaintedOrTop(
                            taintedStack.getElementAtPosition(1),
                            taintedStack.getElementAtPosition(2))) {

                        if (node instanceof Jumpi) {
                            taintedJumpi.add(node);
                            return true;
                        }

                        checkForSemanticIntegrityViolation(node, tool, cfg);
                    }
                }
            }
        }
            return true;
    }

        private void checkForSemanticIntegrityViolation(Statement logx, CheckToolWithAnalysisResults<
                SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
                EVMCFG cfg){
            Set<Statement> externalDatas = cfg.getExternalData();

            for (Statement data : externalDatas) {
                if (cfg.reachableFromWithoutStatements(data, logx, taintedJumpi)) {

                    ProgramCounterLocation logxLocation = (ProgramCounterLocation) logx.getLocation();

                    log.warn("Semantic Integrity Violation at pc {} at line {} coming from line {}.",
                            logxLocation.getPc(),
                            logxLocation.getSourceCodeLine(),
                            ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine());

                    String warn = "Semantic Integrity Violation vulnerability at "
                            + ((ProgramCounterLocation) data.getLocation()).getSourceCodeLine();
                    tool.warn(warn);
                    MyCache.getInstance().addSemanticIntegrityViolationWarning(cfg.hashCode(), warn);
                }
            }
    }
}

