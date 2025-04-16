package it.unipr.analysis.taint;

import it.unipr.analysis.operator.CalldatacopyOperator;
import it.unipr.analysis.operator.CalldataloadOperator;
import it.unive.lisa.symbolic.value.Operator;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public class DelegatecallTaintaddressAbstactDomain extends TaintAbstractDomain  {
    private static final DelegatecallTaintaddressAbstactDomain TOP = new DelegatecallTaintaddressAbstactDomain(
            createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
    private static final DelegatecallTaintaddressAbstactDomain BOTTOM = new DelegatecallTaintaddressAbstactDomain(null, TaintElement.BOTTOM);


    private static TaintElement[] createFilledArray(int size, TaintElement element) {
        TaintElement[] array = new TaintElement[size];
        Arrays.fill(array, element);
        return array;
    }

    public DelegatecallTaintaddressAbstactDomain() { super(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN); }

    protected DelegatecallTaintaddressAbstactDomain(TaintElement[] stack, TaintElement memory) {super(stack, memory);}

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
        return new DelegatecallTaintaddressAbstactDomain(array, memory);
    }

    @Override
    public DelegatecallTaintaddressAbstactDomain top() { return TOP; }

    @Override
    public DelegatecallTaintaddressAbstactDomain bottom() { return BOTTOM; }



}
