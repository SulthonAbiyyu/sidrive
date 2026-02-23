// ═══════════════════════════════════════════════════════════════════════════════
// 🔥 MIDTRANS WEBHOOK - FIXED SIGNATURE VERIFICATION
// 
// FIX: Explicit String() conversion untuk statusCode karena Midtrans bisa kirim
//      sebagai string "201" atau number 201
// ═══════════════════════════════════════════════════════════════════════════════

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// 🔥 HELPER: SHA512 Hash (BUKAN HMAC!)
async function sha512Hash(text: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(text)
  const hashBuffer = await crypto.subtle.digest('SHA-512', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  return hashHex
}

serve(async (req) => {
  console.log('📢 ========== MIDTRANS UNIFIED WEBHOOK ==========')
  console.log('⏰ Timestamp:', new Date().toISOString())
  
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')
    console.log('🔑 ========== SERVER KEY DEBUG ==========')
    console.log('   Length:', MIDTRANS_SERVER_KEY?.length)
    console.log('   First 15 chars:', MIDTRANS_SERVER_KEY?.substring(0, 15))
    console.log('   Last 10 chars:', MIDTRANS_SERVER_KEY?.substring(MIDTRANS_SERVER_KEY.length - 10))
    console.log('   Expected: Mid-server-aJ...nobB7ycRmvv')
    console.log('========================================')
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!MIDTRANS_SERVER_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      console.error('❌ Missing environment variables')
      throw new Error('Missing environment variables')
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { 
        persistSession: false,
        autoRefreshToken: false 
      }
    })

    // ========== PARSE NOTIFICATION ==========
    const notification = await req.json()
    
    console.log('📦 RAW NOTIFICATION:')
    console.log(JSON.stringify(notification, null, 2))
    
    const orderId = notification.order_id
    const transactionStatus = notification.transaction_status
    const fraudStatus = notification.fraud_status
    const statusCodeRaw = notification.status_code
    const signatureKey = notification.signature_key
    const grossAmountRaw = notification.gross_amount
    
    // 🔥 CRITICAL FIX: Convert statusCode ke STRING explicitly
    const statusCode = String(statusCodeRaw)
    
    console.log('📋 Notification Details:')
    console.log('   Order ID:', orderId)
    console.log('   Status Code (raw):', statusCodeRaw, 'Type:', typeof statusCodeRaw)
    console.log('   Status Code (converted):', statusCode, 'Type:', typeof statusCode)
    console.log('   Transaction Status:', transactionStatus)
    console.log('   Gross Amount RAW:', grossAmountRaw)
    console.log('   Gross Amount TYPE:', typeof grossAmountRaw)
    console.log('   Signature (received):', signatureKey)

    // ========== 🔥 VERIFY SIGNATURE (SHA512 HASH!) ==========
    console.log('🔐 ========== SIGNATURE VERIFICATION ==========')
    
    // Convert gross_amount ke string
    let grossAmountString = String(grossAmountRaw)
    
    // 🔥 CRITICAL: Midtrans pakai format tanpa decimal jika integer!
    // Try #1: Format asli yang dikirim
    const signatureInput1 = `${orderId}${statusCode}${grossAmountString}${MIDTRANS_SERVER_KEY}`
    console.log('   Try #1 - Input:', signatureInput1.substring(0, 60) + '...')
    console.log('   Try #1 - Length:', signatureInput1.length)
    
    const expectedSignature1 = await sha512Hash(signatureInput1)
    console.log('   Expected:', expectedSignature1)
    console.log('   Received:', signatureKey)
    console.log('   Match:', signatureKey === expectedSignature1)

    let isValid = signatureKey === expectedSignature1
    let grossAmountFinal = grossAmountString

    // Jika tidak match, coba format alternatif
    if (!isValid) {
      console.log('   ⚠️ Try #1 failed, trying alternatives...')
      
      // Alternative 1: Parse ke number lalu convert ke integer string (remove decimal)
      const grossAmountNumber = parseFloat(String(grossAmountRaw))
      const grossAmountInt = String(Math.round(grossAmountNumber))
      const signatureInput2 = `${orderId}${statusCode}${grossAmountInt}${MIDTRANS_SERVER_KEY}`
      console.log('   Try #2 - Input:', signatureInput2.substring(0, 60) + '...')
      console.log('   Try #2 - Gross Amount:', grossAmountInt)
      
      const expectedSignature2 = await sha512Hash(signatureInput2)
      console.log('   Expected:', expectedSignature2)
      console.log('   Match:', signatureKey === expectedSignature2)
      
      if (signatureKey === expectedSignature2) {
        isValid = true
        grossAmountFinal = grossAmountInt
        console.log('   ✅ Try #2 SUCCESS!')
      } else {
        // Alternative 2: Tambah .00 jika belum ada
        const grossAmountWithDecimal = grossAmountString.includes('.') 
          ? grossAmountString 
          : `${grossAmountString}.00`
        
        const signatureInput3 = `${orderId}${statusCode}${grossAmountWithDecimal}${MIDTRANS_SERVER_KEY}`
        console.log('   Try #3 - Input:', signatureInput3.substring(0, 60) + '...')
        console.log('   Try #3 - Gross Amount:', grossAmountWithDecimal)
        
        const expectedSignature3 = await sha512Hash(signatureInput3)
        console.log('   Expected:', expectedSignature3)
        console.log('   Match:', signatureKey === expectedSignature3)
        
        if (signatureKey === expectedSignature3) {
          isValid = true
          grossAmountFinal = grossAmountWithDecimal
          console.log('   ✅ Try #3 SUCCESS!')
        }
      }
    }

    if (!isValid) {
      console.error('❌❌❌ SIGNATURE VERIFICATION FAILED! ❌❌❌')
      console.error('Debug Info:')
      console.error('   Server Key Length:', MIDTRANS_SERVER_KEY.length)
      console.error('   Server Key First 10 chars:', MIDTRANS_SERVER_KEY.substring(0, 10))
      console.error('   Server Key Last 10 chars:', MIDTRANS_SERVER_KEY.substring(MIDTRANS_SERVER_KEY.length - 10))
      console.error('   Order ID:', orderId)
      console.error('   Status Code (raw):', statusCodeRaw, 'Type:', typeof statusCodeRaw)
      console.error('   Status Code (string):', statusCode, 'Type:', typeof statusCode)
      console.error('   Gross Amount (raw):', grossAmountRaw, 'Type:', typeof grossAmountRaw)
      console.error('   Gross Amount (string):', grossAmountString)
      
      return new Response(JSON.stringify({ 
        error: 'Invalid signature',
        debug: {
          orderId,
          statusCodeRaw,
          statusCodeType: typeof statusCodeRaw,
          statusCodeString: statusCode,
          grossAmountRaw,
          grossAmountType: typeof grossAmountRaw,
          grossAmountString,
          receivedSignature: signatureKey,
          serverKeyPreview: MIDTRANS_SERVER_KEY.substring(0, 10) + '...' + MIDTRANS_SERVER_KEY.substring(MIDTRANS_SERVER_KEY.length - 10)
        }
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401
      })
    }

    console.log('✅✅✅ SIGNATURE VERIFIED! ✅✅✅')

    // Parse gross_amount untuk database
    const grossAmount = parseFloat(grossAmountFinal)

    // ═══════════════════════════════════════════════════════════════
    // ROUTE 1: SETTLEMENT (SETL-xxx)
    // ═══════════════════════════════════════════════════════════════
    if (orderId.startsWith('SETL')) {
      console.log('💵 ========== SETTLEMENT ==========')
      
      if (transactionStatus === 'settlement' || 
          (transactionStatus === 'capture' && fraudStatus === 'accept')) {
        
        const { data: transaksi } = await supabase
          .from('transaksi_keuangan')
          .select('metadata')
          .eq('metadata->>order_id', orderId)
          .maybeSingle()

        if (!transaksi) {
          console.error('❌ Transaction not found')
          return new Response(
            JSON.stringify({ success: false, message: 'Transaction not found' }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }

        const driverId = transaksi.metadata.driver_id

        const { data: result, error: rpcError } = await supabase.rpc(
          'topup_admin_wallet_from_settlement',
          {
            p_driver_id: driverId,
            p_amount: grossAmount,
            p_order_id: orderId,
          }
        )

        if (rpcError) {
          console.error('❌ RPC error:', rpcError.message)
          return new Response(
            JSON.stringify({ success: false, message: rpcError.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }

        console.log('✅ Settlement processed')
        return new Response(
          JSON.stringify({ success: true, result }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      }
      
      return new Response(
        JSON.stringify({ message: 'Settlement not final' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ROUTE 2: TOPUP (TOPUP-xxx)
    // ═══════════════════════════════════════════════════════════════
    else if (orderId.startsWith('TOPUP')) {
      console.log('💰 ========== TOPUP ==========')
      
      if (transactionStatus === 'settlement' || 
          (transactionStatus === 'capture' && fraudStatus === 'accept')) {
        
        const { data: transaksi } = await supabase
          .from('transaksi_keuangan')
          .select('*')
          .eq('metadata->>order_id', orderId)
          .maybeSingle()

        if (!transaksi) {
          console.error('❌ Transaction not found')
          return new Response(
            JSON.stringify({ success: false, message: 'Transaction not found' }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }

        if (transaksi.status === 'success') {
          console.log('⚠️ Already processed')
          return new Response(
            JSON.stringify({ success: true, message: 'Already processed' }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }

        const userId = transaksi.id_user

        const { error: walletError } = await supabase.rpc('topup_wallet', {
          p_user_id: userId,
          p_amount: grossAmount,
          p_transaction_id: transaksi.id_transaksi
        })

        if (walletError) {
          console.error('❌ Topup failed:', walletError)
          return new Response(
            JSON.stringify({ success: false, message: walletError.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }

        await supabase
          .from('transaksi_keuangan')
          .update({ status: 'success', updated_at: new Date().toISOString() })
          .eq('id_transaksi', transaksi.id_transaksi)

        console.log('✅ Topup completed')
        return new Response(
          JSON.stringify({ success: true, message: 'Topup processed' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      }
      
      return new Response(
        JSON.stringify({ message: 'Topup not final' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ROUTE 3: ORDER PAYMENT (OJEK & UMKM)
    // ═══════════════════════════════════════════════════════════════
    else {
      console.log('🛒 ========== ORDER PAYMENT ==========')
      
      const { data: pesanan, error: orderError } = await supabase
        .from('pesanan')
        .select('*')
        .eq('id_pesanan', orderId)
        .maybeSingle()

      if (orderError || !pesanan) {
        console.error('❌ Order not found:', orderId)
        return new Response(
          JSON.stringify({ success: false, message: 'Order not found' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      }

      console.log('📦 Order Type:', pesanan.jenis)
      console.log('📦 Total:', pesanan.total_harga)
      console.log('📦 Current Status:', pesanan.payment_status)

      // Idempotency check
      if (pesanan.payment_status === 'paid') {
        console.log('⚠️ Already processed (idempotent)')
        return new Response(
          JSON.stringify({ success: true, message: 'Already processed' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      }

      // Process success payment
      if (transactionStatus === 'settlement' || 
          (transactionStatus === 'capture' && fraudStatus === 'accept')) {
        
        console.log('💰 Payment SUCCESS!')

        // STEP 1: Credit admin wallet
        console.log('💰 Crediting admin wallet:', grossAmount)
        
        const { data: creditResult, error: creditError } = await supabase.rpc(
          'credit_to_admin_wallet',
          {
            p_order_id: orderId,
            p_amount: grossAmount,
            p_customer_id: pesanan.id_user,
            p_description: `Payment for ${pesanan.jenis} order`
          }
        )

        if (creditError) {
          console.error('❌ Credit admin wallet failed:', creditError.message)
          return new Response(
            JSON.stringify({ success: false, message: creditError.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }

        if (!creditResult || !creditResult.success) {
          console.error('❌ Credit failed:', creditResult)
          return new Response(
            JSON.stringify({ success: false, message: 'Failed to credit admin wallet' }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }
        
        console.log('✅ Admin wallet credited:', creditResult.admin_new_balance)

        // STEP 2: Update order status
        let newStatus = 'mencari_driver'
        if (pesanan.jenis === 'umkm') {
          newStatus = 'menunggu_konfirmasi'
        }

        console.log('📝 Updating order status to:', newStatus)

        const updateData = {
          payment_status: 'paid',
          status_pesanan: newStatus,
          updated_at: new Date().toISOString(),
        }

        if (newStatus === 'mencari_driver') {
          updateData.search_start_time = new Date().toISOString()
        }

        const { error: updateError } = await supabase
          .from('pesanan')
          .update(updateData)
          .eq('id_pesanan', orderId)

        if (updateError) {
          console.error('❌ Update order failed:', updateError)
          return new Response(
            JSON.stringify({ success: false, message: updateError.message }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
          )
        }

        console.log('✅ Order status updated')
        console.log('✅✅✅ WEBHOOK COMPLETED SUCCESSFULLY ✅✅✅')

        return new Response(
          JSON.stringify({
            success: true,
            message: 'Payment confirmed',
            order_id: orderId,
            new_status: newStatus,
            admin_wallet_credited: grossAmount
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      }
      
      // Pending
      else if (transactionStatus === 'pending') {
        console.log('⏳ Payment pending')
        return new Response(
          JSON.stringify({ message: 'Pending' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      }
      
      // Failed
      else if (['deny', 'cancel', 'expire', 'failure'].includes(transactionStatus)) {
        console.log('❌ Payment failed:', transactionStatus)
        
        await supabase
          .from('pesanan')
          .update({
            payment_status: 'failed',
            status_pesanan: 'dibatalkan',
            updated_at: new Date().toISOString(),
          })
          .eq('id_pesanan', orderId)
        
        return new Response(
          JSON.stringify({ message: 'Payment failed' }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
        )
      }

      console.log('⚠️ Unknown status:', transactionStatus)
      return new Response(
        JSON.stringify({ message: 'Unknown status' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      )
    }

  } catch (error) {
    console.error('❌❌❌ WEBHOOK ERROR ❌❌❌')
    console.error('Message:', error.message)
    console.error('Stack:', error.stack)
    
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  }
})