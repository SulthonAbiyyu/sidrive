import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

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
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!MIDTRANS_SERVER_KEY) {
      throw new Error('MIDTRANS_SERVER_KEY is missing')
    }

    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error('Supabase credentials are missing')
    }

    const { orderId, grossAmount, customerDetails, itemDetails } = await req.json()

    console.log('🔐 Creating Midtrans transaction for order:', orderId)

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

    // 4. Update database dengan token & response
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    const { error: updateError } = await supabase
      .from('pesanan')
      .update({
        midtrans_token: midtransData.token,
        payment_gateway_response: midtransData,
        updated_at: new Date().toISOString(),
      })
      .eq('id_pesanan', orderId)

    if (updateError) {
      console.error('❌ Database update error:', updateError)
      throw new Error(`Database error: ${updateError.message}`)
    }

    console.log('✅ Database updated for order:', orderId)

    // 5. Return response ke Flutter
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