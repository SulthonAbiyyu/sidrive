import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')

    if (!MIDTRANS_SERVER_KEY) {
      throw new Error('MIDTRANS_SERVER_KEY is missing')
    }

    const { orderId, grossAmount, customerDetails, itemDetails } = await req.json()

    console.log('💰 Creating Midtrans transaction for TOP UP:', orderId)

    const midtransAuth = btoa(`${MIDTRANS_SERVER_KEY}:`)
    
    const midtransResponse = await fetch('https://app.sandbox.midtrans.com/snap/v1/transactions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Basic ${midtransAuth}`,
      },
      body: JSON.stringify({
        transaction_details: {
          order_id: orderId,
          gross_amount: grossAmount,
        },
        customer_details: customerDetails,
        item_details: itemDetails,
        enabled_payments: [
          'gopay',
          'shopeepay',
          'other_qris',
          'bca_va',
          'bni_va',
          'bri_va',
          'permata_va',
        ],
        callbacks: {
          finish: 'sidrive://payment/finish',
        },
      }),
    })

    if (!midtransResponse.ok) {
      const errorText = await midtransResponse.text()
      console.error('❌ Midtrans error:', errorText)
      throw new Error(`Midtrans error: ${errorText}`)
    }

    const midtransData = await midtransResponse.json()
    console.log('✅ Midtrans transaction created:', midtransData.token)

    // ✅ TIDAK ADA UPDATE DATABASE DI SINI!
    // Top up tracking sudah dilakukan di wallet_topup_service.dart

    // Return response ke Flutter
    return new Response(
      JSON.stringify({
        token: midtransData.token,
        redirect_url: midtransData.redirect_url,
        order_id: orderId,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('❌ Function error:', error)
    return new Response(
      JSON.stringify({
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})