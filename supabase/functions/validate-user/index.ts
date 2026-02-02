// Supabase Edge Function: validate-user
// Deployed via: supabase functions deploy validate-user

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0"

serve(async (req) => {
  try {
    // 1. Parse Input
    const { userId, isValid } = await req.json()
    
    if (!userId) {
      throw new Error("Missing userId")
    }

    // 2. Initialize Admin Client
    // Need SERVICE_ROLE_KEY to bypass RLS and update user status
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 3. Perform Validation Logic
    let updateData = {}
    if (isValid) {
      updateData = { 
        is_validated: true, 
        status: 'active',
        validated_at: new Date().toISOString()
      }
    } else {
      updateData = { 
        status: 'rejected',
        // Optional: Add rejection reason if provided
      }
    }

    // 4. Update Database
    const { data, error } = await supabaseAdmin
      .from('users')
      .update(updateData)
      .eq('id', userId)
      .select()
      .single()

    if (error) throw error

    // 5. Advanced Logic (Simulated)
    // - Send Welcome Email via Resend/SendGrid
    // - Send Push Notification via FCM
    // - Update Analytics
    console.log(`User ${userId} validation processed. Status: ${isValid ? 'Approved' : 'Rejected'}`)

    // Example: Trigger Notification (Simulated)
    if (isValid) {
       await supabaseAdmin.from('notifications').insert({
         user_id: userId,
         title: "Bienvenue !",
         body: "Votre compte a été validé par un administrateur."
       })
    }

    // 6. Return Success
    return new Response(
      JSON.stringify({ success: true, user: data }),
      { headers: { "Content-Type": "application/json" } },
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    )
  }
})
