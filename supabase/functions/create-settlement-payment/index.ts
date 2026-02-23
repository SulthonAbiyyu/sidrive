// supabase/functions/create-settlement-payment/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

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
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!MIDTRANS_SERVER_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error('Missing environment variables')
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    const { orderId, grossAmount, customerDetails, itemDetails, driverId } = await req.json()

    console.log('💰 Creating SETTLEMENT transaction (Driver → Admin):', orderId)
    console.log('   Driver ID:', driverId)
    console.log('   Amount:', grossAmount)

    // ✅ FIX 1: Get id_user from drivers table
    const { data: driverData, error: driverError } = await supabase
      .from('drivers')
      .select('id_user')
      .eq('id_driver', driverId)
      .single()

    if (driverError || !driverData) {
      console.error('❌ Driver not found:', driverError)
      throw new Error(`Driver not found: ${driverError?.message || 'Unknown error'}`)
    }

    const userId = driverData.id_user
    console.log('✅ User ID found:', userId)

    // 2. Create Midtrans transaction
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

    // 3. Save pending settlement transaction to database
    // ✅ FIX 2: Use userId instead of driverId
    const { error: dbError } = await supabase
      .from('transaksi_keuangan')
      .insert({
        id_user: userId,  // ✅ Pakai userId dari tabel users
        jenis_transaksi: 'settlement_pending',
        jumlah: grossAmount,
        deskripsi: `Settlement ke admin (pending) - Order ID: ${orderId}`,
        metadata: {
          order_id: orderId,
          driver_id: driverId,  // Simpan driverId di metadata
          midtrans_token: midtransData.token,
          status: 'pending',
          settlement_type: 'driver_to_admin',
        },
        created_at: new Date().toISOString(),
      })

    if (dbError) {
      console.error('❌ Database error:', dbError)
      throw new Error(`Database error: ${dbError.message}`)
    }

    console.log('✅ Settlement transaction saved to database')

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