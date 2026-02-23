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

    console.log('🔍 Checking for stuck orders...')

    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString()

    // Find orders where driver hasn't moved in 10 minutes
    const { data: stuckOrders, error } = await supabase
      .from('pengiriman')
      .select('id_pesanan, id_driver, last_movement_time, pesanan!inner(total_harga)')
      .in('status_pengiriman', ['menuju_pickup', 'pickup_selesai'])
      .lt('last_movement_time', tenMinutesAgo)

    if (error) throw error

    console.log(`Found ${stuckOrders?.length || 0} stuck orders`)

    let canceledCount = 0

    for (const order of stuckOrders || []) {
      const totalHarga = order.pesanan.total_harga
      const biayaAdmin = Math.round((totalHarga * 0.20) / 500) * 500

      console.log(`❌ Auto-canceling order: ${order.id_pesanan}`)

      // Get driver balance
      const { data: driver } = await supabase
        .from('drivers')
        .select('saldo_tersedia, id_user')
        .eq('id_driver', order.id_driver)
        .single()

      if (driver && driver.saldo_tersedia >= biayaAdmin) {
        // Deduct driver balance
        await supabase
          .from('drivers')
          .update({
            saldo_tersedia: driver.saldo_tersedia - biayaAdmin,
            updated_at: new Date().toISOString(),
          })
          .eq('id_driver', order.id_driver)

        // Record transaction
        await supabase
          .from('transaksi_keuangan')
          .insert({
            id_user: driver.id_user,
            jenis_transaksi: 'debit',
            kategori: 'biaya_cancel_auto',
            jumlah: biayaAdmin,
            saldo_sebelum: driver.saldo_tersedia,
            saldo_sesudah: driver.saldo_tersedia - biayaAdmin,
            keterangan: `Auto cancel - GPS tidak bergerak 10 menit`,
            created_at: new Date().toISOString(),
          })
      }

      // Cancel order
      await supabase
        .from('pesanan')
        .update({
          status_pesanan: 'dibatalkan',
          alasan_cancel: 'Auto cancel - Driver GPS tidak bergerak 10 menit',
          waktu_cancel: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id_pesanan', order.id_pesanan)

      await supabase
        .from('pengiriman')
        .update({
          status_pengiriman: 'dibatalkan',
          updated_at: new Date().toISOString(),
        })
        .eq('id_pesanan', order.id_pesanan)

      canceledCount++
    }

    console.log(`✅ Auto-canceled ${canceledCount} orders`)

    return new Response(
      JSON.stringify({ success: true, canceledCount }),
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