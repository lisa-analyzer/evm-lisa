package it.unipr.analysis.taint;

import it.unipr.analysis.operator.*;
import it.unive.lisa.program.cfg.statement.Statement;
import it.unive.lisa.symbolic.value.Operator;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public class XCallUncheckedSuccessAbstractDomain extends TaintAbstractDomain  {
    private static final XCallUncheckedSuccessAbstractDomain TOP = new XCallUncheckedSuccessAbstractDomain(
            createFilledArray(TaintAbstractDomain.STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN);
    private static final XCallUncheckedSuccessAbstractDomain BOTTOM = new XCallUncheckedSuccessAbstractDomain(null, TaintElement.BOTTOM);


    private static TaintElement[] createFilledArray(int size, TaintElement element) {
        TaintElement[] array = new TaintElement[size];
        Arrays.fill(array, element);
        return array;
    }

    public XCallUncheckedSuccessAbstractDomain() { super(createFilledArray(STACK_LIMIT, TaintElement.BOTTOM), TaintElement.CLEAN); }

    protected XCallUncheckedSuccessAbstractDomain(TaintElement[] stack, TaintElement memory) {super(stack, memory);}

    /**
     * returns the set of the tainted opcodes for the Abstract Domain
     * @return the set of the tainted opcodes
     */
    public Set<Operator> getTaintedOpcode() {
        Set<Operator> taintedOpcode = new HashSet<>();
        taintedOpcode.add(CallOperator.INSTANCE);
        taintedOpcode.add(StaticcallOperator.INSTANCE);
        taintedOpcode.add(CallcodeOperator.INSTANCE);
        taintedOpcode.add(CalldatacopyOperator.INSTANCE);
        return taintedOpcode;
    }



    @Override
    public Set<Operator> getSanitizedOpcode() {
        return Set.of();
    }

    @Override
    public TaintAbstractDomain mk(TaintElement[] array, TaintElement memory) {
        return new XCallUncheckedSuccessAbstractDomain(array, memory);
    }

    @Override
    public XCallUncheckedSuccessAbstractDomain top() { return TOP; }

    @Override
    public XCallUncheckedSuccessAbstractDomain bottom() { return BOTTOM; }



}