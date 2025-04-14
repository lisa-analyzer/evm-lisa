package it.unipr.checker;


import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.analysis.taint.TaintElement;
import it.unipr.cfg.Delegatecall;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.ProgramCounterLocation;
import it.unipr.cfg.Return;
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

/**
 * Semantic checker wich detect a possible exploit through the delegatecall opcode.
 * This checker detect if the stack is tainted before a delegatecall opcode.
 */
public class DelegatecallChecker implements
        SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {
    private static final Logger log = LogManager.getLogger(DelegatecallChecker.class);

    public boolean visit(CheckToolWithAnalysisResults<
                                 SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
                         CFG graph, Statement node) {
        EVMCFG cfg = ((EVMCFG) graph);


        if (node instanceof Delegatecall || node instanceof Return) {
            for (AnalyzedCFG<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
                    TypeEnvironment<InferredTypes>>> result : tool.getResultOf(cfg)) {
                AnalysisState<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain,
                        TypeEnvironment<InferredTypes>>> analysisResult = null;

                try {
                    analysisResult = result.getAnalysisStateBefore(node);
                } catch (SemanticException e1) {
                    log.error("(DelegatecallChecker): {}", e1.getMessage());
                }

                // Retrieve the symbolic stack from the analysis result
                TaintAbstractDomain taintedStack = analysisResult.getState().getValueState();

                // If the stack is bottom the node is unreacheble so there is not nothing to do
                if(taintedStack.isBottom())
                    continue;
                else if(node instanceof Delegatecall){
                    TaintElement taintedAddress = taintedStack.getSecondElement();
                    if(taintedAddress.isTaint()) {
                        raiseWarningTaintedAddr(node, tool, cfg);
                    }
                } else if(node instanceof Return){

                }

            }

        }
        return true;
    }

        private void raiseWarningTaintedAddr (Statement sink, CheckToolWithAnalysisResults<
                                           SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
                                   EVMCFG cfg) {
            ProgramCounterLocation loc = (ProgramCounterLocation) sink.getLocation();
            log.error("DelegatecallChecker: The address of the delegatecall at line {} is tainted", loc.getSourceCodeLine());

            String warn = "DelegatecallChecker: The address of delegate call is tainted at line " + loc.getSourceCodeLine();
            tool.warn(warn);
            //TODO: cache stuff
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
