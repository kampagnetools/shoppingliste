import { supabase } from '@/lib/supabase.js'

export function useActivityLog(profile) {
  async function log(productId, action, description) {
    await supabase.from('activity_log').insert({
      product_id:  productId,
      action,
      description,
      user_id:     profile?.id   ?? null,
      user_name:   profile?.full_name || profile?.email || 'Ukendt'
    })
  }

  async function fetchLog(productId) {
    const { data } = await supabase
      .from('activity_log')
      .select('*')
      .eq('product_id', productId)
      .order('created_at', { ascending: false })
      .limit(30)
    return data ?? []
  }

  return { log, fetchLog }
}
