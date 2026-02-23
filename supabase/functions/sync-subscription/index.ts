// Supabase Edge Function: sync-subscription
// Called by the app to pull the user's current Stripe subscription status
// directly from Stripe and write it to profiles.
//
// This is the reliable fallback for when the webhook hasn't fired yet.

import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  httpClient: Stripe.createFetchHttpClient(),
  apiVersion: '2024-04-10',
})

const adminClient = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // ── Authenticate caller ───────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Extract the JWT from "Bearer <token>"
    const jwt = authHeader.replace(/^Bearer\s+/i, '')

    // Use the admin client to verify the JWT — this is the correct pattern
    // for Supabase Edge Functions (avoids "Invalid JWT" from user-context client)
    const { data: { user }, error: authError } = await adminClient.auth.getUser(jwt)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized', detail: authError?.message }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── Get profile to find stripe_customer_id ────────────────────────────
    const { data: profile } = await adminClient
      .from('profiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single()

    let customerId: string | null = profile?.stripe_customer_id ?? null

    // ── If no customer ID saved, search Stripe by email ───────────────────
    if (!customerId && user.email) {
      const customers = await stripe.customers.list({ email: user.email, limit: 5 })
      if (customers.data.length > 0) {
        // Take the most recently created customer
        customerId = customers.data[0].id

        // Save it for future webhook lookups
        await adminClient
          .from('profiles')
          .update({ stripe_customer_id: customerId })
          .eq('id', user.id)
      }
    }

    if (!customerId) {
      // No Stripe customer at all → user is free
      return new Response(
        JSON.stringify({ isPremium: false, status: null }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Fetch all subscriptions for this customer ─────────────────────────
    const subscriptions = await stripe.subscriptions.list({
      customer: customerId,
      limit: 10,
      expand: ['data.default_payment_method'],
    })

    // Find the best (most active) subscription
    // Priority: active > trialing > past_due > others
    const priority = ['active', 'trialing', 'past_due', 'incomplete']
    const sorted = subscriptions.data.sort((a, b) => {
      return priority.indexOf(a.status) - priority.indexOf(b.status)
    })

    const best = sorted[0]

    if (!best) {
      // Has a customer but no subscriptions
      await adminClient
        .from('profiles')
        .update({ is_premium: false, subscription_status: null, premium_expires_at: null })
        .eq('id', user.id)

      return new Response(
        JSON.stringify({ isPremium: false, status: null }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const activeStatuses = ['active', 'trialing']
    const isPremium = activeStatuses.includes(best.status)
    const expiresAt = new Date((best.current_period_end ?? 0) * 1000).toISOString()

    // ── Update profiles table ─────────────────────────────────────────────
    const update: Record<string, unknown> = {
      is_premium: isPremium,
      premium_expires_at: isPremium ? expiresAt : null,
    }

    // Write subscription_status if column exists (migration 20260224000001)
    try {
      await adminClient
        .from('profiles')
        .update({ ...update, subscription_status: best.status })
        .eq('id', user.id)
    } catch (_) {
      // Column not yet migrated — write without it
      await adminClient.from('profiles').update(update).eq('id', user.id)
    }

    console.log(`Synced subscription for user ${user.id}: ${best.status} → isPremium=${isPremium}`)

    return new Response(
      JSON.stringify({
        isPremium,
        status: best.status,
        expiresAt: isPremium ? expiresAt : null,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    console.error('sync-subscription error:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
