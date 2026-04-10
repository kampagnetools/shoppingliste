<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm" @click.self="$emit('close')">
    <div class="bg-white w-full max-w-2xl border border-slate-200 overflow-hidden animate-in fade-in-0 zoom-in-95 duration-200 max-h-[90vh] flex flex-col">

      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-5 border-b border-slate-200 bg-gradient-to-r from-indigo-50 to-white">
        <div>
          <h3 class="text-base font-bold text-slate-900">{{ isBulkEdit ? 'Rediger Temaer' : 'Rediger Produkt' }}</h3>
          <p v-if="isBulkEdit" class="text-xs text-slate-500 mt-1">{{ props.products.length }} produkter valgt</p>
        </div>
        <button @click="$emit('close')" class="p-1.5 hover:bg-slate-100 text-slate-400 transition-colors">
          <X :size="18" />
        </button>
      </div>

      <!-- Content -->
      <div class="px-6 py-5 flex-1 overflow-y-auto space-y-5">
        <!-- Debug message -->
        <div v-if="saving" class="p-4 bg-blue-50 border border-blue-200 text-sm text-blue-700">
          <strong>Status:</strong> Gemmer... Check konsol (F12) for details
        </div>
        <!-- Produktnavn (only for single edit) -->
        <div v-if="!isBulkEdit">
          <label class="block text-sm font-semibold text-slate-700 mb-2">Produktnavn</label>
          <input
            v-model="formData.name"
            type="text"
            class="w-full px-4 py-2.5 border border-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 hover:border-slate-300 transition-colors"
          />
        </div>

        <!-- Pris (only for single edit) -->
        <div v-if="!isBulkEdit">
          <label class="block text-sm font-semibold text-slate-700 mb-2">Pris (EUR)</label>
          <input
            v-model.number="formData.price_eur"
            type="number"
            step="0.01"
            class="w-full px-4 py-2.5 border border-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 hover:border-slate-300 transition-colors"
          />
        </div>

        <!-- Beskrivelse (only for single edit) -->
        <div v-if="!isBulkEdit">
          <label class="block text-sm font-semibold text-slate-700 mb-2">Beskrivelse (Pris eksempel)</label>
          <input
            v-model="formData.price_example"
            type="text"
            placeholder="f.eks. '100 stk. til behandling'"
            class="w-full px-4 py-2.5 border border-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 hover:border-slate-300 transition-colors"
          />
        </div>

        <!-- Medie (only for single edit) -->
        <div v-if="!isBulkEdit" class="hidden">
          {{ formData.placements }}
        </div>

        <!-- Temaer -->
        <div>
          <label class="block text-sm font-semibold text-slate-700 mb-3">Temaer</label>
          <div class="space-y-2">
            <label v-for="theme in themes" :key="theme.id" class="flex items-center gap-3 p-2.5 hover:bg-slate-50 cursor-pointer transition-colors">
              <input
                type="checkbox"
                :checked="formData.themeIds.includes(theme.id)"
                @change="toggleTheme(theme.id)"
                class="w-4 h-4 cursor-pointer"
              />
              <span class="text-sm text-slate-700 font-medium">{{ theme.name }}</span>
            </label>
          </div>
        </div>

        <!-- Medie (only for single edit) - view/edit existing media only -->
        <div v-if="!isBulkEdit && formData.placements.length > 0">
          <label class="block text-sm font-semibold text-slate-700 mb-3">Medie</label>

          <!-- Existing media -->
          <div class="space-y-2">
            <div v-for="placement in formData.placements" :key="placement.id" class="flex items-center justify-between p-3 bg-slate-50 border border-slate-200">
              <div class="flex items-center gap-3">
                <span class="inline-block px-2.5 py-1 bg-indigo-100 text-indigo-700 text-xs font-semibold ">
                  {{ getMediaLabel(placement.channel) }}
                </span>
                <span v-if="placement.title" class="text-sm text-slate-700">{{ placement.title }}</span>
                <a v-if="placement.channel === 'web' && placement.url" :href="placement.url" target="_blank" class="text-xs text-indigo-600 hover:underline">
                  {{ getUrlHostname(placement.url) }}
                </a>
              </div>
              <button @click="removeMedia(placement.id)" class="p-1.5 hover:bg-red-100 text-red-600 transition-colors">
                <X :size="16" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="px-6 py-4 bg-white border-t border-slate-200 flex gap-3 justify-end">
        <button
          @click="$emit('close')"
          class="px-4 py-2.5 border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors text-sm font-semibold"
        >
          Annuller
        </button>
        <button
          @click="saveProduct()"
          :disabled="saving"
          class="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:from-slate-400 disabled:to-slate-400 text-white transition-all text-sm font-semibold"
        >
          <span v-if="saving">Gemmer...</span>
          <span v-else>Gem ændringer</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { X } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase.js'

