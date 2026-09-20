import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { cert, getApps, initializeApp } from "npm:firebase-admin@14.4.0/app";
import { getAuth } from "npm:firebase-admin@14.4.0/auth";

const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
const groqApiKey = Deno.env.get("GROQ_API_KEY");

if (!serviceAccountJson) {
  throw new Error("FIREBASE_SERVICE_ACCOUNT secret is not configured.");
}

if (!groqApiKey) {
  throw new Error("GROQ_API_KEY secret is not configured.");
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

      const decodedToken =
        await firebaseAuth.verifyIdToken(firebaseIdToken);

      const uid = decodedToken.uid;

      console.log(`Transcription requested by Firebase user: ${uid}`);

      const contentType = req.headers.get("Content-Type") ?? "";

      if (!contentType.startsWith("audio/")) {
        return new Response(
          JSON.stringify({
            error: "Request body must contain an audio file.",
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }

      const audioBytes = await req.arrayBuffer();

      if (audioBytes.byteLength === 0) {
        return new Response(
          JSON.stringify({
            error: "Audio file is empty.",
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }

      const formData = new FormData();

      const audioBlob = new Blob([audioBytes], {
        type: contentType,
      });

      formData.append(
        "file",
        audioBlob,
        "voice.m4a",
      );

      formData.append(
        "model",
        "whisper-large-v3-turbo",
      );

      formData.append(
        "response_format",
        "json",
      );

      formData.append(
        "temperature",
        "0",
      );

      const groqResponse = await fetch(
        "https://api.groq.com/openai/v1/audio/transcriptions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${groqApiKey}`,
          },
          body: formData,
        },
      );

      if (!groqResponse.ok) {
        const errorBody = await groqResponse.text();

        console.error(
          "Groq transcription failed:",
          groqResponse.status,
          errorBody,
        );

        return new Response(
          JSON.stringify({
            error: "Speech transcription failed.",
          }),
          {
            status: 502,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }

      const transcription = await groqResponse.json();

      const text =
        transcription?.text?.toString().trim() ?? "";

      if (!text) {
        return new Response(
          JSON.stringify({
            error: "No speech was detected.",
          }),
          {
            status: 422,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
            },
          },
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          text,
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
      console.error(
        "Audio transcription failed:",
        error,
      );

      return new Response(
        JSON.stringify({
          error: "Unable to transcribe audio.",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }
  },
};