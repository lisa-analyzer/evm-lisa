package it.unipr.checker;

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

public class XCallUncheckedSuccessChecker implements SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {
    private static final Logger log = LogManager.getLogger(XCallUncheckedSuccessChecker.class);

    public boolean visit(CheckToolWithAnalysisResults<
                                        SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
                                CFG graph, Statement node){
        EVMCFG cfg = ((EVMCFG) graph);
    if(node instanceof Delegatecall || node instanceof Call || node instanceof Staticcall ||
            node instanceof Return || node instanceof Callcode) {
        for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
                TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
            AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
                    TypeEnvironment<InferredTypes>>> analysisResult = null;
            try {
                analysisResult = result.getAnalysisStateBefore(node);
            } catch (SemanticException e1) {
                log.error("(XCallUncheckedSuccessChecker): {}", e1.getMessage());
            }

            // Retrieve the symbolic stack from the analysis result
            TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

            if (taintedStack.isBottom())
                continue;
            else if (node instanceof Return) {
                TaintElement firstElement = taintedStack.getFirstElement();
                TaintElement secondElement = taintedStack.getSecondElement();
                if (firstElement.isTaint() || secondElement.isTaint()) {
                    raiseWarning(node, tool, cfg);
                }
            }
        }
    }
        return true;
}


    private void raiseWarning (Statement source, CheckToolWithAnalysisResults<
                                                  SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
                                          EVMCFG cfg) {
        ProgramCounterLocation loc = (ProgramCounterLocation) source.getLocation();

        log.error("XCallUncheckedSuccessChecker: The value pushed by {} at line {}, has never been checked, this may lead to unexpected behavior ",source.toString(), loc.getSourceCodeLine());

        String warn = "XCallUncheckedSuccessChecker: The value pushed by "+ source.toString() +" at line "+loc.getSourceCodeLine()+", has never been checked, this may lead to unexpected behavior " ;
        tool.warn(warn);
        MyCache.getInstance().addXCallUncheckedSuccessWarning(cfg.hashCode(), warn);
    }

    private static boolean isEnabled = false;

    public static void enableChecker () {
        isEnabled = true;
    }

    public static void disableChecker () {
        isEnabled = false;
    }

    public static boolean isEnabled () {
        return isEnabled;
    }
}
