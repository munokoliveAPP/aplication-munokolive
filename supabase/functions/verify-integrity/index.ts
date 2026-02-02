// Supabase Edge Function: verify-integrity
// Validates Google Play Integrity (Android) and Apple App Attest (iOS) tokens

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GOOGLE_PLAY_INTEGRITY_URL = "https://playintegrity.googleapis.com/v1/packageName:decodeIntegrityToken";
// You need to set these in your Supabase Dashboard > Edge Functions > Secrets
// GOOGLE_CLOUD_API_KEY (or Service Account JSON)
// APPLE_APP_ID (e.g. com.example.app)

serve(async (req) => {
  try {
    const { p_token, p_platform } = await req.json();

    if (!p_token) {
      return new Response(JSON.stringify({ error: "Missing token" }), { status: 400 });
    }

    let isValid = false;

    if (p_platform === 'android') {
      // Android: Verify Play Integrity Token
      // Note: This requires a Google Cloud Service Account with Play Integrity API enabled
      // and the proper scope. This is a simplified example using an API Key if allowed,
      // but usually requires OAuth2 service account flow.
      
      console.log("Verifying Android Token...");
      
      // Placeholder for actual Google API call:
      // const result = await fetch(`${GOOGLE_PLAY_INTEGRITY_URL}`, { ... });
      
      // For now, assuming valid if token length > 50 (Mock)
      isValid = p_token.length > 50; 
      
    } else if (p_platform === 'ios') {
      // iOS: Verify App Attest
      // This is complex and requires verifying the attestation object, 
      // the certificate chain, the nonce, and the SHA256 hash.
      // Libraries like 'cbor' and 'asn1' are needed.
      
      console.log("Verifying iOS Token...");
      
      // Placeholder for actual Apple verification logic
      isValid = p_token.length > 50; 
    } else {
       // Unknown platform
       isValid = false;
    }

    if (!isValid) {
      return new Response(JSON.stringify({ valid: false, message: "Integrity check failed" }), {
        headers: { "Content-Type": "application/json" },
        status: 200, // Return 200 so the RPC can parse the boolean/result
      });
    }

    return new Response(JSON.stringify({ valid: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    });
  }
});
