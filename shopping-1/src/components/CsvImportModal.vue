<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm" @click.self="$emit('close')">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-2xl border border-slate-200 overflow-hidden max-h-[90vh] flex flex-col animate-in fade-in-0 zoom-in-95 duration-200">

      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-5 border-b border-slate-200 bg-gradient-to-r from-indigo-50 to-white">
        <h3 class="text-base font-bold text-slate-900">Importer CSV</h3>
        <button @click="$emit('close')" class="p-1.5 rounded-lg hover:bg-slate-100 text-slate-400 transition-colors">
          <X :size="18" />
        </button>
      </div>

      <div class="px-6 py-5 flex-1 overflow-y-auto space-y-4">
        <!-- Step 1: File upload -->
        <div v-if="!parsed">
          <label class="block mb-3 text-sm font-semibold text-slate-700">Vælg CSV-fil</label>
          <input
            type="file"
            accept=".csv"
            @change="onFileSelect"
            class="w-full px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 hover:border-slate-300 transition-colors file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-indigo-600 file:text-white file:font-semibold file:cursor-pointer hover:file:bg-indigo-700"
          />
          <p class="text-xs text-slate-500 mt-3 font-medium">Format: Tema;Pris;Beskrivelse (semikolon-adskilt)</p>
        </div>

        <!-- Step 2: Preview table -->
        <div v-else>
          <div class="flex items-center justify-between mb-4">
            <h4 class="text-sm font-semibold text-slate-700">Forhåndsvisning ({{ rows.length }} rækker)</h4>
            <button
              @click="resetFile"
              class="text-xs px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors font-medium"
            >
              Skift fil
            </button>
          </div>

          <!-- Warnings -->
          <div v-if="unmatchedThemes.size > 0" class="mb-4 rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
            <strong class="font-semibold">⚠️ Advarsel:</strong> {{ unmatchedThemes.size }} tema(er) blev ikke fundet
            <span class="block mt-2 font-mono text-xs text-amber-700">{{ Array.from(unmatchedThemes).join(', ') }}</span>
          </div>

          <div v-if="errorMsg" class="mb-4 rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700 font-medium">
            {{ errorMsg }}
          </div>

          <!-- Preview table (scrollable) -->
          <div class="border border-slate-200 rounded-xl overflow-hidden bg-slate-50">
            <table class="w-full text-sm">
              <thead class="bg-gradient-to-r from-slate-100 to-slate-50 border-b border-slate-200">
                <tr>
                  <th class="px-4 py-3 text-left font-bold text-slate-700 w-24">Tema</th>
                  <th class="px-4 py-3 text-left font-bold text-slate-700 w-24">Pris</th>
                  <th class="px-4 py-3 text-left font-bold text-slate-700 flex-1">Beskrivelse</th>
                </tr>
              </thead>
              <tbody class="max-h-[300px] overflow-y-auto block w-full">
                <tr v-for="(row, idx) in rows" :key="idx" class="border-b border-slate-200 hover:bg-indigo-50 transition-colors block w-full grid" style="grid-template-columns: 96px 96px 1fr;">
                  <td class="px-4 py-3 text-slate-900">
                    <span v-if="row.themeId" class="inline-block bg-indigo-100 text-indigo-700 px-2.5 py-0.5 rounded-full text-xs font-semibold">
                      {{ row.themeName }}
                    </span>
                    <span v-else class="inline-block bg-amber-100 text-amber-700 px-2.5 py-0.5 rounded-full text-xs font-semibold">
                      — ukendt
                    </span>
                  </td>
                  <td class="px-4 py-3 text-slate-700 font-mono text-xs">{{ row.priceExample }}</td>
                  <td class="px-4 py-3 text-slate-700 truncate text-xs">{{ row.description }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="px-6 py-4 bg-gradient-to-r from-slate-50 to-white border-t border-slate-200 flex gap-3 justify-end">
        <button
          @click="$emit('close')"
          class="px-4 py-2.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors text-sm font-semibold"
        >
          Annuller
        </button>
        <button
          v-if="parsed && rows.length > 0"
          @click="doImport"
          :disabled="importing"
          class="px-4 py-2.5 rounded-lg bg-gradient-to-r from-indigo-600 to-indigo-700 hover:from-indigo-700 hover:to-indigo-800 disabled:from-slate-400 disabled:to-slate-400 text-white transition-all text-sm font-semibold shadow-md active:scale-95"
        >
          <span v-if="importing">Importerer...</span>
          <span v-else>Importer {{ rows.length }} produkter</span>
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
  themes: { type: Array, default: () => [] },
  dkkRate: { type: Number, default: 7.46 },
  profile: { type: Object, default: () => ({}) }
})

