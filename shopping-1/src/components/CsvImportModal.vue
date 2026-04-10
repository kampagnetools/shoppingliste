<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm" @click.self="$emit('close')">
    <div class="bg-white w-full max-w-2xl border border-slate-200 overflow-hidden max-h-[90vh] flex flex-col animate-in fade-in-0 zoom-in-95 duration-200">

      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-5 border-b border-slate-200 bg-white">
        <h3 class="text-base font-bold text-slate-900">Importer CSV</h3>
        <button @click="$emit('close')" class="p-1.5 hover:bg-slate-100 text-slate-400 transition-colors">
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
            class="w-full px-4 py-3 border border-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 hover:border-slate-300 transition-colors file:mr-4 file:py-2 file:px-4 file:border-0 file:bg-indigo-600 file:text-white file:font-semibold file:cursor-pointer hover:file:bg-indigo-700"
          />
          <p class="text-xs text-slate-500 mt-3 font-medium">Format: Tema;Pris;Beskrivelse (semikolon-adskilt)</p>
        </div>

        <!-- Step 2: Preview table -->
        <div v-else>
          <h4 class="text-sm font-semibold text-slate-700 mb-4">Forhåndsvisning ({{ rows.length }} rækker)</h4>

          <!-- Warning if columns missing -->
          <div v-if="rows.some(r => r.hasMissingColumns)" class="mb-4 bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
            <strong>⚠️ Advarsel:</strong> {{ rows.filter(r => r.hasMissingColumns).length }} rækker mangler kolonne(r). De importeres med tomme værdier.
          </div>


          <div v-if="errorMsg" class="mb-4 bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700 font-medium">
            {{ errorMsg }}
          </div>

          <!-- Preview table (scrollable) -->
          <div class="border border-slate-200 bg-slate-50">
            <!-- Header - fixed -->
            <div class="bg-slate-100 border-b border-slate-200 grid px-4 py-3 sticky top-0" style="grid-template-columns: 1fr 60px; gap: 12px;">
              <div class="text-xs font-bold text-slate-700">Produkt</div>
              <div class="text-xs font-bold text-slate-700 text-right">Pris</div>
            </div>
            <!-- Rows - scrollable -->
            <div class="max-h-[300px] overflow-y-auto">
              <div v-for="(row, idx) in rows" :key="idx" class="grid px-4 py-3 border-b border-slate-200 transition-colors" :class="row.hasMissingColumns ? 'bg-amber-50 hover:bg-amber-100' : 'hover:bg-slate-100'" style="grid-template-columns: 1fr 60px; gap: 12px; align-items: center;">
                <div class="text-xs truncate font-medium" :class="row.hasMissingColumns ? 'text-amber-700' : 'text-slate-700'">{{ row.description || '—' }}</div>
                <div class="text-xs font-mono text-right" :class="row.hasMissingColumns ? 'text-amber-700' : 'text-slate-700'">{{ row.priceExample || '—' }}</div>
              </div>
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
          v-if="parsed && rows.length > 0"
          @click="doImport"
          :disabled="importing"
          class="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-400 text-white transition-all text-sm font-semibold"
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
  dkkRate: { type: Number, default: 7.46 },
  profile: { type: Object, default: () => ({}) }
})

const emit = defineEmits(['close', 'imported'])

const parsed = ref(false)
const rows = ref([])
const importing = ref(false)
const errorMsg = ref('')


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
        if (parts.length < 1) continue

        let tema = parts[0]

        // Remove BOM if present
        if (tema.charCodeAt(0) === 0xFEFF) {
          tema = tema.slice(1)
        }

        const priceRaw = parts[1] || ''
        const description = parts[2] || ''

        // Parse price: strip "kr.", "pr. dag", etc., convert DKK to EUR
        const priceEur = priceRaw ? parseDanishPrice(priceRaw) : 0

        const hasMissingColumns = !priceRaw || !description

        parsed_rows.push({
          tema,
          priceExample: priceRaw,
          priceEur,
          description,
          hasMissingColumns
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

    // Log activity
    if (props.profile.id) {
      await supabase.from('activity_log').insert({
        product_id: null, // bulk import
        action: 'csv_import',
        description: `Importerede ${createdProducts.length} produkter fra CSV`,
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
