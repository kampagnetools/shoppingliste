<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-msf-navy/60 backdrop-blur-sm" @click.self="$emit('close')">
    <div class="bg-white w-full max-w-2xl border border-gray-200 overflow-hidden">
      <div class="flex items-center justify-between px-6 py-4 bg-gray-50 border-b border-gray-200">
        <div>
          <h3 class="text-lg font-bold text-msf-navy">Opret nyt produkt</h3>
          <p class="text-xs text-gray-500">Udfyld stamdata for det nye element i kataloget</p>
        </div>
        <button @click="$emit('close')" class="text-gray-400 hover:text-msf-navy transition-colors p-2">
          <X :size="20" />
        </button>
      </div>

      <form @submit.prevent="handleSubmit" class="p-6">
        <div class="grid grid-cols-6 gap-6">
          <div class="col-span-6 sm:col-span-4">
            <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Produktnavn <span class="text-red-500">*</span></label>
            <input v-model="form.name" type="text" required class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-msf-navy/20 focus:border-msf-navy outline-none transition-all" placeholder="f.eks. Tungespatel" />
          </div>

          <div class="col-span-6 sm:col-span-2">
            <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5 text-blue-600">Pris (EUR) <span class="text-red-500">*</span></label>
            <div class="relative">
              <input v-model.number="form.price_eur" type="number" step="0.01" min="0" required class="w-full pl-7 pr-3 py-2 border border-blue-200 bg-blue-50/30 rounded-md focus:ring-2 focus:ring-blue-500/20 outline-none font-semibold" placeholder="0.00" />
              <span class="absolute left-2.5 top-2.5 text-gray-500 text-sm">€</span>
            </div>
            <p v-if="form.price_eur > 0" class="mt-1 text-[10px] text-blue-600 font-medium italic">
              ≈ {{ (form.price_eur * exchangeRate).toFixed(2) }} DKK
            </p>
          </div>

          <div class="col-span-6">
            <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">UNICAT Navn</label>
            <input v-model="form.unicat_name" type="text" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-msf-navy/20 outline-none" placeholder="DEPRESSOR, TONGUE, wooden" />
          </div>

          <div class="col-span-6">
            <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-2">Temaer</label>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-2 p-3 border border-gray-100 bg-gray-50 max-h-40 overflow-y-auto">
              <label
                v-for="theme in themes"
                :key="theme.id"
                :class="[
                  'flex items-center gap-2 px-2 py-1.5 rounded border transition-all cursor-pointer text-xs',
                  form.themeIds.includes(theme.id) ? 'bg-msf-navy text-white border-msf-navy' : 'bg-white border-gray-200 text-gray-700 hover:border-msf-navy'
                ]"
              >
                <input type="checkbox" :value="theme.id" v-model="form.themeIds" class="hidden" />
                <span>{{ theme.name }}</span>
              </label>
            </div>
          </div>

          <div class="col-span-6">
            <label class="block text-xs font-bold uppercase tracking-wider text-gray-600 mb-1.5">Fundraising-beskrivelse</label>
            <textarea v-model="form.description" rows="3" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-msf-navy/20 outline-none resize-none text-sm" placeholder="Kort beskrivelse..." />
          </div>
        </div>

        <transition enter-active-class="transform transition duration-300 ease-out" enter-from-class="opacity-0 -translate-y-2" enter-to-class="opacity-100 translate-y-0">
          <div v-if="errorMsg" class="mt-4 p-3 rounded-md bg-red-50 border-l-4 border-red-500 text-xs text-red-700 flex items-center gap-2">
            <AlertCircle :size="14" /> {{ errorMsg }}
          </div>
        </transition>

        <div class="flex justify-end gap-3 mt-8 pt-6 border-t border-gray-100">
          <button type="button" @click="$emit('close')" class="px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded-md transition-colors">
            Annuller
          </button>
          <button type="submit" :disabled="saving" class="px-6 py-2 text-sm font-bold text-white bg-msf-navy hover:bg-opacity-90 rounded-md shadow-lg disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2">
            <Loader2 v-if="saving" class="animate-spin" :size="16" />
            {{ saving ? 'Behandler...' : 'Opret Produkt' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { X, Loader2, AlertCircle } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase.js'
import { useActivityLog } from '@/composables/useActivityLog.js'

const props = defineProps({
  themes:  { type: Array, default: () => [] },
  profile: { type: Object, required: true }
})
const emit = defineEmits(['close', 'created'])
const { log } = useActivityLog(props.profile)

const form = ref({ name: '', unicat_name: '', price_eur: null, description: '', price_example: '', themeIds: [] })
const saving = ref(false)
const errorMsg = ref('')
const exchangeRate = ref(7.46)

onMounted(() => {
  const cached = localStorage.getItem('msf_eur_dkk_rate')
  if (cached) exchangeRate.value = parseFloat(cached)
})

async function handleSubmit() {
  if (saving.value) return
  saving.value = true
  errorMsg.value = ''

  try {
    const { data: product, error: pErr } = await supabase
      .from('products')
      .insert({
        name:           form.value.name,
        unicat_name:    form.value.unicat_name   || null,
        price_eur:      form.value.price_eur,
        description:    form.value.description   || null,
        price_example:  form.value.price_example || null,
        last_edited_by: props.profile.id,
        version_number: 1
      })
      .select()
      .single()

    if (pErr) throw pErr

    await supabase.from('products').update({ product_family_id: product.id }).eq('id', product.id)

    if (form.value.themeIds.length > 0) {
      const { error: tErr } = await supabase.from('product_themes').insert(
        form.value.themeIds.map(tid => ({ product_id: product.id, theme_id: tid }))
      )
      if (tErr) throw tErr
    }

    log(product.id, 'product_created', `Produkt oprettet: "${product.name}"`)
    emit('created', { ...product, product_family_id: product.id })
  } catch (err) {
    errorMsg.value = err.message || 'Der skete en fejl under gemmeprocessen.'
  } finally {
    saving.value = false
  }
}
</script>
