package it.unipr.frontend;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

public class SMAddress {
	
	private final static String API_KEY = "V1JWVWVCKP23DVXI1I2TX8V19XICS3TIJ6";
	
	public static String parseSMAddress(String address) throws IOException {
        String bytecodeRequest = request("proxy", "eth_getCode", address);
        String[] test = bytecodeRequest.split("\"");
        System.out.println(test[9]);
        return test[9];
	}
	
	private static String request(String module, String action, String address) throws IOException {
        String request = String.format("https://api.etherscan.io/api?module=%s&action=%s&address=%s&apikey=%s",
        								module, action, address, API_KEY);
        
        URL requestUrl = new URL(request);
        HttpURLConnection connection = (HttpURLConnection) requestUrl.openConnection();
        connection.setRequestMethod("GET");
        connection.setRequestProperty("User-Agent", "Mozilla/5.0");
        
        if (connection.getResponseCode() == HttpURLConnection.HTTP_OK){
            BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
            StringBuilder sb = new StringBuilder();
            String readLine = null;
            while ((readLine = in.readLine()) != null) {
                sb.append(readLine);
            }
            in.close();
            return sb.toString();
        } else {
            return null;
        }

	}
}
