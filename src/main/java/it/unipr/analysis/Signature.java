package it.unipr.analysis;

import it.unive.lisa.program.cfg.statement.Statement;
import java.util.*;

public class Signature {
    private final String _name;
    private final String _type;
    private final List<String> _inputParamTypes;
    private final List<String> _outputParamTypes;
    private final String _fullSignature;
    private final String _selector;
    private Set<Statement> _entryPoints;
    private Set<Statement> _exitPoints;

    public Signature(String name, String type, List<String> inputParamTypes, List<String> outputParamTypes,
                     String fullSignature, String selector) {
        this._name = name;
        this._type = type;
        this._inputParamTypes = inputParamTypes;
        this._outputParamTypes = outputParamTypes;
        this._fullSignature = fullSignature;
        this._selector = selector;
        this._entryPoints = new HashSet<>();
        this._exitPoints = new HashSet<>();
    }

    public String getName() {
        return _name;
    }

    public String getType() {
        return _type;
    }

    public int getParamCount() {
        return _inputParamTypes.size();
    }

    public int getOutputParamCount() {
        return _outputParamTypes.size();
    }

    public List<String> getParamTypes() {
        return _inputParamTypes;
    }

    public String getFullSignature() {
        return _fullSignature;
    }

    public String getSelector() {
        return _selector;
    }

    public Set<Statement> getEntryPoints() {
        return _entryPoints;
    }

    public void setEntryPoints(Set<Statement> entryPoints) {
        this._entryPoints = entryPoints;
    }

    public void addEntryPoint(Statement entryPoint) {
        if (entryPoint != null)
            this._entryPoints.add(entryPoint);
    }

    public Set<Statement> getExitPoints() {
        return _exitPoints;
    }

    public void setExitPoints(Set<Statement> exitPoints) {
        this._exitPoints = exitPoints;
    }

    public void addExitPoint(Statement exitPoints) {
        if (exitPoints != null)
            this._exitPoints.add(exitPoints);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null || getClass() != obj.getClass())
            return false;
        Signature other = (Signature) obj;
        return Objects.equals(_name, other._name) &&
                Objects.equals(_type, other._type) &&
                Objects.equals(_fullSignature, other._fullSignature) &&
                Objects.equals(_selector, other._selector);
    }

    @Override
    public int hashCode() {
        return Objects.hash(_name, _type, _fullSignature, _selector);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        String indent = "  ";

        sb.append("{\n");
        sb.append(indent).append("\"name\": \"").append(_name).append("\",\n");
        sb.append(indent).append("\"type\": \"").append(_type).append("\",\n");
        sb.append(indent).append("\"inputParamCount\": ").append(_inputParamTypes.size()).append(",\n");

        sb.append(indent).append("\"inputParamTypes\": [");
        if (!_inputParamTypes.isEmpty()) {
            sb.append("\n");
            for (int i = 0; i < _inputParamTypes.size(); i++) {
                sb.append(indent).append(indent).append("\"").append(_inputParamTypes.get(i)).append("\"");
                if (i < _inputParamTypes.size() - 1) {
                    sb.append(",");
                }
                sb.append("\n");
            }
            sb.append(indent);
        }
        sb.append("],\n");
        sb.append(indent).append("\"outputParamCount\": ").append(_outputParamTypes.size()).append(",\n");

        sb.append(indent).append("\"outputParamTypes\": [");
        if (!_outputParamTypes.isEmpty()) {
            sb.append("\n");
            for (int i = 0; i < _outputParamTypes.size(); i++) {
                sb.append(indent).append(indent).append("\"").append(_outputParamTypes.get(i)).append("\"");
                if (i < _outputParamTypes.size() - 1) {
                    sb.append(",");
                }
                sb.append("\n");
            }
            sb.append(indent);
        }
        sb.append("],\n");

        sb.append(indent).append("\"fullSignature\": \"").append(_fullSignature).append("\",\n");
        sb.append(indent).append("\"selector\": \"").append(_selector).append("\",\n");

        sb.append(indent).append("\"entryPoints\": [");
        if (!_entryPoints.isEmpty()) {
            sb.append("\n");
            Iterator<Statement> iterator = _entryPoints.iterator();

            while (iterator.hasNext()) {
                sb.append(indent).append(indent).append("\"").append(iterator.next().toString()).append("\"");
                if (iterator.hasNext()) {
                    sb.append(",");
                }
                sb.append("\n");
            }
            sb.append(indent);
        }
        sb.append("],\n");

        sb.append(indent).append("\"exitPoints\": [");
        if (!_exitPoints.isEmpty()) {
            sb.append("\n");
            Iterator<Statement> iterator = _exitPoints.iterator();

            while (iterator.hasNext()) {
                sb.append(indent).append(indent).append("\"").append(iterator.next().toString()).append("\"");
                if (iterator.hasNext()) {
                    sb.append(",");
                }
                sb.append("\n");
            }
            sb.append(indent);
        }
        sb.append("]\n");

        sb.append("}");
        return sb.toString();
    }
}