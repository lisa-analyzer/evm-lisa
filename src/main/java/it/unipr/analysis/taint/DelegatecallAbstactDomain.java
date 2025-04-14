package it.unipr.analysis.taint;

import it.unipr.analysis.operator.CalldatacopyOperator;
import it.unipr.analysis.operator.CalldataloadOperator;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public class DelegatecallAbstactDomain extends TaintAbstractDomain  {
    private static final DelegatecallAbstactDomain TOP = new DelegatecallAbstactDomain(
            createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
    private static final DelegatecallAbstactDomain BOTTOM = new DelegatecallAbstactDomain(null, TaintElement.BOTTOM);


    private static TaintElement[] createFilledArray(int size, TaintElement element) {
        TaintElement[] array = new TaintElement[size];
        Arrays.fill(array, element);
        return array;
    }

    public DelegatecallAbstactDomain() { super(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN); }

    protected DelegatecallAbstactDomain(TaintElement[] stack, TaintElement memory) {super(stack, memory);}

    /**
     * returns the set of the tainted opcodes for the Abstract Domain
     * @return the set of the tainted opcodes
     */
    public Set<Operator> getTaintedOpcode() {
        Set<Operator> taintedOpcode = new HashSet<>();
        taintedOpcode.add(CalldatacopyOperator.INSTANCE);
        taintedOpcode.add(CalldataloadOperator.INSTANCE);
        return taintedOpcode;
    }



    @Override
    public Set<Operator> getSanitizedOpcode() {
        return Set.of();
    }

    @Override
    public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
        return new DelegatecallAbstactDomain(array, memory);
    }

    @Override
    public DelegatecallAbstactDomain top() { return TOP; }

    @Override
    public DelegatecallAbstactDomain bottom() { return BOTTOM; }



}