const emit = defineEmits(['close', 'imported'])

const parsed = ref(false)
const rows = ref([])
const importing = ref(false)
const errorMsg = ref('')

const unmatchedThemes = computed(() => {
  const unmatched = new Set()
  rows.value.forEach(row => {
    if (!row.themeId) unmatched.add(row.themeName)
  })
  return unmatched
})

function onFileSelect(event) {
  const file = event.target.files[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      let text = e.target.result

      // Strip UTF-8 BOM
      if (text.charCodeAt(0) === 0xFEFF) {
        text = text.slice(1)
      }

      // Parse CSV: split by newline, then by semicolon
      const lines = text.split('\n').filter(line => line.trim().length > 0)
      const parsed_rows = []

      for (const line of lines) {
        const parts = line.split(';').map(p => p.trim())
        if (parts.length < 3) continue

        const themeName = parts[0]
        const priceRaw = parts[1]
        const description = parts[2]

        // Match theme by name (case-insensitive)
        const theme = props.themes.find(t => t.name.toLowerCase() === themeName.toLowerCase())
        const themeId = theme?.id || null

        // Parse price: strip "kr.", "pr. dag", etc., convert DKK to EUR
        const priceEur = parseDanishPrice(priceRaw)

        parsed_rows.push({
          themeName,
          themeId,
          priceExample: priceRaw,
          priceEur,
          description
        })
      }

      rows.value = parsed_rows
      parsed.value = true
      errorMsg.value = ''
    } catch (err) {
      errorMsg.value = 'Fejl ved parsing af fil: ' + err.message
    }
  }
  reader.readAsText(file)
}

function parseDanishPrice(priceStr) {
  // Remove non-numeric chars except . and ,
  let cleaned = priceStr.replace(/[^\d.,]/g, '')

  // Danish format: . is thousands sep, , is decimal
  // Convert to: . for decimal only
  cleaned = cleaned.replace(/\./g, '') // remove thousands separator
  cleaned = cleaned.replace(',', '.') // convert , to .

  const dkkValue = parseFloat(cleaned) || 0
  return dkkValue / props.dkkRate // convert to EUR
}

function resetFile() {
  parsed.value = false
  rows.value = []
  errorMsg.value = ''
}

async function doImport() {
  importing.value = true
  errorMsg.value = ''

  try {
    // Prepare product inserts
    const productsToInsert = rows.value.map(row => ({
      name: row.description,
      price_eur: row.priceEur,
      price_example: row.priceExample,
      last_edited_by: props.profile.id,
      last_edited_at: new Date().toISOString(),
      created_at: new Date().toISOString()
    }))

    // Batch insert products
    const { data: createdProducts, error: insertError } = await supabase
      .from('products')
      .insert(productsToInsert)
      .select('id, name, price_eur')

    if (insertError) throw new Error('Produkter kunne ikke indsættes: ' + insertError.message)

    // Link themes to products
    let themeLinksCreated = 0
    for (let i = 0; i < rows.value.length; i++) {
      const row = rows.value[i]
      if (!row.themeId || !createdProducts[i]) continue

      const { error: linkError } = await supabase
        .from('product_themes')
        .insert({
          product_id: createdProducts[i].id,
          theme_id: row.themeId
        })

      if (!linkError) themeLinksCreated++
    }

    // Log activity
    if (props.profile.id) {
      await supabase.from('activity_log').insert({
        product_id: null, // bulk import
        action: 'csv_import',
        description: `Importerede ${createdProducts.length} produkter (${themeLinksCreated} med tema)`,
        user_id: props.profile.id,
        user_name: props.profile.full_name || props.profile.email,
        created_at: new Date().toISOString()
      }).catch(() => {}) // ignore log errors
    }

    emit('imported', createdProducts)
    resetFile()
  } catch (err) {
    errorMsg.value = err.message
  } finally {
    importing.value = false
  }
}
</script>
