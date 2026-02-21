// Supabase Edge Function: stripe-webhook
// Handles Stripe webhook events to keep profiles.is_premium in sync.
//
// Required Supabase Secrets:
//   STRIPE_SECRET_KEY
//   STRIPE_WEBHOOK_SECRET   – whsec_… (from Stripe Dashboard → Webhooks)
//   SUPABASE_SERVICE_ROLE_KEY is auto-injected

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

// ── Helper: resolve Supabase user from Stripe customer or subscription ───────
async function getUserIdFromCustomer(customerId: string): Promise<string | null> {
  const { data } = await adminClient
    .from('profiles')
    .select('id')
    .eq('stripe_customer_id', customerId)
    .single()
  return data?.id ?? null
}

async function setPremium(userId: string, isPremium: boolean, expiresAt?: Date) {
  await adminClient
    .from('profiles')
    .update({
      is_premium: isPremium,
      premium_expires_at: expiresAt?.toISOString() ?? null,
    })
    .eq('id', userId)
}

// ── Handler ──────────────────────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
  if (!webhookSecret) {
    return new Response('Webhook secret not configured', { status: 500 })
  }

  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return new Response('Missing stripe-signature header', { status: 400 })
  }

  const body = await req.text()
  let event: Stripe.Event

  try {
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret)
  } catch (err) {
    console.error('Webhook signature verification failed:', err)
    return new Response(`Webhook Error: ${String(err)}`, { status: 400 })
  }

  console.log(`Processing Stripe event: ${event.type}`)

  try {
    switch (event.type) {
      // ── Checkout completed → user paid ──────────────────────────────────────
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        if (session.mode !== 'subscription') break

        const customerId = session.customer as string
        const userId = await getUserIdFromCustomer(customerId)
        if (!userId) {
          console.error('No user found for customer:', customerId)
          break
        }

        // Retrieve the subscription to get the current period end
        const subscriptionId = session.subscription as string
        const subscription = await stripe.subscriptions.retrieve(subscriptionId)
        const expiresAt = new Date((subscription.current_period_end ?? 0) * 1000)

        await setPremium(userId, true, expiresAt)
        console.log(`Activated premium for user ${userId}`)
        break
      }

      // ── Subscription renewed ────────────────────────────────────────────────
      case 'invoice.paid': {
        const invoice = event.data.object as Stripe.Invoice
        if (!invoice.subscription) break

        const customerId = invoice.customer as string
        const userId = await getUserIdFromCustomer(customerId)
        if (!userId) break

        const subscription = await stripe.subscriptions.retrieve(invoice.subscription as string)
        const expiry = new Date((subscription.current_period_end ?? 0) * 1000)
        await setPremium(userId, true, expiry)
        console.log(`Renewed premium for user ${userId}`)
        break
      }

      // ── Subscription cancelled or expired ───────────────────────────────────
      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription
        const customerId = subscription.customer as string
        const userId = await getUserIdFromCustomer(customerId)
        if (!userId) break

        await setPremium(userId, false)
        console.log(`Deactivated premium for user ${userId}`)
        break
      }

      // ── Subscription status changed (paused, unpaid, etc.) ──────────────────
      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription
        const customerId = subscription.customer as string
        const userId = await getUserIdFromCustomer(customerId)
        if (!userId) break

        const active = ['active', 'trialing'].includes(subscription.status)
        if (active) {
          const expiresAt = new Date((subscription.current_period_end ?? 0) * 1000)
          await setPremium(userId, true, expiresAt)
        } else {
          await setPremium(userId, false)
        }
        console.log(`Updated premium status for user ${userId} → ${subscription.status}`)
        break
      }

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Error handling webhook event:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
