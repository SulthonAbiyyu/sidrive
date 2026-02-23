import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

serve(async (req) => {
  // ============================================================================
  // 0. HANDLE CORS PREFLIGHT
  // ============================================================================
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders,
      status: 204,
    })
  }

  try {
    // ============================================================================
    // 1. VALIDASI AUTHORIZATION (INI AKAR ERROR KAMU)
    // ============================================================================
    const authHeader = req.headers.get("Authorization")

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing or invalid Authorization header",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 401,
        }
      )
    }

    // ============================================================================
    // 2. VALIDASI ENV
    // ============================================================================
    const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY")
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    const IS_PRODUCTION = Deno.env.get("IS_PRODUCTION") === "true"

    if (!MIDTRANS_SERVER_KEY) throw new Error("MIDTRANS_SERVER_KEY is missing")
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY)
      throw new Error("Supabase credentials are missing")

    // ============================================================================
    // 3. PARSE BODY
    // ============================================================================
    const {
      payoutId,
      adminId,
      amount,
      bankCode,
      bankName,
      accountNumber,
      accountHolderName,
      notes,
    } = await req.json()

    if (
      !payoutId ||
      !adminId ||
      !amount ||
      !bankCode ||
      !accountNumber ||
      !accountHolderName
    ) {
      throw new Error("Missing required fields")
    }

    if (amount < 100000) {
      throw new Error("Minimum withdrawal amount is Rp 100.000")
    }

    // ============================================================================
    // 4. SUPABASE CLIENT
    // ============================================================================
    const supabase = createClient(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY
    )

    await supabase
      .from("admin_payouts")
      .update({
        status: "processing",
        processed_at: new Date().toISOString(),
      })
      .eq("id", payoutId)

    // ============================================================================
    // 5. MIDTRANS PAYOUT
    // ============================================================================
    const midtransBaseUrl = IS_PRODUCTION
      ? "https://app.midtrans.com/iris/api/v1"
      : "https://app.sandbox.midtrans.com/iris/api/v1"

    const midtransAuth = btoa(`${MIDTRANS_SERVER_KEY}:`)

    const midtransRequestBody = {
      payouts: [
        {
          beneficiary_name: accountHolderName,
          beneficiary_account: accountNumber,
          beneficiary_bank: bankCode.toLowerCase(),
          beneficiary_email: `admin-${adminId}@sidrive.com`,
          amount: amount.toString(),
          notes: notes || `Admin Payout ${new Date().toISOString()}`,
        },
      ],
    }

    const midtransResponse = await fetch(`${midtransBaseUrl}/payouts`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: `Basic ${midtransAuth}`,
      },
      body: JSON.stringify(midtransRequestBody),
    })

    const contentType = midtransResponse.headers.get("content-type")

    if (!contentType?.includes("application/json")) {
      const text = await midtransResponse.text()
      throw new Error(`Midtrans non-JSON response: ${text}`)
    }

    const midtransData = await midtransResponse.json()

    if (!midtransResponse.ok) {
      throw new Error(midtransData.error_message || "Midtrans payout failed")
    }

    const payoutResult = midtransData.payouts?.[0]
    if (!payoutResult) throw new Error("Invalid Midtrans response")

    const referenceNo = payoutResult.reference_no
    const payoutStatus = payoutResult.status

    const dbStatus =
      payoutStatus === "completed"
        ? "completed"
        : payoutStatus === "failed"
        ? "failed"
        : "processing"

    await supabase
      .from("admin_payouts")
      .update({
        reference_no: referenceNo,
        status: dbStatus,
        midtrans_response: payoutResult,
        completed_at:
          dbStatus !== "processing"
            ? new Date().toISOString()
            : null,
      })
      .eq("id", payoutId)

    // ============================================================================
    // 6. RESPONSE SUCCESS
    // ============================================================================
    return new Response(
      JSON.stringify({
        success: true,
        message: "Payout request submitted successfully",
        data: {
          payout_id: payoutId,
          reference_no: referenceNo,
          status: dbStatus,
        },
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    )
  } catch (error) {
    console.error("❌ Edge Function error:", error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    )
  }
})
