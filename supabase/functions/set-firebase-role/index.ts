import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { cert, getApps, initializeApp } from "npm:firebase-admin@14.4.0/app";
import { getAuth } from "npm:firebase-admin@14.4.0/auth";

const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

if (!serviceAccountJson) {
  throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not configured.");
}

const serviceAccount = JSON.parse(serviceAccountJson);

const firebaseApp =
  getApps().length > 0
    ? getApps()[0]
    : initializeApp({
        credential: cert(serviceAccount),
      });

const firebaseAuth = getAuth(firebaseApp);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export default {
  async fetch(req: Request): Promise<Response> {
    if (req.method === "OPTIONS") {
      return new Response("ok", {
        headers: corsHeaders,
      });
    }

    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({
          error: "Method not allowed",
        }),
        {
          status: 405,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    try {
      const authorization = req.headers.get("Authorization");

      if (!authorization?.startsWith("Bearer ")) {
        return new Response(
          JSON.stringify({
            error: "Missing Firebase ID token.",
          }),
          {
            status: 401,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }

      const firebaseIdToken = authorization.substring("Bearer ".length);

      // Verify the Firebase ID token.
      // This also gives us the authenticated Firebase UID.
      const decodedToken =
        await firebaseAuth.verifyIdToken(firebaseIdToken);

      const uid = decodedToken.uid;

      // Get the existing custom claims so we don't accidentally
      // overwrite any other claims in the future.
      const userRecord = await firebaseAuth.getUser(uid);

      const currentClaims = userRecord.customClaims ?? {};

      // Only update Firebase if the role isn't already present.
      if (currentClaims.role !== "authenticated") {
        await firebaseAuth.setCustomUserClaims(uid, {
          ...currentClaims,
          role: "authenticated",
        });
      }

      return new Response(
        JSON.stringify({
          success: true,
          role: "authenticated",
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    } catch (error) {
      console.error("Firebase role assignment failed:", error);

      return new Response(
        JSON.stringify({
          error: "Unable to authenticate Firebase user.",
        }),
        {
          status: 401,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }
  },
};