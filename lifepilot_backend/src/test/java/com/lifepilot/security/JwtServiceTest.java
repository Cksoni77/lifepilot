package com.lifepilot.security;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Base64;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

class JwtServiceTest {
    @Test
    void signsAndValidatesAccessTokenSubject() {
        String secret = Base64.getEncoder().encodeToString(new byte[32]);
        JwtService jwtService = new JwtService(secret, 15);
        UUID userId = UUID.randomUUID();

        assertEquals(userId, jwtService.readUserId(jwtService.issueAccessToken(userId)));
    }

    @Test
    void passwordsAreStoredAsVerifiableNonPlaintextHashes() {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String password = "test-password-123";
        String hash = encoder.encode(password);

        assertNotEquals(password, hash);
        assertTrue(encoder.matches(password, hash));
    }
}
