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
      throw new Error('Only super_admin can delete admin')
    }

    // Parse request
    const { id_admin } = await req.json()

    if (!id_admin) {
      throw new Error('Missing id_admin')
    }

    console.log('Deleting admin:', id_admin)

    // Soft delete: set is_active = false
    const { error: updateError } = await supabaseAdmin
      .from('admins')
      .update({
        is_active: false,
        updated_at: new Date().toISOString(),
      })
      .eq('id_admin', id_admin)

    if (updateError) {
      throw new Error(`Failed to delete admin: ${updateError.message}`)
    }

    console.log('Admin deleted successfully!')

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Admin deleted successfully'
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