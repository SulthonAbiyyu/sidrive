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

    // Cek authorization
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Cek super_admin
    const { data: adminData, error: adminError } = await supabaseAdmin
      .from('admins')
      .select('level')
      .eq('id_user', user.id)
      .single()

    if (adminError || !adminData || adminData.level !== 'super_admin') {
      throw new Error('Only super_admin can update admin')
    }

    // Parse request
    const { id_admin, nama, level, is_active, new_password } = await req.json()

    if (!id_admin || !nama || !level || is_active === undefined) {
      throw new Error('Missing required fields')
    }

    console.log('Updating admin:', id_admin)

    // Get admin data untuk ambil id_user
    const { data: targetAdmin, error: getError } = await supabaseAdmin
      .from('admins')
      .select('id_user')
      .eq('id_admin', id_admin)
      .single()

    if (getError || !targetAdmin) {
      throw new Error('Admin not found')
    }

    // STEP 1: Update admin record
    const updateData: any = {
      nama: nama,
      level: level,
      is_active: is_active,
      updated_at: new Date().toISOString(),
    }

    if (new_password && new_password.length >= 6) {
      updateData.password_hash = new_password
    }

    const { error: updateError } = await supabaseAdmin
      .from('admins')
      .update(updateData)
      .eq('id_admin', id_admin)

    if (updateError) {
      throw new Error(`Failed to update admin: ${updateError.message}`)
    }

    // STEP 2: Update password di Auth (jika ada)
    if (new_password && new_password.length >= 6) {
      console.log('Updating auth password...')
      const { error: authUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
        targetAdmin.id_user,
        { password: new_password }
      )

      if (authUpdateError) {
        console.error('Failed to update auth password:', authUpdateError)
        // Don't throw, admin record sudah terupdate
      }
    }

    console.log('Admin updated successfully!')

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Admin updated successfully'
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