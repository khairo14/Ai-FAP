// Supabase Edge Function: create-checkout-session
// Creates a Stripe Checkout Session for web / desktop users.
//
// Required Supabase Secrets (set via: supabase secrets set KEY=value):
//   STRIPE_SECRET_KEY       – sk_test_… or sk_live_…
//   SUPABASE_SERVICE_ROLE_KEY is auto-injected by Supabase

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
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // ── Authenticate caller ───────────────────────────────────────────────────
    const jwt = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '')
    if (!jwt) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: { user }, error: authError } = await adminClient.auth.getUser(jwt)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── Parse request body ───────────────────────────────────────────────────
    const { priceId, planType, successUrl, cancelUrl } = await req.json() as {
      priceId: string
      planType?: string   // 'monthly' | 'annual'
      successUrl: string
      cancelUrl: string
    }

    if (!priceId || !successUrl || !cancelUrl) {
      return new Response(
        JSON.stringify({ error: 'priceId, successUrl, cancelUrl are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // ── Get or create Stripe Customer ────────────────────────────────────────
    const { data: profile } = await adminClient
      .from('profiles')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single()

    let customerId: string = profile?.stripe_customer_id ?? ''

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: { supabase_user_id: user.id },
      })
      customerId = customer.id

      await adminClient
        .from('profiles')
        .update({ stripe_customer_id: customerId })
        .eq('id', user.id)
    }

    // ── Determine trial eligibility ──────────────────────────────────────────
    // Only give a free trial on the MONTHLY plan (price_xxx_monthly).
    // Annual subscribers pay immediately and get full access from day 1.
    // Trial is also skipped if the customer already had a trial/subscription before.
    const existingSubscriptions = await stripe.subscriptions.list({
      customer: customerId,
      limit: 10,
    })
    const hadTrialBefore = existingSubscriptions.data.some(
      (s) => s.status !== 'canceled' || s.trial_start != null,
    )

    // Trial only on monthly plan and only if the customer hasn't had one before.
    // Annual subscribers pay immediately and get full Pro from day 1.
    const isMonthly = planType === 'monthly' || planType == null  // default monthly if not specified
    const grantTrial = isMonthly && !hadTrialBefore

    // ── Create Checkout Session ──────────────────────────────────────────────
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      allow_promotion_codes: true,
      subscription_data: {
        ...(grantTrial ? { trial_period_days: 14 } : {}),
        metadata: { supabase_user_id: user.id },
      },
      metadata: { supabase_user_id: user.id },
    })

    return new Response(JSON.stringify({ url: session.url }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('create-checkout-session error:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
