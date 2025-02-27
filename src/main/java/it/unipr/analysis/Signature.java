package it.unipr.analysis;

import it.unive.lisa.program.cfg.statement.Statement;
import java.util.*;
import org.json.JSONArray;
import org.json.JSONObject;

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

	public JSONObject toJson() {
		JSONObject json = new JSONObject();

		json.put("name", _name);
		json.put("type", _type);
		json.put("input_param_count", _inputParamTypes.size());

		JSONArray inputTypesArray = new JSONArray();
		for (String type : _inputParamTypes)
			inputTypesArray.put(type);
		json.put("input_param_types", inputTypesArray);

		json.put("output_param_count", _outputParamTypes.size());

		JSONArray outputTypesArray = new JSONArray();
		for (String type : _outputParamTypes)
			outputTypesArray.put(type);
		json.put("output_param_types", outputTypesArray);

		json.put("full_signature", _fullSignature);
		json.put("selector", _selector);

		JSONArray entryPointsArray = new JSONArray();
		for (Statement stmt : _entryPoints)
			entryPointsArray.put(stmt.toString());
		json.put("entry_points", entryPointsArray);

		JSONArray exitPointsArray = new JSONArray();
		for (Statement stmt : _exitPoints)
			exitPointsArray.put(stmt.toString());

		json.put("exit_points", exitPointsArray);

		return json;
	}

	@Override
	public String toString() {
		return toJson().toString(4);
	}
}