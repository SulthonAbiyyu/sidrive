import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

interface NotificationPayload {
  orderId: string
  userId: string
  driverName: string
  status: string
  latitude?: number
  longitude?: number
  timestamp?: number
}

interface StatusInfo {
  title: string
  body: string
  progress: number
}

serve(async (req) => {
  try {
    console.log('🔥 [Edge Function] Send tracking notification')
    
    const payload: NotificationPayload = await req.json()
    const { orderId, userId, driverName, status, latitude, longitude, timestamp } = payload
    
    console.log(`📦 Order: ${orderId}`)
    console.log(`👤 User: ${userId}`)
    console.log(`🚗 Driver: ${driverName}`)
    console.log(`📊 Status: ${status}`)
    console.log(`📍 Location: ${latitude}, ${longitude}`)
    
    // ✅ VALIDASI KETAT
    if (!orderId || orderId.trim() === '' || 
        !userId || userId.trim() === '' ||
        !driverName || driverName.trim() === '' ||
        !status || status.trim() === '') {
      console.error('❌ Missing or empty required fields')
      return new Response(
        JSON.stringify({ 
          error: 'Missing required fields',
          details: 'All fields must be non-empty strings'
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // ✅ VALIDASI STATUS
    const validStatuses = [
      'diterima', 
      'menuju_pickup', 
      'sampai_pickup', 
      'customer_naik', 
      'perjalanan', 
      'sampai_tujuan', 
      'selesai'
    ]
    
    if (!validStatuses.includes(status)) {
      console.error(`❌ Invalid status: ${status}`)
      return new Response(
        JSON.stringify({ 
          error: 'Invalid status',
          details: `Status must be one of: ${validStatuses.join(', ')}`,
          received: status
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    console.log('✅ Validation passed')
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    // ✅ QUERY FCM TOKEN
    console.log('🔍 Fetching FCM token for user:', userId)
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id_user', userId)
      .single()
    
    if (userError) {
      console.error('❌ Error fetching user:', userError)
      return new Response(
        JSON.stringify({ error: 'User not found', details: userError }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    if (!user?.fcm_token || user.fcm_token.trim() === '') {
      console.error('❌ FCM token is null or empty for user:', userId)
      return new Response(
        JSON.stringify({ 
          error: 'FCM token not found',
          details: 'User has no valid FCM token registered'
        }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    const fcmToken = user.fcm_token
    console.log(`✅ FCM Token found: ${fcmToken.substring(0, 30)}...`)
    
    console.log('🔑 Getting access token...')
    const accessToken = await getAccessToken()
    
    if (!accessToken) {
      console.error('❌ Failed to get access token')
      return new Response(
        JSON.stringify({ error: 'Failed to get access token' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    console.log('✅ Access token obtained')
    
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID') ?? ''
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
    
    const statusInfo = getStatusInfo(status, driverName)
    const progressPercent = statusInfo.progress
    
    console.log(`📱 Sending FCM with ${progressPercent}% progress`)
    console.log(`📱 Title: ${statusInfo.title}`)
    console.log(`📱 Body: ${statusInfo.body}`)
    
    // ✅ KIRIM FCM DENGAN DATA LOCATION
    const fcmResponse = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: statusInfo.title,
            body: statusInfo.body,
          },
          data: {
            orderId: orderId,
            status: status,
            driverName: driverName,
            type: 'tracking_update',
            progress: progressPercent.toString(),
            timestamp: (timestamp || Date.now()).toString(),
            latitude: latitude?.toString() || '',
            longitude: longitude?.toString() || '',
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'tracking_channel',
              tag: `order_${orderId}`,
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              icon: '@mipmap/ic_launcher',
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                contentAvailable: true,
                badge: 1,
              },
            },
          },
        },
      }),
    })
    
    const fcmResult = await fcmResponse.json()
    
    if (fcmResponse.ok) {
      console.log('✅ FCM sent successfully')
      console.log('📋 FCM Response:', JSON.stringify(fcmResult))
      return new Response(
        JSON.stringify({ success: true, result: fcmResult }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    } else {
      console.error('❌ FCM failed:', fcmResult)
      return new Response(
        JSON.stringify({ error: 'FCM failed', details: fcmResult }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
  } catch (error) {
    console.error('❌ Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

function getStatusInfo(status: string, driverName: string): StatusInfo {
  switch (status) {
    case 'diterima': 
      return {
        title: `✅ ${driverName} Menerima Pesanan`,
        body: 'Driver sedang bersiap',
        progress: 15
      }
    case 'menuju_pickup': 
      return {
        title: `🚗 ${driverName} Menuju Lokasi Anda`,
        body: 'Estimasi 3-5 menit',
        progress: 35
      }
    case 'sampai_pickup': 
      return {
        title: `📍 ${driverName} Telah Tiba`,
        body: 'Driver menunggu Anda',
        progress: 50
      }
    case 'customer_naik': 
      return {
        title: '👤 Perjalanan Dimulai',
        body: 'Menuju ke tujuan',
        progress: 60
      }
    case 'perjalanan': 
      return {
        title: '🛣️ Dalam Perjalanan',
        body: 'Sedang menuju tujuan Anda',
        progress: 80
      }
    case 'sampai_tujuan': 
      return {
        title: '🎯 Sampai di Tujuan',
        body: 'Anda telah tiba',
        progress: 95
      }
    case 'selesai': 
      return {
        title: '🎉 Pesanan Selesai',
        body: 'Terima kasih!',
        progress: 100
      }
    default: 
      return {
        title: '📦 Update Pesanan',
        body: 'Pesanan diproses',
        progress: 0
      }
  }
}

async function getAccessToken(): Promise<string | null> {
  try {
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY') ?? ''
    
    if (!serviceAccountJson) {
      console.error('❌ FIREBASE_SERVICE_ACCOUNT_KEY not set')
      return null
    }
    
    const serviceAccount = JSON.parse(serviceAccountJson)
    
    const jwtHeader = base64urlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
    
    const now = Math.floor(Date.now() / 1000)
    const jwtPayload = base64urlEncode(JSON.stringify({
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }))
    
    // ✅ FIX: Handle \n dengan benar
    const privateKey = serviceAccount.private_key.replace(/\\n/g, '\n')
    
    const pemHeader = '-----BEGIN PRIVATE KEY-----'
    const pemFooter = '-----END PRIVATE KEY-----'
    const pemContents = privateKey
      .replace(pemHeader, '')
      .replace(pemFooter, '')
      .replace(/\s/g, '')
    
    const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))
    
    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      binaryDer,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign']
    )
    
    const textEncoder = new TextEncoder()
    const dataToSign = textEncoder.encode(`${jwtHeader}.${jwtPayload}`)
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      cryptoKey,
      dataToSign
    )
    
    const jwtSignature = base64urlEncode(String.fromCharCode(...new Uint8Array(signature)))
    
    const jwt = `${jwtHeader}.${jwtPayload}.${jwtSignature}`
    
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    })
    
    if (!tokenResponse.ok) {
      console.error('❌ Token response not OK:', await tokenResponse.text())
      return null
    }
    
    const tokenData = await tokenResponse.json()
    return tokenData.access_token
    
  } catch (error) {
    console.error('❌ Error getting access token:', error)
    return null
  }
}

function base64urlEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
}