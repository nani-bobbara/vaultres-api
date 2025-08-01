import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the current user
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      throw new Error('User not authenticated')
    }

    if (req.method === 'POST') {
      // Handle avatar upload
      const formData = await req.formData()
      const file = formData.get('avatar') as File

      if (!file) {
        throw new Error('No file provided')
      }

      // Upload to storage
      const fileExt = file.name.split('.').pop()
      const fileName = `${user.id}.${fileExt}`
      
      const { data: uploadData, error: uploadError } = await supabaseClient.storage
        .from('avatars')
        .upload(fileName, file, {
          upsert: true
        })

      if (uploadError) {
        throw uploadError
      }

      // Get public URL
      const { data } = supabaseClient.storage
        .from('avatars')
        .getPublicUrl(fileName)

      // Update user profile
      const { error: updateError } = await supabaseClient
        .from('user_profiles')
        .update({ avatar_url: data.publicUrl })
        .eq('user_id', user.id)

      if (updateError) {
        throw updateError
      }

      return new Response(
        JSON.stringify({ 
          message: 'Avatar updated successfully',
          avatar_url: data.publicUrl 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // GET request - return current avatar
    const { data: profile } = await supabaseClient
      .from('user_profiles')
      .select('avatar_url')
      .eq('user_id', user.id)
      .single()

    return new Response(
      JSON.stringify({ avatar_url: profile?.avatar_url || null }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
