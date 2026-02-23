import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

interface NewOrderPayload {
  orderId: string
  customerId: string
  customerName: string
  jenisPesanan: string      // ✅ BARU: 'ojek' | 'umkm'
  jenisKendaraan?: string   // ✅ Optional untuk UMKM
  lokasiJemput: string
  lokasiTujuan: string
  lokasiJemputLat: number
  lokasiJemputLng: number
  lokasiTokoLat?: number    // ✅ BARU: untuk UMKM
  lokasiTokoLng?: number    // ✅ BARU: untuk UMKM
  jarak: number
  ongkir: number
  timestamp?: number
}

serve(async (req) => {
  try {
    console.log('📢 [New Order Notification] Starting...')
    
    const payload: NewOrderPayload = await req.json()
    const { 
      orderId, 
      customerId,
      customerName,
      jenisPesanan,      // ✅ BARU
      jenisKendaraan,
      lokasiJemput, 
      lokasiTujuan,
      lokasiJemputLat,
      lokasiJemputLng,
      lokasiTokoLat,     // ✅ BARU
      lokasiTokoLng,     // ✅ BARU
      jarak,
      ongkir,
      timestamp 
    } = payload
    
    console.log(`📦 Order: ${orderId}`)
    console.log(`📋 Jenis: ${jenisPesanan}`)
    console.log(`🚗 Vehicle: ${jenisKendaraan || 'N/A'}`)
    console.log(`📍 Pickup: ${lokasiJemput} (${lokasiJemputLat}, ${lokasiJemputLng})`)
    if (lokasiTokoLat && lokasiTokoLng) {
      console.log(`🏪 Toko: (${lokasiTokoLat}, ${lokasiTokoLng})`)
    }
    console.log(`📍 Destination: ${lokasiTujuan}`)
    console.log(`💰 Price: Rp ${ongkir}`)
    
    // ✅ Validasi
    if (!orderId || !jenisPesanan || !lokasiJemput || !lokasiTujuan || !lokasiJemputLat || !lokasiJemputLng) {
      console.error('❌ Missing required fields')
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // ✅ Validasi UMKM harus punya lokasi toko
    if (jenisPesanan === 'umkm' && (!lokasiTokoLat || !lokasiTokoLng)) {
      console.error('❌ UMKM order missing toko location')
      return new Response(
        JSON.stringify({ error: 'UMKM order requires toko location' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    // ✅ STEP 1: Query driver berdasarkan jenis pesanan
    console.log('🔍 Fetching online drivers...')
    
    let driversQuery = supabase
      .from('drivers')
      .select(`
        id_driver,
        id_user,
        current_location
      `)
      .eq('is_online', true)
      .not('current_location', 'is', null)
    
    // ✅ CONDITIONAL: Jika OJEK, filter by vehicle type
    if (jenisPesanan === 'ojek' && jenisKendaraan) {
      console.log(`🚗 Filtering for vehicle: ${jenisKendaraan}`)
      
      driversQuery = driversQuery.select(`
        id_driver,
        id_user,
        current_location,
        driver_vehicles!inner(
          jenis_kendaraan,
          is_active,
          status_verifikasi
        )
      `)
      .eq('driver_vehicles.is_active', true)
      .eq('driver_vehicles.status_verifikasi', 'approved')
      .eq('driver_vehicles.jenis_kendaraan', jenisKendaraan)
    }

    const { data: onlineDrivers, error: driversError } = await driversQuery

    if (driversError) {
      console.error('❌ Error fetching drivers:', driversError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch drivers', details: driversError }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    if (!onlineDrivers || onlineDrivers.length === 0) {
      console.log('⚠️ No online drivers found')
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'No online drivers available',
          driversNotified: 0
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    console.log(`✅ Found ${onlineDrivers.length} online driver(s)`)
    
    // ✅ STEP 2: Hitung jarak driver berdasarkan jenis pesanan
    console.log('📏 Calculating driver distances...')
    
    // ✅ PENTING: Untuk UMKM, hitung jarak dari DRIVER → TOKO
    //            Untuk OJEK, hitung jarak dari DRIVER → PICKUP CUSTOMER
    const referencePoint = jenisPesanan === 'umkm'
      ? `POINT(${lokasiTokoLng} ${lokasiTokoLat})`
      : `POINT(${lokasiJemputLng} ${lokasiJemputLat})`
    
    console.log(`📍 Reference point (${jenisPesanan}): ${referencePoint}`)
    
    const driversWithDistance: Array<{ 
      id_driver: string
      id_user: string
      distance_km: number 
    }> = []
    
    for (const driver of onlineDrivers) {
      try {
        const { data: distanceData, error: distanceError } = await supabase
          .rpc('calculate_distance_km', {
            point1: driver.current_location,
            point2: referencePoint
          })
        
        if (distanceError) {
          console.error(`⚠️ Error calculating distance for driver ${driver.id_driver}:`, distanceError)
          continue
        }
        
        const distance = distanceData as number
        console.log(`  - Driver ${driver.id_driver}: ${distance.toFixed(2)} km`)
        
        // ✅ Filter: HANYA driver dalam radius 10km
        if (distance <= 10) {
          driversWithDistance.push({
            id_driver: driver.id_driver,
            id_user: driver.id_user,
            distance_km: distance
          })
        } else {
          console.log(`    ❌ Too far (${distance.toFixed(2)} km > 10 km)`)
        }
        
      } catch (e) {
        console.error(`⚠️ Error processing driver ${driver.id_driver}:`, e)
      }
    }
    
    if (driversWithDistance.length === 0) {
      console.log('❌ No drivers within 10km radius')
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'No drivers available within 10km',
          driversNotified: 0,
          totalDriversOnline: onlineDrivers.length
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // ✅ Sort by distance (terdekat dulu)
    driversWithDistance.sort((a, b) => a.distance_km - b.distance_km)
    
    console.log(`✅ Found ${driversWithDistance.length} driver(s) within 10km`)
    
    // ✅ STEP 3: Ambil FCM tokens
    const nearbyDriverUserIds = driversWithDistance.map(d => d.id_user)
    
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id_user, fcm_token, nama')
      .in('id_user', nearbyDriverUserIds)
      .not('fcm_token', 'is', null)
    
    if (usersError || !users || users.length === 0) {
      console.error('❌ No FCM tokens found')
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'No valid FCM tokens',
          driversNotified: 0
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    console.log(`✅ Found ${users.length} driver(s) with FCM tokens`)
    
    // ✅ STEP 4: Get Access Token
    console.log('🔑 Getting access token...')
    const accessToken = await getAccessToken()
    
    if (!accessToken) {
      console.error('❌ Failed to get access token')
      return new Response(
        JSON.stringify({ error: 'Failed to get access token' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID') ?? ''
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
    
    // ✅ Format harga
    const formattedPrice = new Intl.NumberFormat('id-ID').format(ongkir)
    
    // ✅ STEP 5: Kirim notifikasi
    const notifications: Promise<any>[] = []
    let successCount = 0
    let failCount = 0
    
    // ✅ Tentukan title berdasarkan jenis pesanan
    const notifTitle = jenisPesanan === 'umkm'
      ? 'Pesanan UMKM Baru!'
      : `Pesanan ${jenisKendaraan?.toUpperCase() || 'MOTOR'} Baru!`
    
    for (const user of users) {
      const fcmToken = user.fcm_token
      
      const driverInfo = driversWithDistance.find(d => d.id_user === user.id_user)
      const distanceText = driverInfo ? ` (${driverInfo.distance_km.toFixed(1)} km)` : ''
      
      // ✅ Body berbeda untuk UMKM vs OJEK
      const notifBody = jenisPesanan === 'umkm'
        ? `${customerName} | ${jarak.toFixed(1)} km | Rp ${formattedPrice}${distanceText}`
        : `${customerName} | ${jarak.toFixed(1)} km | Rp ${formattedPrice}${distanceText}`
      
      console.log(`📤 Sending to: ${user.nama}${distanceText}`)
      
      const notifPromise = fetch(fcmUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: {
              title: notifTitle,
              body: notifBody,
            },
            data: {
              orderId: orderId,
              customerId: customerId,
              customerName: customerName,
              jenisPesanan: jenisPesanan,              // ✅ BARU
              jenisKendaraan: jenisKendaraan || '',
              lokasiJemput: lokasiJemput,
              lokasiTujuan: lokasiTujuan,
              jarak: jarak.toString(),
              ongkir: ongkir.toString(),
              type: 'new_order',
              timestamp: (timestamp || Date.now()).toString(),
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
              distance_km: driverInfo?.distance_km.toString() || '0',
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channelId: 'new_order_channel',
                tag: `new_order_${orderId}`,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                icon: '@mipmap/ic_launcher',
                color: '#FF6B9D',
                defaultSound: true,
                defaultVibrateTimings: true,
                visibility: 'public',
                ticker: `Pesanan baru ${jenisPesanan}`,
                notificationCount: 1,
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  contentAvailable: true,
                  badge: 1,
                  alert: {
                    title: notifTitle,
                    body: notifBody,
                  },
                },
              },
            },
          },
        }),
      })
      .then(async (response) => {
        const result = await response.json()
        if (response.ok) {
          successCount++
          console.log(`✅ Sent to ${user.nama}`)
          return { success: true, driver: user.nama, distance: driverInfo?.distance_km }
        } else {
          failCount++
          console.error(`❌ Failed for ${user.nama}:`, result)
          return { success: false, driver: user.nama, error: result }
        }
      })
      .catch((error) => {
        failCount++
        console.error(`❌ Error sending to ${user.nama}:`, error)
        return { success: false, driver: user.nama, error: error.message }
      })
      
      notifications.push(notifPromise)
    }
    
    // ✅ Wait for all notifications
    const results = await Promise.all(notifications)
    
    console.log(`✅ Success: ${successCount}, Failed: ${failCount}`)
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        driversNotified: successCount,
        driversFailed: failCount,
        totalDriversOnline: onlineDrivers.length,
        driversWithin10km: driversWithDistance.length,
        results: results
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    console.error('❌ Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

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