package com.bcp.training.vault;

import java.util.LinkedHashMap;
import java.util.Map;

import org.eclipse.microprofile.config.inject.ConfigProperty;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/vault-demo")
public class SecretResource {

    @ConfigProperty(name = "vault.secret.file")
    String secretFile;

    @Inject
    SecretFileLoader secretFileLoader;

    @GET
    @Path("/secret")
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, Object> getSecretStatus() {
        Map<String, String> secrets = secretFileLoader.load(secretFile);
        String username = secrets.getOrDefault("DB_USERNAME", "missing");
        String password = secrets.getOrDefault("DB_PASSWORD", "");

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("secretFile", secretFile);
        result.put("secretLoaded", !secrets.isEmpty());
        result.put("dbUsername", username);
        result.put("dbPasswordLength", password.length());
        return result;
    }
}

