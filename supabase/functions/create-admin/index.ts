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
    // Get service role client (punya akses admin)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get user dari token
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Cek apakah user adalah super_admin
    const { data: adminData, error: adminError } = await supabaseAdmin
      .from('admins')
      .select('level')
      .eq('id_user', user.id)
      .single()

    if (adminError || !adminData || adminData.level !== 'super_admin') {
      throw new Error('Only super_admin can create new admin')
    }

    // Parse request body
    const { email, password, username, nama, level } = await req.json()

    // Validasi input
    if (!email || !password || !username || !nama || !level) {
      throw new Error('Missing required fields')
    }

    if (password.length < 6) {
      throw new Error('Password must be at least 6 characters')
    }

    if (!['admin', 'super_admin'].includes(level)) {
      throw new Error('Invalid level')
    }

    console.log('Creating auth user...')
    console.log('Email:', email)
    console.log('Username:', username)

    // STEP 1: Create user di Supabase Auth
    const { data: authUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
      user_metadata: {
        username: username,
        nama: nama,
      }
    })

    if (authError) {
      console.error('Auth error:', authError)
      throw new Error(`Failed to create auth user: ${authError.message}`)
    }

    if (!authUser.user) {
      throw new Error('Failed to create auth user: No user returned')
    }

    console.log('Auth user created:', authUser.user.id)

    // STEP 2: Insert ke tabel admins
    const { error: insertError } = await supabaseAdmin
      .from('admins')
      .insert({
        id_user: authUser.user.id,
        username: username,
        password_hash: password, // Simpan untuk referensi
        nama: nama,
        email: email,
        level: level,
        is_active: true,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })

    if (insertError) {
      console.error('Insert error:', insertError)
      
      // Rollback: hapus auth user kalau insert gagal
      await supabaseAdmin.auth.admin.deleteUser(authUser.user.id)
      
      throw new Error(`Failed to insert admin record: ${insertError.message}`)
    }

    console.log('Admin created successfully!')

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Admin created successfully',
        data: {
          id_user: authUser.user.id,
          username: username,
          email: email,
          nama: nama,
          level: level,
        }
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})