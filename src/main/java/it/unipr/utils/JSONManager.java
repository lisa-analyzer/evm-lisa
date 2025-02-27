package it.unipr.utils;

import it.unipr.analysis.SmartContract;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

public class JSONManager {
	public static JSONObject aggregateSmartContractsToJson(List<SmartContract> contracts) {
		JSONObject aggregatedJson = new JSONObject();
		JSONArray contractsArray = new JSONArray();

		for (SmartContract contract : contracts)
			if (contract != null)
				contractsArray.put(contract.toJson());

		aggregatedJson.put("smart_contracts", contractsArray);
		return aggregatedJson;
	}
}
