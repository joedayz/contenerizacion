package com.bcp.training.vault;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Map;

import org.junit.jupiter.api.Test;

public class SecretFileLoaderTest {

    @Test
    void parsesExportStyleFile() {
        SecretFileLoader loader = new SecretFileLoader();
        Map<String, String> values = loader.load("src/test/resources/vault-db.env");

        assertEquals("appuser", values.get("DB_USERNAME"));
        assertEquals("supersecret", values.get("DB_PASSWORD"));
    }
}

