import { ref, readonly } from 'vue'

const CACHE_KEY      = 'msf_eur_dkk_rate'
const CACHE_DATE_KEY = 'msf_eur_dkk_date'
const FALLBACK_RATE  = 7.46

const rate    = ref(FALLBACK_RATE)
const loading = ref(false)
const error   = ref(null)

function todayStr() {
  return new Date().toISOString().slice(0, 10)
}

async function fetchRate() {
  loading.value = true
  error.value   = null
  try {
    const res  = await fetch('https://api.frankfurter.app/latest?from=EUR&to=DKK')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    const r    = data.rates.DKK
    rate.value = r
    localStorage.setItem(CACHE_KEY,      String(r))
    localStorage.setItem(CACHE_DATE_KEY, todayStr())
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

export function useCurrency() {
  const cached     = localStorage.getItem(CACHE_KEY)
  const cachedDate = localStorage.getItem(CACHE_DATE_KEY)

  if (cached) rate.value = parseFloat(cached)
  if (cachedDate !== todayStr()) fetchRate()

  function eurToDkk(eur) {
    if (eur == null) return '–'
    return new Intl.NumberFormat('da-DK', {
      style:                 'currency',
      currency:              'DKK',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(parseFloat(eur) * rate.value)
  }

  return { rate: readonly(rate), loading: readonly(loading), error: readonly(error), eurToDkk, fetchRate }
}
