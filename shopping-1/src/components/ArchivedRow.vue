<template>
  <tr class="group border-b border-gray-100 last:border-0 hover:bg-amber-50/30 transition-colors">
    <td class="pl-6 pr-4 py-4">
      <span class="text-sm font-semibold text-gray-500">{{ product.name }}</span>
      <div v-if="product.unicat_name" class="text-xs text-gray-400 mt-0.5">{{ product.unicat_name }}</div>
    </td>

    <td class="px-4 py-4 whitespace-nowrap">
      <div class="flex items-center gap-1">
        <span
          v-for="theme in (product.themes ?? []).slice(0, 2)" :key="theme.id"
          class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-gray-100 text-gray-400"
        >{{ theme.name }}</span>
        <span v-if="(product.themes?.length ?? 0) > 2"
          class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-400">
          +{{ product.themes.length - 2 }}
        </span>
        <span v-if="!product.themes?.length" class="text-sm text-gray-300">–</span>
      </div>
    </td>

    <td class="px-4 py-4 whitespace-nowrap">
      <span class="text-sm tabular-nums text-gray-400">{{ eurToDkk(product.price_eur) }}</span>
    </td>

    <td class="px-4 py-4 whitespace-nowrap">
      <div class="flex flex-col gap-0.5">
        <span class="text-sm tabular-nums text-gray-600">{{ fmt(product.archived_at) }}</span>
        <span class="text-xs text-gray-400">{{ archivedByName }}</span>
      </div>
    </td>

    <td class="pl-4 pr-6 py-4 text-right whitespace-nowrap">
      <div class="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
        <button
          @click="reactivate"
          :disabled="working"
          class="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-medium text-emerald-700 bg-emerald-50 hover:bg-emerald-100 transition-colors active:scale-95"
        >
          <RotateCcw :size="13" /> Genaktivér
        </button>
        <button
          @click="duplicate"
          :disabled="working"
          class="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 transition-colors active:scale-95"
        >
          <Copy :size="13" /> Dubler
        </button>
      </div>
    </td>
  </tr>
</template>

<script setup>
import { ref, computed } from 'vue'
import { RotateCcw, Copy } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase.js'
import { useCurrency } from '@/composables/useCurrency.js'
import { useActivityLog } from '@/composables/useActivityLog.js'

const props = defineProps({
  product:   { type: Object, required: true },
  allThemes: { type: Array,  default: () => [] },
  profile:   { type: Object, required: true }
})
const emit = defineEmits(['reactivated', 'duplicated'])

const { eurToDkk } = useCurrency()
const { log } = useActivityLog(props.profile)
const working = ref(false)

const archivedByName = computed(() =>
  props.product.archiver?.full_name || props.product.archiver?.email || 'Ukendt'
)

function fmt(iso) {
  if (!iso) return '–'
  return new Date(iso).toLocaleString('da-DK', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  })
}

const PRODUCT_SELECT = `*, themes:product_themes(theme:themes(*)), placements(*), editor:profiles!last_edited_by(full_name, email)`

function normalize(data) {
  return { ...data, themes: (data.themes ?? []).map(t => t.theme), placements: data.placements ?? [] }
}

async function reactivate() {
  working.value = true
  const { error } = await supabase.from('products')
    .update({ is_archived: false, archived_at: null, archived_by: null, last_edited_by: props.profile.id, last_edited_at: new Date().toISOString() })
    .eq('id', props.product.id)

  if (error) { alert('Fejl: ' + error.message); working.value = false; return }

  const { data, error: fetchErr } = await supabase.from('products')
    .select(PRODUCT_SELECT)
    .eq('id', props.product.id)
    .single()

  if (fetchErr) { alert('Fejl: ' + fetchErr.message); working.value = false; return }

  log(props.product.id, 'product_updated', 'Produkt genaktiveret fra arkiv')
  emit('reactivated', normalize(data))
  working.value = false
}

async function duplicate() {
  working.value = true
  const { data: newProduct, error } = await supabase.from('products')
    .insert({
      name:              props.product.name + ' (kopi)',
      unicat_name:       props.product.unicat_name,
      description:       props.product.description,
      price_example:     props.product.price_example,
      price_eur:         props.product.price_eur,
      is_archived:       false,
      version_number:    1,
      last_edited_by:    props.profile.id,
      last_edited_at:    new Date().toISOString()
    })
    .select()
    .single()

  if (error) { alert('Fejl: ' + error.message); working.value = false; return }

  await supabase.from('products').update({ product_family_id: newProduct.id }).eq('id', newProduct.id)

  const themeIds = (props.product.themes ?? []).map(t => t.id)
  if (themeIds.length) {
    await supabase.from('product_themes').insert(themeIds.map(tid => ({ product_id: newProduct.id, theme_id: tid })))
  }

  log(newProduct.id, 'product_created', `Dubleret fra arkiveret produkt "${props.product.name}"`)
  emit('duplicated', { ...newProduct, product_family_id: newProduct.id, themes: props.allThemes.filter(t => themeIds.includes(t.id)), placements: [] })
  working.value = false
}
</script>
