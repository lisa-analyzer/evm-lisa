package it.unipr.analysis;

import it.unive.lisa.analysis.*;
import it.unive.lisa.analysis.lattices.Satisfiability;
import it.unive.lisa.analysis.value.ValueDomain;
import it.unive.lisa.program.cfg.ProgramPoint;
import it.unive.lisa.symbolic.value.Identifier;
import it.unive.lisa.symbolic.value.ValueExpression;
import it.unive.lisa.util.representation.StringRepresentation;
import it.unive.lisa.util.representation.StructuredRepresentation;

import java.util.Arrays;
import java.util.function.Predicate;

public class MemoryByte implements ValueDomain<MemoryByte>, BaseLattice<MemoryByte> {
    private static final int WORD_SIZE = 32;
    private byte[] _memory;
    private final boolean _isTop;
    private static final MemoryByte BOTTOM = new MemoryByte(null);
    private static final MemoryByte TOP = new MemoryByte(null, true);

    public MemoryByte() {
        this(new byte[0]);
    }
    public MemoryByte(byte[] memory) {
        this._memory = memory;
        this._isTop = false;
    }
    public MemoryByte(byte[] memory, boolean isTop) {
        this._memory = memory;
        this._isTop = isTop;
    }

    public void mstore(int offset, byte[] value) {
        if (value.length != WORD_SIZE) {
            throw new IllegalArgumentException("The value must be 32 byte");
        }
        ensureCapacity(offset + WORD_SIZE);
        System.arraycopy(value, 0, _memory, offset, WORD_SIZE);
    }

    public byte[] mload(int offset) {
        if (offset + WORD_SIZE > _memory.length) {
            return new byte[WORD_SIZE];
        }
        byte[] result = new byte[WORD_SIZE];
        System.arraycopy(_memory, offset, result, 0, WORD_SIZE);
        return result;
    }

    private void ensureCapacity(int size) {
        if (size > _memory.length) {
            byte[] newMemory = new byte[size];
            System.arraycopy(_memory, 0, newMemory, 0, _memory.length);
            _memory = newMemory;
        }
    }

    @Override
    public int hashCode() {
        return Arrays.hashCode(_memory);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null || getClass() != obj.getClass())
            return false;
        MemoryByte that = (MemoryByte) obj;
        return Arrays.equals(_memory, that._memory);
    }

    @Override
    public MemoryByte clone() {
        MemoryByte cloned = new MemoryByte();
        cloned._memory = Arrays.copyOf(this._memory, this._memory.length);
        return cloned;
    }

    @Override
    public String toString() {
//        StringBuilder sb = new StringBuilder("MemoryByte{");
//        sb.append("size=").append(_memory.length);
//        sb.append(", data=").append(Arrays.toString(_memory));
//        sb.append('}');
//        return sb.toString();

        if (_isTop)
            return "TOP";

        if (_memory == null)
            return "BOTTOM";

        if(_memory.length == 0)
            return "EMPTY";

        StringBuilder hexString = new StringBuilder("");
        for (byte b : _memory) {
            hexString.append(String.format("%02X", b));
        }

        return hexString.toString();
    }

    @Override
    public boolean lessOrEqual(MemoryByte other) throws SemanticException {
        return false;
    }

    @Override
    public MemoryByte lub(MemoryByte other) throws SemanticException {
        return null;
    }

    @Override
    public MemoryByte lubAux(MemoryByte other) throws SemanticException {
        return null;
    }

    @Override
    public boolean lessOrEqualAux(MemoryByte other) throws SemanticException {
        return false;
    }

    @Override
    public MemoryByte top() {
        return TOP;
    }

    @Override
    public MemoryByte bottom() {
        return BOTTOM;
    }

    @Override
    public MemoryByte assign(Identifier id, ValueExpression expression, ProgramPoint pp, SemanticOracle oracle) throws SemanticException {
        return null;
    }

    @Override
    public MemoryByte smallStepSemantics(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle) throws SemanticException {
        return null;
    }

    @Override
    public MemoryByte assume(ValueExpression expression, ProgramPoint src, ProgramPoint dest, SemanticOracle oracle) throws SemanticException {
        return null;
    }

    @Override
    public boolean knowsIdentifier(Identifier id) {
        return false;
    }

    @Override
    public MemoryByte forgetIdentifier(Identifier id) throws SemanticException {
        return null;
    }

    @Override
    public MemoryByte forgetIdentifiersIf(Predicate<Identifier> test) throws SemanticException {
        return null;
    }

    @Override
    public Satisfiability satisfies(ValueExpression expression, ProgramPoint pp, SemanticOracle oracle) throws SemanticException {
        return null;
    }

    @Override
    public MemoryByte pushScope(ScopeToken token) throws SemanticException {
        return null;
    }

    @Override
    public MemoryByte popScope(ScopeToken token) throws SemanticException {
        return null;
    }

    @Override
    public StructuredRepresentation representation() {
        // Se il valore è Top, restituiamo una rappresentazione adeguata
        if (_isTop)
            return Lattice.topRepresentation();

        // Se la memoria è vuota, restituiamo una rappresentazione adeguata
        if (_memory == null || _memory.length == 0)
            return Lattice.bottomRepresentation();

        // Altrimenti, rappresentiamo i byte della memoria come valori esadecimali
        StringBuilder hexString = new StringBuilder("");
        for (byte b : _memory) {
            hexString.append(String.format("%02X", b)); // Converte il byte in esadecimale con due caratteri
        }

        return new StringRepresentation(hexString.toString());
    }
}