package com.bcp.training.vault;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class SecretFileLoader {

    public Map<String, String> load(String filePath) {
        Path path = Path.of(filePath);
        if (!Files.exists(path)) {
            return Map.of();
        }

        try {
            List<String> lines = Files.readAllLines(path);
            Map<String, String> values = new LinkedHashMap<>();
            for (String line : lines) {
                String clean = line.trim();
                if (clean.isEmpty() || clean.startsWith("#")) {
                    continue;
                }
                if (clean.startsWith("export ")) {
                    clean = clean.substring("export ".length());
                }
                int equals = clean.indexOf('=');
                if (equals <= 0) {
                    continue;
                }

                String key = clean.substring(0, equals).trim();
                String value = clean.substring(equals + 1).trim();
                if ((value.startsWith("\"") && value.endsWith("\""))
                        || (value.startsWith("'") && value.endsWith("'"))) {
                    value = value.substring(1, value.length() - 1);
                }
                values.put(key, value);
            }
            return values;
        } catch (IOException e) {
            throw new IllegalStateException("Cannot read Vault secret file: " + filePath, e);
        }
    }
}

