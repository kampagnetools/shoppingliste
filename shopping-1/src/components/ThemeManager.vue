<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40" @click.self="$emit('close')">
    <div class="bg-white w-full max-w-md border border-msf-border overflow-hidden">
      
      <div class="flex items-center justify-between px-6 py-4 border-b border-msf-border bg-gray-50/50">
        <h3 class="text-base font-semibold text-msf-navy">Administrer Temaer</h3>
        <button @click="$emit('close')" class="p-1.5  hover:bg-gray-200 text-gray-400 transition-colors">
          <X :size="18" />
        </button>
      </div>

      <div class="px-6 py-5 space-y-4">
        <form @submit.prevent="addTheme" class="flex gap-2">
          <input 
            v-model="newName" 
            type="text" 
            class="input-field flex-1" 
            placeholder="Nyt tema (f.eks. 'Nødhjælp'...)" 
            required 
            :disabled="saving"
          />
          <button type="submit" :disabled="saving || !newName.trim()" class="btn-primary whitespace-nowrap min-w-[80px]">
            <span v-if="saving">...</span>
            <span v-else>Tilføj</span>
          </button>
        </form>

        <div v-if="errorMsg" class="rounded-lg bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700 flex justify-between items-start">
          <span>{{ errorMsg }}</span>
          <button @click="errorMsg = ''" class="text-red-400 hover:text-red-600">✕</button>
        </div>

        <div class="max-h-[350px] overflow-y-auto pr-1 custom-scrollbar">
          <ul class="divide-y divide-msf-border border overflow-hidden">
            <li
              v-for="theme in sortedThemes"
              :key="theme.id"
              class="group flex items-center justify-between py-3 px-4 hover:bg-gray-50 transition-colors"
            >
              <span class="text-sm font-medium text-gray-700">{{ theme.name }}</span>
              <button
                @click="deleteTheme(theme)"
                class="opacity-0 group-hover:opacity-100 p-2 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition-all"
                title="Slet tema"
              >
                <Trash2 :size="15" />
              </button>
            </li>
            
            <li v-if="!localThemes.length" class="py-10 text-center">
              <p class="text-sm text-gray-400 italic">Ingen temaer oprettet endnu.</p>
            </li>
          </ul>
        </div>
      </div>

      <div class="px-6 py-3 bg-gray-50 border-t border-msf-border text-[11px] text-gray-400">
        Bemærk: Sletning af et tema fjerner det permanent fra alle tilknyttede produkter.
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { X, Trash2 } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase.js'

const props = defineProps({ 
  themes: { type: Array, default: () => [] } 
})
const emit = defineEmits(['close', 'updated'])

const localThemes = ref([...props.themes])
const newName     = ref('')
const saving      = ref(false)
const errorMsg    = ref('')

const sortedThemes = computed(() =>
  [...localThemes.value].sort((a, b) => a.name.localeCompare(b.name))
)

async function addTheme() {
  if (!newName.value.trim()) return
  
  saving.value   = true
  errorMsg.value = ''
  
  const { data, error } = await supabase
    .from('themes')
    .insert({ name: newName.value.trim() })
    .select()
    .single()

  if (error) {
    if (error.code === '23505') {
      errorMsg.value = 'Dette tema eksisterer allerede.'
    } else {
      errorMsg.value = 'Der opstod en fejl: ' + error.message 
    }
  } else { 
    localThemes.value.push(data)
    newName.value = ''
    emit('updated', localThemes.value) 
  }
  
  saving.value = false
}

async function deleteTheme(theme) {
  const isConfirmed = confirm(`Er du sikker på, at du vil slette temaet "${theme.name}"?\n\nDet vil blive fjernet fra alle produkter, der bruger det.`)
  
  if (!isConfirmed) return

  errorMsg.value = ''
  
  const { error } = await supabase
    .from('themes')
    .delete()
    .eq('id', theme.id)

  if (error) { 
    errorMsg.value = 'Kunne ikke slette tema: ' + error.message 
    return 
  }

  localThemes.value = localThemes.value.filter(t => t.id !== theme.id)
  emit('updated', localThemes.value)
}
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e5e7eb;
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #d1d5db;
}
</style>