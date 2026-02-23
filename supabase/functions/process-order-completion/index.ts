import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    const { idPesanan, idDriver } = await req.json()

    console.log('📦 Processing order completion:', idPesanan)

    // 1. Get order data
    const { data: pesanan, error: pesananError } = await supabase
      .from('pesanan')
      .select('payment_method, total_harga')
      .eq('id_pesanan', idPesanan)
      .single()

    if (pesananError) throw pesananError

    // 2. POIN 6: If cash payment, increment cash order count
    if (pesanan.payment_method === 'cash') {
      console.log('💰 Cash payment detected, incrementing counter...')

      const { data: driver, error: driverError } = await supabase
        .from('drivers')
        .select('jumlah_order_belum_setor, total_cash_pending')
        .eq('id_driver', idDriver)
        .single()

      if (driverError) throw driverError

      const newCount = (driver.jumlah_order_belum_setor || 0) + 1
      const newCashPending = (driver.total_cash_pending || 0) + pesanan.total_harga

      await supabase
        .from('drivers')
        .update({
          jumlah_order_belum_setor: newCount,
          total_cash_pending: newCashPending,
          updated_at: new Date().toISOString(),
        })
        .eq('id_driver', idDriver)

      console.log(`✅ Cash counter updated: ${newCount}/5, pending: ${newCashPending}`)
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Order processed' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('❌ Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})