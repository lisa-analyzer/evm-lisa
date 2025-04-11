package it.unipr.checker;


import it.unipr.analysis.EVMAbstractState;
import it.unipr.analysis.operator.ReturnOperator;
import it.unipr.analysis.taint.TaintAbstractDomain;
import it.unipr.cfg.Delegatecall;
import it.unipr.cfg.EVMCFG;
import it.unipr.cfg.Return;
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
 */
public class DelegatecallChecker implements
        SemanticCheck<SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> {
    private static final Logger log = LogManager.getLogger(DelegatecallChecker.class);

    public boolean visit(CheckToolWithAnalysisResults<
                                     SimpleAbstractState<MonolithicHeap, TaintAbstractDomain, TypeEnvironment<InferredTypes>>> tool,
                         CFG graph, Statement node){
        EVMCFG cfg = ((EVMCFG) graph);
        if(node instanceof Delegatecall || node instanceof Return){


        }
        return false;
    }

    private static boolean isEnabled = false;

    public static void enableChecker() {
        isEnabled = true;
    }

    public static void disableChecker() {
        isEnabled = false;
    }

    public static boolean isEnabled() {
        return isEnabled;
    }



}