const props = defineProps({
  products: { type: Array, required: true },
  themes: { type: Array, default: () => [] }
})

const isBulkEdit = computed(() => props.products.length > 1)

const emit = defineEmits(['close', 'updated'])

const primaryProduct = computed(() => props.products[0])

const formData = ref({
  name: '',
  price_eur: 0,
  price_example: '',
  themeIds: [],
  placements: []
})

// Update formData when primaryProduct changes
const updateFormData = () => {
  const product = primaryProduct.value
  if (product) {
    formData.value = {
      name: product.name || '',
      price_eur: product.price_eur || 0,
      price_example: product.price_example || '',
      themeIds: product.themes?.map(t => t.id) ?? [],
      placements: product.placements ?? []
    }
  }
}

// Call updateFormData when component receives props
updateFormData()

const newMedia = ref({ channel: '', url: '', title: '' })
const showAddMediaForm = ref(false)
const saving = ref(false)

function toggleTheme(themeId) {
  const idx = formData.value.themeIds.indexOf(themeId)
  if (idx > -1) {
    formData.value.themeIds.splice(idx, 1)
  } else {
    formData.value.themeIds.push(themeId)
  }
}

function addMedia() {
  if (!newMedia.value.channel) return
  formData.value.placements.push({
    id: 'new-' + Date.now(),
    product_id: primaryProduct.value.id,
    channel: newMedia.value.channel,
    title: newMedia.value.title,
    url: newMedia.value.url,
    created_at: new Date().toISOString()
  })
  newMedia.value = { channel: '', url: '', title: '' }
  showAddMediaForm.value = false
}

function removeMedia(placementId) {
  formData.value.placements = formData.value.placements.filter(p => p.id !== placementId)
}

function getMediaLabel(channel) {
  const labels = { 'paid': 'Paid', 'web': 'Web', 'email': 'E-mail', 'some': 'SoMe' }
  return labels[channel] || channel
}

function getUrlHostname(url) {
  try {
    return new URL(url).hostname
  } catch {
    return url
  }
}

async function saveProduct() {
  saving.value = true
  try {
    if (isBulkEdit.value) {
      // Bulk edit: update themes for all selected products
      for (const product of props.products) {
        const { error: deleteThemeError } = await supabase
          .from('product_themes')
          .delete()
          .eq('product_id', product.id)

        if (deleteThemeError) throw deleteThemeError

        if (formData.value.themeIds.length > 0) {
          const { error: insertThemeError } = await supabase
            .from('product_themes')
            .insert(formData.value.themeIds.map(tid => ({ product_id: product.id, theme_id: tid })))

          if (insertThemeError) throw insertThemeError
        }

        // Update last_edited_at
        const { error: updateError } = await supabase
          .from('products')
          .update({
            last_edited_at: new Date().toISOString(),
            last_edited_by: product.last_edited_by
          })
          .eq('id', product.id)

        if (updateError) throw updateError
      }
    } else {
      // Single edit: update product details
      const product = primaryProduct.value
      const { error: updateError } = await supabase
        .from('products')
        .update({
          name: formData.value.name,
          price_eur: formData.value.price_eur,
          price_example: formData.value.price_example,
          last_edited_at: new Date().toISOString(),
          last_edited_by: product.last_edited_by
        })
        .eq('id', product.id)

      if (updateError) {
        throw updateError
      }

      // Update themes
      const { error: deleteThemeError } = await supabase
        .from('product_themes')
        .delete()
        .eq('product_id', product.id)

      if (deleteThemeError) {
        throw deleteThemeError
      }

      if (formData.value.themeIds.length > 0) {
        const { error: insertThemeError } = await supabase
          .from('product_themes')
          .insert(formData.value.themeIds.map(tid => ({ product_id: product.id, theme_id: tid })))

        if (insertThemeError) {
          throw insertThemeError
        }
      }

      // Handle placements (new vs existing)
      const newPlacements = formData.value.placements.filter(p => p.id.toString().startsWith('new-'))
      const existingPlacements = formData.value.placements.filter(p => !p.id.toString().startsWith('new-'))
      const deletedIds = (product.placements ?? [])
        .map(p => p.id)
        .filter(id => !existingPlacements.find(p => p.id === id))


      if (deletedIds.length > 0) {
        const { error: deleteError } = await supabase
          .from('placements')
          .delete()
          .in('id', deletedIds)
        if (deleteError) {
          throw deleteError
        }
      }

      if (newPlacements.length > 0) {
        const { error: insertError } = await supabase
          .from('placements')
          .insert(newPlacements.map(p => ({
            product_id: p.product_id,
            channel: p.channel,
            title: p.title,
            url: p.url
          })))
        if (insertError) {
          throw insertError
        }
      }
    }

    emit('updated')
  } catch (err) {
    alert('Fejl ved gemning: ' + err?.message)
  } finally {
    saving.value = false
  }
}
</script>
