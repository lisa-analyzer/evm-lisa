package it.unipr.crossChainAnalysis;

import it.unive.lisa.program.cfg.statement.Statement;
import java.util.*;

public class Signature {
	private final String _name;
	private final String _type;
	private final int _paramCount;
	private final List<String> _paramTypes;
	private final String _fullSignature;
	private final String _selector;
	private Set<Statement> _entryPoints;

	public Signature(String name, String type, int paramCount, List<String> paramTypes, String fullSignature,
			String selector) {
		this._name = name;
		this._type = type;
		this._paramCount = paramCount;
		this._paramTypes = paramTypes;
		this._fullSignature = fullSignature;
		this._selector = selector;
		this._entryPoints = new HashSet<>();
	}

	public String getName() {
		return _name;
	}

	public String getType() {
		return _type;
	}

	public int getParamCount() {
		return _paramCount;
	}

	public List<String> getParamTypes() {
		return _paramTypes;
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
		sb.append(indent).append("\"paramCount\": ").append(_paramCount).append(",\n");

		sb.append(indent).append("\"paramTypes\": [");
		if (!_paramTypes.isEmpty()) {
			sb.append("\n");
			for (int i = 0; i < _paramTypes.size(); i++) {
				sb.append(indent).append(indent).append("\"").append(_paramTypes.get(i)).append("\"");
				if (i < _paramTypes.size() - 1) {
					sb.append(",");
				}
				sb.append("\n");
			}
			sb.append(indent);
		}
		sb.append("],\n");

		sb.append(indent).append("\"fullSignature\": \"").append(_fullSignature).append("\",\n");
		sb.append(indent).append("\"selector\": \"").append(_selector).append("\",\n");

		sb.append(indent).append("\"entrypoints\": [");
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
		sb.append("]\n");

		sb.append("}");
		return sb.toString();
	}
}
