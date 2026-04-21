import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export const config = {
  verify_jwt: false,
};

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Development-only bypass for OTP flow demos.
// Set to false before production use.
const DEV_BYPASS = true;

function json(
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeEmail(value: string): string {
  return value.trim().toLowerCase();
}

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    if (req.method !== "POST") {
      return json(405, { error: "method_not_allowed" });
    }

    const body = await req.json().catch(() => null);

    if (!body || typeof body !== "object") {
      return json(400, { error: "invalid_body" });
    }

    const raw = body as Record<string, unknown>;
    const action = raw.action;
    const emailRaw = raw.email;

    if (typeof action !== "string" || typeof emailRaw !== "string") {
      return json(400, { error: "missing_fields" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      return json(500, { error: "missing_supabase_env" });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const email = normalizeEmail(emailRaw);

    // ─── SEND: store OTP + email via Resend ─────────────────────────────
    if (action === "send") {
      if (DEV_BYPASS) {
        return json(200, {
          success: true,
          message: "OTP bypass mode",
        });
      }

      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

      const { error: insertError } = await supabase.from("otp_codes").insert({
        email,
        otp,
        expires_at: expiresAt,
        verified: false,
      });

      if (insertError) {
        console.error("otp insert failed", insertError);
        return json(500, { error: "store_failed", details: insertError.message });
      }

      const apiKey = Deno.env.get("RESEND_API_KEY");
      if (!apiKey) {
        return json(500, { error: "missing_resend_key" });
      }

      const resendRes = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: "Menaka Home Foods <onboarding@resend.dev>",
          to: [email],
          subject: "Your OTP Code",
          html: `<h1>Your OTP is: ${otp}</h1>`,
        }),
      });

      const resendData = await resendRes.json().catch(() => ({}));

      if (!resendRes.ok) {
        return json(500, {
          error: "send_failed",
          details: resendData,
        });
      }

      return json(200, { success: true, message: "OTP sent" });
    }

    // ─── VERIFY: latest unused OTP for email ────────────────────────────
    if (action === "verify") {
      if (DEV_BYPASS) {
        return json(200, {
          success: true,
          isExistingUser: false,
        });
      }

      const otpRaw = raw.otp;
      if (typeof otpRaw !== "string" || !otpRaw.trim()) {
        return json(400, { error: "missing_otp" });
      }

      const otp = otpRaw.trim();

      const { data, error: fetchError } = await supabase
        .from("otp_codes")
        .select("*")
        .eq("email", email)
        .eq("verified", false)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (fetchError) {
        console.error("otp fetch failed", fetchError);
        return json(500, { error: "fetch_failed" });
      }

      if (!data) {
        return json(400, { error: "no_otp" });
      }

      if (new Date(data.expires_at as string) < new Date()) {
        return json(400, { error: "expired" });
      }

      if (String(data.otp) !== otp) {
        return json(400, { error: "invalid" });
      }

      const { error: updateError } = await supabase
        .from("otp_codes")
        .update({ verified: true })
        .eq("id", data.id);

      if (updateError) {
        console.error("otp verify update failed", updateError);
        return json(500, { error: "update_failed" });
      }

      const { data: userExists, error: rpcError } = await supabase.rpc(
        "auth_user_exists",
        { p_email: email },
      );

      if (rpcError) {
        console.error("auth_user_exists failed", rpcError);
        return json(500, { error: "user_check_failed" });
      }

      return json(200, {
        success: true,
        verified: true,
        isExistingUser: userExists === true,
      });
    }

    return json(400, { error: "invalid_action" });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return json(500, { error: message });
  }
});
