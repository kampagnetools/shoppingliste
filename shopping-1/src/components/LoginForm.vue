<template>
  <div class="min-h-screen bg-[#F4F7FE] flex items-center justify-center p-4">
    <div class="w-full max-w-[400px]">
      
      <div class="bg-white shadow-slate-200/60 border border-slate-200 overflow-hidden">
        <div class="h-1.5 bg-[#002060] w-full"></div>
        
        <div class="p-8">
          <div class="mb-8 text-center">
            <h2 class="text-xl font-bold text-slate-800">Log ind</h2>
            <p class="text-sm text-slate-500 mt-1">Indtast dine oplysninger for adgang</p>
          </div>

          <form @submit.prevent="handleSubmit" class="space-y-5">
            <div>
              <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-2">
                E-mail
              </label>
              <input
                v-model="form.email"
                type="email"
                required
                autocomplete="email"
                class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 focus:ring-4 focus:ring-[#002060]/10 focus:border-[#002060] outline-none transition-all placeholder:text-slate-400"
                placeholder="navn@domæne.org"
              />
            </div>

            <div>
              <label class="block text-[11px] font-bold uppercase tracking-wider text-slate-600 mb-2">
                Adgangskode
              </label>
              <input
                v-model="form.password"
                type="password"
                required
                autocomplete="current-password"
                class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 focus:ring-4 focus:ring-[#002060]/10 focus:border-[#002060] outline-none transition-all placeholder:text-slate-400"
                placeholder="••••••••"
              />
            </div>

            <div v-if="errorMsg" class="p-3 bg-red-50 border border-red-100 text-xs text-red-700 font-medium animate-in fade-in slide-in-from-top-1">
              {{ errorMsg }}
            </div>

            <button 
              type="submit" 
              :disabled="loading" 
              class="w-full bg-[#002060] hover:bg-[#001845] text-white font-bold py-3 shadow-lg shadow-[#002060]/10 transition-all active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <Loader2 v-if="loading" :size="18" class="animate-spin" />
              <span>{{ loading ? 'Godkender...' : 'Log ind' }}</span>
            </button>
          </form>

          
        </div>
      </div>
      
     
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { supabase } from '@/lib/supabase.js'
import { Loader2 } from 'lucide-vue-next'

const form     = ref({ email: '', password: '' })
const loading  = ref(false)
const errorMsg = ref('')

async function handleSubmit() {
  if (loading.value) return
  loading.value = true
  errorMsg.value = ''

  try {
    const { error } = await supabase.auth.signInWithPassword({
      email:    form.value.email,
      password: form.value.password
    })

    if (error) {
      errorMsg.value = error.message.includes('Invalid login credentials')
        ? 'Forkert e-mail eller adgangskode.'
        : 'Adgang nægtet. Tjek dine oplysninger.'
    }
  } catch (e) {
    errorMsg.value = 'Netværksfejl. Prøv igen senere.'
  } finally {
    loading.value = false
  }
}
</script>