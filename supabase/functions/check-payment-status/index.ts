import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')

    if (!MIDTRANS_SERVER_KEY) {
      throw new Error('MIDTRANS_SERVER_KEY is missing')
    }

    const { orderId } = await req.json()

    console.log('🔍 Checking payment status for:', orderId)

    const midtransAuth = btoa(`${MIDTRANS_SERVER_KEY}:`)
    
    const response = await fetch(`https://api.sandbox.midtrans.com/v2/${orderId}/status`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Authorization': `Basic ${midtransAuth}`,
      },
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ Midtrans error:', errorText)
      throw new Error(`Midtrans error: ${errorText}`)
    }

    const data = await response.json()
    
    console.log('✅ Transaction status:', data.transaction_status)

    return new Response(
      JSON.stringify({
        transaction_status: data.transaction_status,
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
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})