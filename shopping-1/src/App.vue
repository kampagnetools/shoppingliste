<template>
  <div class="min-h-screen bg-slate-100 font-sans antialiased text-slate-900 selection:bg-indigo-100 selection:text-indigo-900">

    <LoginForm v-if="!session" />

    <template v-else>
      <header class="bg-white border-b-2 border-slate-200 sticky top-0 z-40">
        <div class="max-w-screen-2xl mx-auto px-6 py-3 flex items-center gap-6">

          <h1 class="text-slate-900 font-bold text-sm tracking-tight uppercase">Shoppingliste</h1>

          <nav v-if="isAdmin" class="flex items-center gap-2">
            <button
              @click="showAddProduct = true"
              class="group flex items-center gap-2 bg-[#E30613] hover:bg-red-700 text-white px-4 py-2 text-xs font-bold transition-all"
            >
              <Plus :size="14" stroke-width="3" class="group-hover:rotate-90 transition-transform" />
              <span>Nyt produkt</span>
            </button>

            <button
              @click="showCsvImport = true"
              class="flex items-center gap-2 bg-white border border-slate-200 text-slate-600 px-4 py-2 text-xs font-medium hover:bg-slate-50 hover:border-slate-300 hover:text-slate-900 transition-all"
            >
              <Upload :size="14" />
              <span class="hidden md:inline">Importer CSV</span>
            </button>

            <button
              @click="showThemeManager = true"
              class="flex items-center gap-2 bg-white border border-slate-200 text-slate-600 px-4 py-2 text-xs font-medium hover:bg-slate-50 hover:border-slate-300 hover:text-slate-900 transition-all"
            >
              <Tags :size="14" />
              <span class="hidden md:inline">Temaer</span>
            </button>
          </nav>

          <div class="flex-1" />

          <div class="flex items-center gap-6">
            <div class="hidden lg:flex flex-col items-end">
              <span class="text-slate-400 text-[10px] font-bold uppercase tracking-tighter">Valutakurs</span>
              <span class="text-indigo-600 text-xs font-mono font-bold">1 EUR = {{ dkkRate.toFixed(2) }} DKK</span>
            </div>

            <div class="flex items-center gap-3 pl-6 border-l border-slate-200">
              <div
                class="text-[9px] uppercase tracking-[0.2em] font-black"
                :class="isAdmin ? 'text-indigo-500' : 'text-slate-400'"
              >
                {{ isAdmin ? 'Admin' : 'Standard' }}
              </div>

              <button @click="signOut" class="text-slate-400 hover:text-red-500 p-2 transition-colors group" title="Log ud">
                <LogOut :size="18" class="group-hover:translate-x-0.5 transition-transform" />
              </button>
            </div>
          </div>
        </div>
      </header>

      <div class="bg-gradient-to-b from-slate-50 to-white border-b border-slate-200 sticky top-[61px] z-30">
        <div class="max-w-screen-2xl mx-auto px-6 py-5 flex flex-wrap items-center gap-3">

          <!-- Title removed per user request -->

          <!-- Search -->
          <div class="relative flex-1 min-w-[260px]">
            <Search :size="16" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Søg navn eller links…"
              class="w-full bg-white border border-slate-200 hover:border-slate-300 pl-10 pr-4 py-2.5 text-sm font-medium text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 transition-all"
            />
          </div>

          <!-- Pris inline -->
          <div class="flex items-center gap-2 bg-white border border-slate-200 overflow-hidden hover:border-slate-300 transition-colors"
            :class="isPriceFiltered ? 'border-indigo-300 ring-2 ring-indigo-100' : ''">
            <span class="px-3 text-[11px] font-black text-slate-400 uppercase tracking-widest py-2.5">
              DKK
            </span>
            <input
              v-model.number="priceFrom"
              type="number"
              placeholder="Fra"
              class="w-16 px-2 py-2.5 text-sm font-bold bg-transparent focus:outline-none text-slate-700 placeholder:text-slate-300"
            />
            <span class="text-slate-300">–</span>
            <input
              v-model.number="priceTo"
              type="number"
              placeholder="Til"
              class="w-16 px-2 py-2.5 text-sm font-bold bg-transparent focus:outline-none text-slate-700 placeholder:text-slate-300"
            />
            <button v-if="isPriceFiltered" @click="priceFrom = ''; priceTo = ''"
              class="px-3 py-2.5 text-slate-400 hover:text-indigo-600 transition-colors">
              <X :size="14" stroke-width="3" />
            </button>
          </div>

          <!-- Temaer -->
          <select
            v-model="selectedTheme"
            class="w-48 bg-white border border-slate-200 hover:border-slate-300 px-4 py-2.5 text-sm text-slate-700 font-bold focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 cursor-pointer transition-all appearance-none"
            :class="selectedTheme ? 'border-indigo-300 ring-2 ring-indigo-100 text-indigo-700' : ''"
          >
            <option value="">Alle temaer</option>
            <option v-for="t in themes" :key="t.id" :value="t.id">{{ t.name }}</option>
          </select>

          <!-- Versioner -->
          <select
            v-model="selectedVersionId"
            class="w-48 bg-white border border-slate-200 hover:border-slate-300 px-4 py-2.5 text-sm font-bold focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100 cursor-pointer transition-all appearance-none"
            :class="selectedVersionId ? 'border-indigo-300 ring-2 ring-indigo-100 text-indigo-700' : 'text-slate-700'"
          >
            <option value="">Alle versioner</option>
            <option v-for="v in catalogVersions" :key="v.id" :value="v.id">
              {{ v.name }} · {{ fmtDate(v.created_at) }}
            </option>
          </select>
        </div>

      </div>

      <main class="max-w-screen-2xl mx-auto px-6 py-8">
        <div class="bg-white border border-slate-200 overflow-hidden">

          <div v-if="loadingProducts" class="py-40 flex flex-col items-center justify-center text-center">
            <div class="h-12 w-12 border-4 border-slate-100 border-t-indigo-600  animate-spin mb-4"></div>
            <p class="text-[10px] font-black text-slate-400 uppercase tracking-[0.3em]">Synkroniserer database</p>
          </div>

          <template v-else>
            <!-- Tabs -->
            <div class="flex items-center gap-0 px-6 border-b border-slate-200 bg-white">
              <button
                v-for="tab in [
                  { key: 'products', label: 'Produkt', count: processedProducts.length },
                  { key: 'active', label: 'Aktiv', count: activeProducts.length },
                  { key: 'archived', label: 'Arkiv', count: archivedProducts.length }
                ]"
                :key="tab.key"
                @click="activeTab = tab.key"
                class="relative py-4 px-6 text-sm font-semibold transition-all whitespace-nowrap flex items-center gap-2.5"
                :class="activeTab === tab.key ? 'text-indigo-600' : 'text-slate-500 hover:text-slate-700'"
              >
                {{ tab.label }}
                <span class="rounded-full min-w-[24px] px-2.5 py-0.5 text-[11px] font-black tabular-nums text-center transition-all"
                  :class="activeTab === tab.key
                    ? 'bg-gradient-to-r from-indigo-500 to-indigo-600 text-white'
                    : 'bg-slate-100 text-slate-500'">
                  {{ tab.count }}
                </span>
                <span v-if="activeTab === tab.key" class="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-indigo-500 to-indigo-600 rounded-t-full" />
              </button>
            </div>

            <!-- Sticky bulk action bar -->
            <div v-if="selectedIds.length > 0" class="sticky top-0 z-20 px-6 py-3 bg-gradient-to-r from-indigo-50 to-indigo-100 border-b-2 border-indigo-300 flex items-center justify-between">
              <span class="text-sm font-bold text-indigo-700">{{ selectedIds.length }} {{ selectedIds.length === 1 ? 'produkt' : 'produkter' }} valgt</span>
              <div class="flex gap-2">
                <button
                  v-if="selectedIds.length === 1"
                  @click="showAddMediaModal = true"
                  class="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-semibold transition-all"
                >
                  <span>Tilføj medie</span>
                </button>
                <button
                  @click="openProductDetail()"
                  :disabled="selectedIds.length !== 1"
                  class="flex items-center gap-2 px-4 py-2 text-sm font-semibold transition-all"
                  :class="selectedIds.length === 1
                    ? 'bg-indigo-600 hover:bg-indigo-700 text-white'
                    : 'bg-slate-300 text-slate-500 cursor-not-allowed'"
                >
                  <span>Rediger</span>
                </button>
              </div>
            </div>

            <!-- Products list (horizontal table view) -->
            <template v-if="activeTab === 'products'">
              <div class="border-t border-slate-200">
                <!-- Table headers -->
                <div class="hidden lg:grid px-6 py-3 text-xs font-bold text-slate-500 uppercase tracking-wide bg-white border-b border-slate-200" style="grid-template-columns: 0.4fr 2fr 0.9fr 1.2fr 1fr 0.9fr 1fr; gap: 1.25rem;">
                  <div class="flex items-center">
                    <input type="checkbox" :checked="selectedIds.length === processedProducts.length && processedProducts.length > 0" @change="toggleSelectAll" class="w-4 h-4 cursor-pointer" />
                  </div>
                  <div>Produkt</div>
                  <div>Pris</div>
                  <div>Beskrivelse</div>
                  <div>Tema</div>
                  <div>Version</div>
                  <div class="text-center">Ændringsdato</div>
                </div>

                <!-- Table rows -->
                <div class="divide-y divide-slate-200">
                  <template v-for="product in processedProducts" :key="product.id">
                    <!-- Desktop view -->
                    <div class="hidden lg:grid px-6 py-4 hover:bg-indigo-50 transition-colors min-h-[80px]" style="grid-template-columns: 0.4fr 2fr 0.9fr 1.2fr 1fr 0.9fr 1fr; gap: 1.25rem; align-items: center;">
                      <!-- Checkbox -->
                      <div class="flex items-center">
                        <input
                          type="checkbox"
                          :checked="selectedIds.includes(product.id)"
                          @change="toggleProductSelection(product.id)"
                          class="w-4 h-4 cursor-pointer"
                        />
                      </div>

                      <!-- Product name (clickable to copy) -->
                      <div class="min-w-0">
                        <span class="text-sm font-semibold text-slate-900 cursor-copy hover:text-indigo-600 truncate block" @click="copyToClipboard(product.name, 'Produktnavn kopieret')" title="Klik for at kopiere">
                          {{ product.name }}
                        </span>
                      </div>

                      <!-- Price DKK -->
                      <div>
                        <span class="text-sm font-bold text-slate-900 cursor-copy hover:text-indigo-600" @click="copyToClipboard(eurToDkk(product.price_eur), 'Pris kopieret')" title="Klik for at kopiere">
                          {{ eurToDkk(product.price_eur) }}
                        </span>
                      </div>

                      <!-- Price example (Beskrivelse) -->
                      <div class="text-xs text-slate-600 truncate cursor-copy hover:text-indigo-600" @click="copyToClipboard(product.price_example || '–', 'Beskrivelse kopieret')" title="Klik for at kopiere">
                        {{ product.price_example || '–' }}
                      </div>

                      <!-- Themes -->
                      <div class="overflow-x-auto scrollbar-hide cursor-grab active:cursor-grabbing select-none" @mousedown="startDrag" :data-product-id="product.id">
                        <div class="flex gap-1 whitespace-nowrap pb-1">
                          <span v-for="theme in product.themes" :key="theme.id" class="inline-block px-2.5 py-0.5 bg-slate-800 text-white text-xs font-semibold rounded-md flex-shrink-0">
                            {{ theme.name }}
                          </span>
                        </div>
                      </div>

                      <!-- Version -->
                      <div class="text-xs text-slate-600 truncate">
                        {{ catalogVersions.find(v => v.id === product.catalog_version_id)?.name || '–' }}
                      </div>

                      <!-- Last edited date -->
                      <div class="text-xs text-slate-600 cursor-copy hover:text-indigo-600 text-center" @click="copyToClipboard(fmtDate(product.last_edited_at || product.created_at), 'Dato kopieret')" title="Klik for at kopiere">
                        {{ fmtDate(product.last_edited_at || product.created_at) }}
                      </div>
                    </div>

                    <!-- Mobile view -->
                    <div class="lg:hidden px-6 py-4 hover:bg-indigo-50 transition-colors">
                      <div class="flex items-center gap-3 mb-3">
                        <input
                          type="checkbox"
                          :checked="selectedIds.includes(product.id)"
                          @change="toggleProductSelection(product.id)"
                          class="w-4 h-4 cursor-pointer flex-shrink-0"
                        />
                        <button @click="openProductDetailForId(product.id)" class="text-sm font-semibold text-indigo-600 hover:text-indigo-700 flex-1 text-left">
                          {{ product.name }}
                        </button>
                      </div>
                      <div class="space-y-2 ml-7">
                        <div class="flex justify-between text-xs">
                          <span class="text-slate-500">Pris:</span>
                          <span class="text-slate-900 font-bold cursor-copy hover:text-indigo-600" @click="copyToClipboard(eurToDkk(product.price_eur), 'Pris kopieret')">{{ eurToDkk(product.price_eur) }}</span>
                        </div>
                        <div class="text-xs">
                          <span class="text-slate-500 block mb-1">Tema:</span>
                          <div class="overflow-x-auto scrollbar-hide cursor-grab active:cursor-grabbing select-none" @mousedown="startDrag" :data-product-id="product.id">
                            <div class="flex gap-1 whitespace-nowrap">
                              <span v-for="theme in product.themes" :key="theme.id" class="inline-block px-2 py-0.5 bg-slate-800 text-white text-xs font-semibold rounded-md flex-shrink-0">
                                {{ theme.name }}
                              </span>
                              <span v-if="!product.themes || product.themes.length === 0" class="text-slate-500">–</span>
                            </div>
                          </div>
                        </div>
                        <div class="flex justify-between text-xs">
                          <span class="text-slate-500">Version:</span>
                          <span class="text-slate-700 font-medium">{{ catalogVersions.find(v => v.id === product.catalog_version_id)?.name || '–' }}</span>
                        </div>
                        <div class="flex justify-between text-xs">
                          <span class="text-slate-500">Ændret:</span>
                          <span class="text-slate-700 font-medium cursor-copy hover:text-indigo-600" @click="copyToClipboard(fmtDate(product.last_edited_at || product.created_at), 'Dato kopieret')">{{ fmtDate(product.last_edited_at || product.created_at) }}</span>
                        </div>
                      </div>
                    </div>
                  </template>
                </div>

                <div v-if="processedProducts.length === 0" class="py-32 flex flex-col items-center">
                  <Search :size="48" class="text-slate-200 mb-4" stroke-width="1.5" />
                  <h3 class="text-slate-900 font-bold text-lg">Intet match fundet</h3>
                  <button @click="clearFilters" class="mt-6 text-indigo-600 font-bold text-sm bg-indigo-50 px-6 py-2">Nulstil</button>
                </div>
              </div>
            </template>

            <!-- Aktiv tab: products with media -->
            <template v-else-if="activeTab === 'active'">
              <div class="border-t border-slate-200">
                <!-- Table headers -->
                <div class="hidden lg:grid px-6 py-3 text-xs font-bold text-slate-500 uppercase tracking-wide bg-white border-b border-slate-200" style="grid-template-columns: 0.4fr 2.5fr 0.9fr 1.2fr 1fr 2fr 1.2fr; gap: 1.25rem;">
                  <div class="flex items-center">
                    <input type="checkbox" :checked="selectedIds.length === activeProducts.length && activeProducts.length > 0" @change="toggleSelectAll" class="w-4 h-4 cursor-pointer" />
                  </div>
                  <div>Produkt</div>
                  <div>Pris</div>
                  <div>Beskrivelse</div>
                  <div>Tema</div>
                  <div>Medie</div>
                  <div>Tilføjet</div>
                </div>

                <div v-if="activeProducts.length === 0" class="py-32 flex flex-col items-center">
                  <Search :size="48" class="text-slate-200 mb-4" stroke-width="1.5" />
                  <h3 class="text-slate-900 font-bold text-lg">Ingen aktive produkter</h3>
                  <p class="text-slate-500 text-sm mt-2">Produkter med medie vil vises her</p>
                </div>

                <div v-else class="divide-y divide-slate-200">
                  <template v-for="product in activeProducts" :key="product.id">
                    <!-- Desktop view -->
                    <div class="hidden lg:grid px-6 py-4 hover:bg-emerald-50 transition-colors min-h-[80px]" style="grid-template-columns: 0.4fr 2.5fr 0.9fr 1.2fr 1fr 2fr 1.2fr; gap: 1.25rem; align-items: center;">
                      <!-- Checkbox -->
                      <div class="flex items-center">
                        <input
                          type="checkbox"
                          :checked="selectedIds.includes(product.id)"
                          @change="toggleProductSelection(product.id)"
                          class="w-4 h-4 cursor-pointer"
                        />
                      </div>

                      <!-- Product name -->
                      <h3 class="text-sm font-semibold text-slate-900 cursor-copy hover:text-indigo-600 truncate" @click="copyToClipboard(product.name, 'Navn kopieret')" title="Klik for at kopiere">
                        {{ product.name }}
                      </h3>

                      <!-- Price DKK -->
                      <div>
                        <span class="text-sm font-bold text-slate-900 cursor-copy hover:text-indigo-600" @click="copyToClipboard(eurToDkk(product.price_eur), 'Pris kopieret')" title="Klik for at kopiere">
                          {{ eurToDkk(product.price_eur) }}
                        </span>
                      </div>

                      <!-- Price example (Beskrivelse) -->
                      <div class="text-xs text-slate-600 truncate cursor-copy hover:text-indigo-600" @click="copyToClipboard(product.price_example || '–', 'Beskrivelse kopieret')" title="Klik for at kopiere">
                        {{ product.price_example || '–' }}
                      </div>

                      <!-- Themes -->
                      <div class="overflow-x-auto scrollbar-hide cursor-grab active:cursor-grabbing select-none" @mousedown="startDrag" :data-product-id="product.id">
                        <div class="flex gap-1 whitespace-nowrap pb-1">
                          <span v-for="theme in product.themes" :key="theme.id" class="inline-block px-2.5 py-0.5 bg-slate-800 text-white text-xs font-semibold rounded-md flex-shrink-0">
                            {{ theme.name }}
                          </span>
                        </div>
                      </div>

                      <!-- Media placements -->
                      <div class="space-y-2">
                        <template v-for="placement in product.placements" :key="placement.id">
                          <div class="text-xs text-slate-600">
                            <div v-if="placement.title"><span class="font-medium">Titel:</span> {{ placement.title }}</div>
                            <div>
                              <span class="font-medium">Medie:</span> {{ getMediaLabel(placement.channel) }}
                            </div>
                            <div v-if="placement.url">
                              <span class="font-medium">url:</span>
                              <a :href="placement.url" target="_blank" class="hover:underline break-all">{{ placement.url }}</a>
                            </div>
                          </div>
                        </template>
                      </div>

                      <!-- Tilføjet date column -->
                      <div class="text-xs text-slate-600">
                        <template v-for="(placement, idx) in product.placements" :key="placement.id">
                          <div v-if="idx === 0">{{ fmtDate(placement.created_at) }}</div>
                        </template>
                      </div>
                    </div>

                    <!-- Mobile view -->
                    <div class="lg:hidden px-6 py-4 hover:bg-emerald-50 transition-colors">
                      <h3 class="text-sm font-semibold text-slate-900 cursor-copy hover:text-indigo-600 mb-3" @click="copyToClipboard(product.name, 'Navn kopieret')" title="Klik for at kopiere">
                        {{ product.name }}
                      </h3>
                      <div class="space-y-2">
                        <div class="flex justify-between text-xs">
                          <span class="text-slate-500">Pris:</span>
                          <span class="text-slate-900 font-bold cursor-copy hover:text-indigo-600" @click="copyToClipboard(eurToDkk(product.price_eur), 'Pris kopieret')">{{ eurToDkk(product.price_eur) }}</span>
                        </div>
                        <div class="text-xs">
                          <span class="text-slate-500 block mb-1">Tema:</span>
                          <div class="overflow-x-auto scrollbar-hide cursor-grab active:cursor-grabbing select-none" @mousedown="startDrag" :data-product-id="product.id">
                            <div class="flex gap-1 whitespace-nowrap">
                              <span v-for="theme in product.themes" :key="theme.id" class="inline-block px-2 py-0.5 bg-slate-800 text-white text-xs font-semibold rounded-md flex-shrink-0">
                                {{ theme.name }}
                              </span>
                              <span v-if="!product.themes || product.themes.length === 0" class="text-slate-500">–</span>
                            </div>
                          </div>
                        </div>
                        <div class="space-y-2">
                          <template v-for="placement in product.placements" :key="placement.id">
                            <div class="text-xs text-slate-600">
                              <div v-if="placement.title"><span class="font-medium">Titel:</span> {{ placement.title }}</div>
                              <div>
                                <span class="font-medium">Medie:</span> {{ getMediaLabel(placement.channel) }}
                              </div>
                              <div v-if="placement.url">
                                <span class="font-medium">url:</span>
                                <a :href="placement.url" target="_blank" class="hover:underline break-all">{{ placement.url }}</a>
                              </div>
                              <div class="mt-1">
                                <span class="font-medium">Tilføjet:</span> {{ fmtDate(placement.created_at) }}
                              </div>
                            </div>
                          </template>
                        </div>
                      </div>
                    </div>
                  </template>
                </div>
              </div>
            </template>

            <!-- Arkiv tab: archived products -->
            <template v-else-if="activeTab === 'archived'">
              <div class="border-t border-slate-200">
                <div v-if="archivedProducts.length === 0" class="py-32 flex flex-col items-center">
                  <Search :size="48" class="text-slate-200 mb-4" stroke-width="1.5" />
                  <h3 class="text-slate-900 font-bold text-lg">Ingen arkiverede produkter</h3>
                </div>
                <div v-else>
                  <!-- Table headers -->
                  <div class="hidden lg:grid px-6 py-3 text-xs font-bold text-slate-500 uppercase tracking-wide bg-white border-b border-slate-200" style="grid-template-columns: 0.4fr 2fr 0.9fr 1.2fr 1fr 0.9fr 1fr; gap: 1.25rem;">
                    <div class="flex items-center">
                      <input type="checkbox" :checked="selectedIds.length === archivedProducts.length && archivedProducts.length > 0" @change="toggleSelectAll" class="w-4 h-4 cursor-pointer" />
                    </div>
                    <div>Produkt</div>
                    <div>Pris</div>
                    <div>Beskrivelse</div>
                    <div>Tema</div>
                    <div>Version</div>
                    <div class="text-center">Ændringsdato</div>
                  </div>

                  <div class="divide-y divide-slate-200">
                    <template v-for="product in archivedProducts" :key="product.id">
                      <!-- Desktop view -->
                      <div class="hidden lg:grid px-6 py-4 hover:bg-slate-50 transition-colors min-h-[80px]" style="grid-template-columns: 0.4fr 2fr 0.9fr 1.2fr 1fr 0.9fr 1fr; gap: 1.25rem; align-items: center;">
                        <!-- Checkbox -->
                        <div class="flex items-center">
                          <input
                            type="checkbox"
                            :checked="selectedIds.includes(product.id)"
                            @change="toggleProductSelection(product.id)"
                            class="w-4 h-4 cursor-pointer"
                          />
                        </div>

                        <!-- Product name (clickable to copy) -->
                        <div class="min-w-0">
                          <span class="text-sm font-semibold text-slate-900 cursor-copy hover:text-indigo-600 truncate block" @click="copyToClipboard(product.name, 'Produktnavn kopieret')" title="Klik for at kopiere">
                            {{ product.name }}
                          </span>
                        </div>

                        <!-- Price DKK -->
                        <div>
                          <span class="text-sm font-bold text-slate-900 cursor-copy hover:text-indigo-600" @click="copyToClipboard(eurToDkk(product.price_eur), 'Pris kopieret')" title="Klik for at kopiere">
                            {{ eurToDkk(product.price_eur) }}
                          </span>
                        </div>

                        <!-- Price example (Beskrivelse) -->
                        <div class="text-xs text-slate-600 truncate cursor-copy hover:text-indigo-600" @click="copyToClipboard(product.price_example || '–', 'Beskrivelse kopieret')" title="Klik for at kopiere">
                          {{ product.price_example || '–' }}
                        </div>

                        <!-- Themes -->
                        <div class="overflow-x-auto scrollbar-hide cursor-grab active:cursor-grabbing select-none" @mousedown="startDrag" :data-product-id="product.id">
                          <div class="flex gap-1 whitespace-nowrap pb-1">
                            <span v-for="theme in product.themes" :key="theme.id" class="inline-block px-2.5 py-0.5 bg-slate-800 text-white text-xs font-semibold rounded-md flex-shrink-0">
                              {{ theme.name }}
                            </span>
                          </div>
                        </div>

                        <!-- Version -->
                        <div class="text-xs text-slate-600 truncate">
                          {{ catalogVersions.find(v => v.id === product.catalog_version_id)?.name || '–' }}
                        </div>

                        <!-- Last edited date -->
                        <div class="text-xs text-slate-600 text-center">
                          {{ fmtDate(product.last_edited_at || product.created_at) }}
                        </div>
                      </div>

                      <!-- Mobile view -->
                      <div class="lg:hidden px-6 py-4 hover:bg-slate-50 transition-colors">
                        <div class="flex items-center gap-3 mb-3">
                          <input
                            type="checkbox"
                            :checked="selectedIds.includes(product.id)"
                            @change="toggleProductSelection(product.id)"
                            class="w-4 h-4 cursor-pointer flex-shrink-0"
                          />
                          <span class="text-sm font-semibold text-slate-900 cursor-copy hover:text-indigo-600 flex-1" @click="copyToClipboard(product.name, 'Produktnavn kopieret')" title="Klik for at kopiere">
                            {{ product.name }}
                          </span>
                        </div>
                        <div class="space-y-2 text-xs">
                          <div class="flex justify-between">
                            <span class="text-slate-500">Pris:</span>
                            <span class="text-slate-900 font-bold cursor-copy hover:text-indigo-600" @click="copyToClipboard(eurToDkk(product.price_eur), 'Pris kopieret')">{{ eurToDkk(product.price_eur) }}</span>
                          </div>
                          <div class="flex justify-between">
                            <span class="text-slate-500">Beskrivelse:</span>
                            <span class="text-slate-600 cursor-copy hover:text-indigo-600" @click="copyToClipboard(product.price_example || '–', 'Beskrivelse kopieret')">{{ product.price_example || '–' }}</span>
                          </div>
                          <div class="text-slate-500">
                            <span class="block mb-1">Tema:</span>
                            <div class="overflow-x-auto scrollbar-hide cursor-grab active:cursor-grabbing select-none" @mousedown="startDrag" :data-product-id="product.id">
                              <div class="flex gap-1 whitespace-nowrap">
                                <span v-for="theme in product.themes" :key="theme.id" class="inline-block px-2 py-0.5 bg-slate-800 text-white text-xs font-semibold rounded-md flex-shrink-0">
                                  {{ theme.name }}
                                </span>
                                <span v-if="!product.themes || product.themes.length === 0" class="text-slate-500">–</span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </template>
                  </div>
                </div>
              </div>
            </template>

            <!-- Placements grouped by product (traditional list format) -->
            <template v-else>
              <div class="border-t border-slate-200">
                <!-- Column headers -->
                <div class="px-8 py-3 grid gap-0 text-sm font-bold text-slate-500 uppercase tracking-widest bg-slate-50 border-b border-slate-200" style="grid-template-columns: 0.5fr 2fr 1.2fr 1.3fr;">
                  <span></span>
                  <span>Produkt</span>
                  <span>Kanaler</span>
                  <span style="justify-self: end;">Senest</span>
                </div>

                <div class="divide-y divide-slate-200">
                  <template v-for="product in processedProducts" :key="product.id">
                    <template v-if="(product.placements ?? []).length">
                      <!-- Product group header -->
                      <div
                        class="px-8 py-3 grid gap-0 text-sm border-b border-slate-200 hover:bg-slate-100 transition-all cursor-pointer items-center"
                        :class="expandedProductId === product.id ? 'bg-indigo-50 ring-2 ring-indigo-200' : 'bg-slate-50'"
                        :data-product-id="product.id"
                        @click="expandedProductId = expandedProductId === product.id ? null : product.id"
                        style="grid-template-columns: 0.5fr 2fr 1.2fr 1.3fr;"
                      >
                        <!-- Expand arrow -->
                        <button class="text-slate-400 hover:text-slate-600 text-xs flex-shrink-0 w-4">
                          {{ expandedProductId === product.id ? '▼' : '▶' }}
                        </button>

                        <!-- Product name with count -->
                        <span class="font-semibold text-slate-900 cursor-copy hover:text-indigo-600 min-w-0 truncate" @click.stop="copyToClipboard(product.name, 'Produktnavn kopieret')" title="Klik for at kopiere">
                          {{ product.name }} ({{ product.placements.length }})
                        </span>

                        <!-- Channel breakdown - clickable preview -->
                        <div v-show="!(channelsDialogOpen && selectedProductForChannels?.id === product.id)" @click="openChannelsDialog(product, $event)" class="flex items-center gap-1 flex-nowrap overflow-hidden cursor-pointer hover:opacity-80 transition-opacity relative">
                          <template v-for="channel in ['paid', 'web', 'email', 'some'].filter(c => product.placements.some(p => p.channel === c))" :key="channel">
                            <span class="text-xs bg-slate-700 text-white px-2 py-1 rounded whitespace-nowrap flex items-center gap-1.5">
                              {{ getMediaLabel(channel) }}
                              <span class="inline-flex items-center justify-center h-4 w-4  bg-white bg-opacity-20 text-xs font-semibold">{{ product.placements.filter(p => p.channel === channel).length }}</span>
                            </span>
                          </template>
                        </div>

                        <!-- Latest created/edited -->
                        <span class="text-slate-500 text-xs whitespace-nowrap" style="justify-self: end;">
                          {{ fmtDate(Math.max(...product.placements.map(p => new Date(p.created_at).getTime()))) }}
                        </span>
                      </div>

                      <!-- Placements list (hidden by default) -->
                      <div v-if="expandedProductId === product.id" class="w-full bg-indigo-50 border-t-2 border-l-4 border-indigo-200 -ml-1">
                        <!-- Placements sub-header -->
                        <div class="px-8 py-2 grid gap-0 text-sm font-bold text-slate-500 uppercase tracking-widest border-b border-slate-200" style="grid-template-columns: 0.5fr 2fr 1.2fr 1.3fr; justify-items: start;">
                          <span></span>
                          <span>Medie navn</span>
                          <span>Kanal</span>
                          <span style="justify-self: end;">Senest</span>
                        </div>

                        <div class="divide-y divide-slate-200">
                          <template v-for="placement in product.placements" :key="placement.id">
                            <div class="hover:bg-slate-100 transition-colors">
                              <div class="px-8 py-3 grid gap-0 text-sm items-center" style="grid-template-columns: 0.5fr 2fr 1.2fr 1.3fr; justify-items: start;">
                                <!-- Empty space -->
                                <span></span>

                                <!-- Title -->
                                <span class="text-slate-800 font-medium cursor-copy hover:text-indigo-600 min-w-0 truncate" @click.stop="copyToClipboard(placement.title, 'Navn kopieret')" title="Klik for at kopiere">
                                  {{ placement.title }}
                                </span>

                                <!-- Channel -->
                                <span class="text-xs bg-slate-700 text-white px-1.5 py-0.5 rounded whitespace-nowrap">
                                  {{ getMediaLabel(placement.channel) }}
                                </span>

                                <!-- Date -->
                                <span class="text-slate-500 cursor-copy hover:text-indigo-600 text-xs whitespace-nowrap" style="justify-self: end;" @click="copyToClipboard(fmtDate(placement.created_at), 'Dato kopieret')" title="Klik for at kopiere">
                                  {{ fmtDate(placement.created_at) }}
                                </span>
                              </div>
                          </div>
                        </template>
                        </div>
                      </div>
                    </template>
                  </template>
                </div>

                <div v-if="!allPlacements.length" class="py-32 flex flex-col items-center">
                  <Search :size="48" class="text-slate-200 mb-4" stroke-width="1.5" />
                  <h3 class="text-slate-900 font-bold text-lg">Ingen medie</h3>
                </div>
              </div>
            </template>

            <footer class="px-6 py-4 border-t border-slate-200 bg-white flex items-center justify-between">
              <div class="flex items-center gap-6">
                <div class="flex items-center gap-3">
                  <div class="h-8 w-8 bg-gradient-to-br from-indigo-500 to-indigo-600 flex items-center justify-center">
                    <span class="text-xs font-bold text-white tabular-nums">{{ processedProducts.length }}</span>
                  </div>
                  <span class="text-[11px] font-semibold text-slate-600 uppercase tracking-wide">Produkter</span>
                </div>
                <div class="w-px h-6 bg-slate-200"></div>
                <div class="flex items-center gap-3">
                  <div class="h-8 w-8 bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center">
                    <span class="text-xs font-bold text-white tabular-nums">{{ activeProducts.length }}</span>
                  </div>
                  <span class="text-[11px] font-semibold text-slate-600 uppercase tracking-wide">Aktive</span>
                </div>
              </div>
              <!-- Active version indicator -->
              <div v-if="selectedVersionId" class="flex items-center gap-2 text-[11px] text-slate-500">
                <GitBranch :size="12" />
                <span class="font-semibold text-slate-700">{{ catalogVersions.find(v => v.id === selectedVersionId)?.name }}</span>
                · {{ fmtDate(catalogVersions.find(v => v.id === selectedVersionId)?.created_at) }}
              </div>
            </footer>
          </template>
        </div>
      </main>

      <AddProductModal
        v-if="showAddProduct"
        :themes="themes"
        :profile="profile"
        :versions="catalogVersions"
        :catalogVersionId="selectedVersionId"
        @close="showAddProduct = false"
        @created="onProductCreated"
      />
      <ThemeManager v-if="showThemeManager" :themes="themes" @close="showThemeManager = false" @updated="themes = $event" />
      <CsvImportModal v-if="showCsvImport" :dkkRate="dkkRate" :profile="profile" @close="showCsvImport = false" @imported="onCsvImported" />

      <!-- Add Media Modal -->
      <div v-if="showAddMediaModal && selectedIds.length === 1" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm" @click.self="showAddMediaModal = false">
        <div class="bg-white w-full max-w-2xl border border-slate-200 overflow-hidden">
          <div class="flex items-center justify-between px-6 py-5 border-b border-slate-200 bg-gradient-to-r from-emerald-50 to-white">
            <h3 class="text-base font-bold text-slate-900">Tilføj medie</h3>
            <button @click="showAddMediaModal = false" class="p-1.5 hover:bg-slate-100 text-slate-400 transition-colors">
              <X :size="18" />
            </button>
          </div>

          <div class="px-6 py-5 space-y-4">
            <div>
              <label class="block text-sm font-semibold text-slate-700 mb-2">Type</label>
              <select v-model="newMediaForm.channel" class="w-full px-4 py-2.5 border border-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100">
                <option value="">Vælg type</option>
                <option value="paid">Paid</option>
                <option value="web">Web</option>
                <option value="email">E-mail</option>
                <option value="some">SoMe</option>
              </select>
            </div>

            <div v-if="newMediaForm.channel === 'web'">
              <label class="block text-sm font-semibold text-slate-700 mb-2">URL</label>
              <input v-model="newMediaForm.url" type="url" placeholder="https://..." class="w-full px-4 py-2.5 border border-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
            </div>

            <div>
              <label class="block text-sm font-semibold text-slate-700 mb-2">Navn (valgfrit)</label>
              <input v-model="newMediaForm.title" type="text" placeholder="f.eks. 'Facebook'" class="w-full px-4 py-2.5 border border-slate-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100" />
            </div>
          </div>

          <div class="px-6 py-4 bg-white border-t border-slate-200 flex gap-3 justify-end">
            <button @click="showAddMediaModal = false" class="px-4 py-2.5 border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors text-sm font-semibold">
              Annuller
            </button>
            <button @click="addMediaToProduct()" :disabled="!newMediaForm.channel" class="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 disabled:from-slate-400 disabled:to-slate-400 text-white transition-all text-sm font-semibold">
              Tilføj
            </button>
          </div>
        </div>
      </div>

      <ProductDetailModal v-if="showProductDetail" :products="getSelectedProducts" :themes="themes" @close="onProductDetailClose" @updated="onProductDetailUpdated" />

      <!-- Bulk themes modal -->
      <div v-if="showBulkThemesModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm" @click.self="showBulkThemesModal = false">
        <div class="bg-white w-full max-w-md border border-slate-200 overflow-hidden animate-in fade-in-0 zoom-in-95 duration-200">
          <div class="flex items-center justify-between px-6 py-5 border-b border-slate-200 bg-gradient-to-r from-indigo-50 to-white">
            <h3 class="text-base font-bold text-slate-900">Rediger Temaer</h3>
            <button @click="showBulkThemesModal = false" class="p-1.5 hover:bg-slate-100 text-slate-400 transition-colors">
              <X :size="18" />
            </button>
          </div>

          <div class="px-6 py-5 space-y-4 max-h-[400px] overflow-y-auto">
            <div class="space-y-2">
              <label class="block text-sm font-semibold text-slate-700 mb-3">Vælg temaer at tilføje/fjerne</label>
              <label v-for="theme in themes" :key="theme.id" class="flex items-center gap-3 p-2.5 hover:bg-slate-50 cursor-pointer transition-colors">
                <input
                  type="checkbox"
                  :checked="bulkThemesToAdd.has(theme.id) || bulkThemesToRemove.has(theme.id)"
                  @change="toggleBulkTheme(theme.id)"
                  class="w-4 h-4 cursor-pointer"
                />
                <span class="text-sm text-slate-700 font-medium flex-1">{{ theme.name }}</span>
                <span v-if="bulkThemesToAdd.has(theme.id)" class="text-xs px-2 py-1 bg-green-100 text-green-700  font-semibold">+ Tilføj</span>
                <span v-else-if="bulkThemesToRemove.has(theme.id)" class="text-xs px-2 py-1 bg-red-100 text-red-700  font-semibold">- Fjern</span>
              </label>
            </div>
          </div>

          <div class="px-6 py-4 bg-white border-t border-slate-200 flex gap-3 justify-end">
            <button
              @click="showBulkThemesModal = false"
              class="px-4 py-2.5 border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors text-sm font-semibold"
            >
              Annuller
            </button>
            <button
              @click="saveBulkThemes"
              :disabled="(bulkThemesToAdd.size === 0 && bulkThemesToRemove.size === 0) || bulkThemesAdding"
              class="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:from-slate-400 disabled:to-slate-400 text-white transition-all text-sm font-semibold"
            >
              <span v-if="bulkThemesAdding">Gemmer...</span>
              <span v-else>Gem ændringer</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Channels Dropdown -->
      <div v-if="channelsDialogOpen" @click="channelsDialogOpen = false" class="fixed inset-0 z-40" />
      <teleport to="body">
        <div v-if="channelsDialogOpen && selectedProductForChannels && channelsRef" class="fixed z-50 animate-in fade-in-0 zoom-in-95 duration-100" :style="{
          top: (channelsRef.getBoundingClientRect().top - 4) + 'px',
          left: channelsRef.getBoundingClientRect().left + 'px'
        }">
          <div class="bg-slate-800 border border-slate-700 overflow-hidden backdrop-blur-sm">
            <div class="p-1">
            <template v-for="channel in ['paid', 'web', 'email', 'some'].filter(c => selectedProductForChannels?.placements.some(p => p.channel === c))" :key="channel">
              <button
                @click="navigateToChannel(selectedProductForChannels, channel)"
                class="w-full text-sm bg-slate-700 hover:bg-slate-600 text-white px-4 py-3 cursor-pointer transition-all duration-150 flex items-center gap-3 justify-between text-left font-medium mb-1 last:mb-0 hover:scale-105 hover:shadow-lg"
              >
                <span class="flex items-center gap-2">
                  <span class="w-2 h-2 " :style="{
                    backgroundColor: {
                      'web': '#3b82f6',
                      'some': '#ec4899',
                      'email': '#f59e0b',
                      'paid': '#10b981'
                    }[channel]
                  }"></span>
                  {{ getMediaLabel(channel) }}
                </span>
                <span class="inline-flex items-center justify-center h-5 w-5  bg-white text-slate-800 text-xs font-bold">{{ selectedProductForChannels?.placements.filter(p => p.channel === channel).length }}</span>
              </button>
            </template>
            </div>
          </div>
        </div>
      </teleport>

    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { Search, Plus, Tags, LogOut, ArrowUpDown, GitBranch, X, Upload } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase.js'
import { useCurrency } from '@/composables/useCurrency.js'

import LoginForm       from '@/components/LoginForm.vue'
import ProductRow      from '@/components/ProductRow.vue'
import ArchivedRow     from '@/components/ArchivedRow.vue'
import AddProductModal from '@/components/AddProductModal.vue'
import ThemeManager from '@/components/ThemeManager.vue'
import CsvImportModal from '@/components/CsvImportModal.vue'
import ProductDetailModal from '@/components/ProductDetailModal.vue'

const session = ref(null)
const profile = ref(null)
const { rate: dkkRate, eurToDkk } = useCurrency()

const products        = ref([])
const themes          = ref([])
const catalogVersions = ref([])
const loadingProducts = ref(false)

const searchQuery      = ref('')
const selectedTheme    = ref('')
const selectedVersionId = ref('')
const priceFrom        = ref('')
const priceTo          = ref('')
const showAddProduct   = ref(false)
const showThemeManager = ref(false)
const showCsvImport = ref(false)
const showBulkMediaModal = ref(false)
const activeTab = ref('products')
const expandedProductId = ref(null)
const expandedPlacementId = ref(null)
const selectedIds = ref([])

// Product detail modal
const showProductDetail = ref(false)
const selectedProductForDetail = ref(null)
const showAddMediaModal = ref(false)
const newMediaForm = ref({ channel: '', url: '', title: '' })

// Bulk themes form
const showBulkThemesModal = ref(false)
const bulkThemesToAdd = ref(new Set())
const bulkThemesToRemove = ref(new Set())
const bulkThemesAdding = ref(false)

const sortBy = ref('latest_activity')
const sortOrder = ref('desc')

const isAdmin = computed(() => profile.value?.user_role === 'admin')
const isPriceFiltered = computed(() => priceFrom.value !== '' || priceTo.value !== '')
const hasActiveFilters = computed(() => searchQuery.value || selectedTheme.value || selectedVersionId.value || isPriceFiltered.value)

function fmtDate(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('da-DK', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

function fmtDateTime(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleString('da-DK', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

const copiedMessage = ref('')
function copyToClipboard(text, message) {
  navigator.clipboard.writeText(text).then(() => {
    copiedMessage.value = message
    setTimeout(() => { copiedMessage.value = '' }, 2000)
  })
}

const channelsDialogOpen = ref(false)
const selectedProductForChannels = ref(null)
const channelsRef = ref(null)

function openChannelsDialog(product, event) {
  selectedProductForChannels.value = product
  channelsDialogOpen.value = true
  if (event) {
    channelsRef.value = event.currentTarget
  }
}

function navigateToChannel(product, channel) {
  activeTab.value = 'placements'
  expandedProductId.value = product.id
  const firstPlacementOfChannel = product.placements.find(p => p.channel === channel)
  if (firstPlacementOfChannel) {
    expandedPlacementId.value = `placement-${firstPlacementOfChannel.id}`
  }
  channelsDialogOpen.value = false
  nextTick(() => {
    const el = document.querySelector(`[data-product-id='${product.id}']`)
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' })
  })
}

const activeProducts = computed(() =>
  [...products.value]
    .filter(p => !p.is_archived && p.placements?.length > 0)
    .sort((a, b) => new Date(b.last_edited_at || b.created_at) - new Date(a.last_edited_at || a.created_at))
)

const archivedProducts = computed(() =>
  [...products.value]
    .filter(p => p.is_archived)
    .sort((a, b) => new Date(b.archived_at) - new Date(a.archived_at))
)

const processedProducts = computed(() => {
  let list = products.value.filter(p => !p.is_archived)

  if (hasActiveFilters.value) {
    const query = searchQuery.value.trim().toLowerCase()
    const themeId = selectedTheme.value
    const versionId = selectedVersionId.value
    const minP = priceFrom.value !== '' ? priceFrom.value / dkkRate.value : null
    const maxP = priceTo.value !== '' ? priceTo.value / dkkRate.value : null

    list = list.filter(p => {
      if (versionId && p.catalog_version_id !== versionId) return false
      if (query) {
        const matchMain = p.name.toLowerCase().includes(query) || (p.unicat_name ?? '').toLowerCase().includes(query)
        const matchLinks = (p.placements ?? []).some(pl => pl.title.toLowerCase().includes(query) || pl.url.toLowerCase().includes(query))
        if (!matchMain && !matchLinks) return false
      }
      if (themeId && !(p.themes ?? []).some(t => t.id === themeId)) return false
      if (minP !== null && p.price_eur < minP) return false
      if (maxP !== null && p.price_eur > maxP) return false
      return true
    })
  }

  list.sort((a, b) => {
    let modifier = sortOrder.value === 'asc' ? 1 : -1

    if (sortBy.value === 'isActive') {
      const aAct = a.placements?.length > 0 ? 1 : 0
      const bAct = b.placements?.length > 0 ? 1 : 0
      return (aAct - bAct) * modifier
    }

    if (sortBy.value === 'latest_activity') {
      const aTime = new Date(a.last_edited_at || a.created_at).getTime()
      const bTime = new Date(b.last_edited_at || b.created_at).getTime()
      return (aTime - bTime) * modifier
    }

    const valA = a[sortBy.value] ?? ''
    const valB = b[sortBy.value] ?? ''
    if (valA < valB) return -1 * modifier
    if (valA > valB) return 1 * modifier
    return 0
  })

  return list
})

const allPlacements = computed(() => {
  return products.value.flatMap(p =>
    (p.placements ?? []).map(pl => ({ ...pl, product: p }))
  )
})

const getSelectedProducts = computed(() => {
  return products.value.filter(p => selectedIds.value.includes(p.id))
})

const setSort = (field) => {
  if (sortBy.value === field) {
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortBy.value = field
    sortOrder.value = 'desc'
  }
}

async function loadInitialData() {
  loadingProducts.value = true
  try {
    const [versionsRes, themesRes, productsRes] = await Promise.all([
      supabase.from('catalog_versions').select('*').order('created_at', { ascending: true }),
      supabase.from('themes').select('*').order('name'),
      supabase.from('products').select(`
        *,
        themes:product_themes(theme:themes(*)),
        placements(*),
        editor:profiles!last_edited_by(full_name, email),
        archiver:profiles!archived_by(full_name, email)
      `).order('created_at', { ascending: false })
    ])

    catalogVersions.value = versionsRes.data ?? []
    themes.value = themesRes.data ?? []
    products.value = (productsRes.data ?? []).map(p => ({
      ...p,
      themes: (p.themes ?? []).map(t => t.theme),
      placements: p.placements ?? []
    }))
  } catch (err) {
    console.error(err)
  } finally {
    loadingProducts.value = false
  }
}

async function signOut() {
  await supabase.auth.signOut()
  session.value = null
  profile.value = null
}

const clearFilters = () => {
  searchQuery.value = ''; selectedTheme.value = ''; priceFrom.value = ''; priceTo.value = ''
}

const onProductDeleted    = (id)  => { products.value = products.value.filter(p => p.id !== id) }
const onProductUpdated    = (upd) => {
  const i = products.value.findIndex(p => p.id === upd.id)
  if (i !== -1) products.value[i] = { ...products.value[i], ...upd }
}
const onProductDuplicated = (p)   => { products.value.unshift(p); activeTab.value = 'active' }
const onProductCreated    = ()    => { showAddProduct.value = false; loadInitialData() }
const onProductArchived   = (id)  => {
  const i = products.value.findIndex(p => p.id === id)
  if (i !== -1) products.value[i] = { ...products.value[i], is_archived: true, archived_at: new Date().toISOString() }
}
const onProductReactivated = (p)  => {
  const i = products.value.findIndex(x => x.id === p.id)
  if (i !== -1) products.value[i] = p
  activeTab.value = 'active'
}

const onCsvImported = () => {
  showCsvImport.value = false
  loadInitialData()
}

function getMediaLabel(channel) {
  const labels = {
    'paid': 'Paid',
    'web': 'Web',
    'email': 'E-mail',
    'some': 'SoMe'
  }
  return labels[channel] || channel
}

function getUrlHostname(url) {
  try {
    return new URL(url).hostname
  } catch {
    return url
  }
}

function startDrag(e) {
  let isDown = true
  let startX = e.pageX
  let scrollLeft = e.currentTarget.scrollLeft

  const onMouseMove = (e) => {
    if (!isDown) return
    e.preventDefault()
    const x = e.pageX - startX
    e.currentTarget.scrollLeft = scrollLeft - x
  }

  const onMouseUp = () => {
    isDown = false
    document.removeEventListener('mousemove', onMouseMove)
    document.removeEventListener('mouseup', onMouseUp)
  }

  document.addEventListener('mousemove', onMouseMove)
  document.addEventListener('mouseup', onMouseUp)
}

function toggleSelectAll(event) {
  if (event.target.checked) {
    selectedIds.value = processedProducts.value.map(p => p.id)
  } else {
    selectedIds.value = []
  }
}

function toggleProductSelection(productId) {
  const idx = selectedIds.value.indexOf(productId)
  if (idx > -1) {
    selectedIds.value.splice(idx, 1)
  } else {
    selectedIds.value.push(productId)
  }
}

function openBulkMediaModal() {
  bulkMediaType.value = ''
  bulkMediaUrl.value = ''
  bulkMediaTitle.value = ''
  showBulkMediaModal.value = true
}

function openProductDetail() {
  if (selectedIds.value.length > 0) {
    showProductDetail.value = true
  }
}

function openProductDetailForId(productId) {
  selectedIds.value = [productId]
  showProductDetail.value = true
}

async function addMediaToProduct() {
  if (!newMediaForm.value.channel || selectedIds.value.length !== 1) return

  const productId = selectedIds.value[0]

  try {
    const { error } = await supabase
      .from('placements')
      .insert({
        product_id: productId,
        channel: newMediaForm.value.channel,
        title: newMediaForm.value.title,
        url: newMediaForm.value.url
      })

    if (error) throw error

    // Reset form and close modal
    newMediaForm.value = { channel: '', url: '', title: '' }
    showAddMediaModal.value = false
    selectedIds.value = []

    // Reload data
    await loadInitialData()
  } catch (err) {
    console.error('Error adding media:', err)
    alert('Fejl ved tilføjelse af medie: ' + err.message)
  }
}

function onProductDetailClose() {
  showProductDetail.value = false
  selectedProductForDetail.value = null
  selectedIds.value = []
}

async function onProductDetailUpdated() {
  showProductDetail.value = false
  selectedProductForDetail.value = null
  selectedIds.value = []
  await loadInitialData()
}

function openBulkThemesModal() {
  bulkThemesToAdd.value.clear()
  bulkThemesToRemove.value.clear()
  showBulkThemesModal.value = true
}

function toggleBulkTheme(themeId) {
  if (bulkThemesToAdd.has(themeId)) {
    bulkThemesToAdd.value.delete(themeId)
  } else if (bulkThemesToRemove.has(themeId)) {
    bulkThemesToRemove.value.delete(themeId)
  } else {
    bulkThemesToAdd.value.add(themeId)
  }
}

async function saveBulkThemes() {
  if (bulkThemesToAdd.value.size === 0 && bulkThemesToRemove.value.size === 0) return

  bulkThemesAdding.value = true
  try {
    for (const productId of selectedIds.value) {
      // Remove themes
      if (bulkThemesToRemove.value.size > 0) {
        const { error } = await supabase
          .from('product_themes')
          .delete()
          .eq('product_id', productId)
          .in('theme_id', Array.from(bulkThemesToRemove.value))
        if (error) throw error
      }

      // Add themes
      if (bulkThemesToAdd.value.size > 0) {
        const { error } = await supabase
          .from('product_themes')
          .insert(Array.from(bulkThemesToAdd.value).map(themeId => ({
            product_id: productId,
            theme_id: themeId
          })))
        if (error) throw error
      }

      // Update product last_edited_at
      const { error: updateError } = await supabase
        .from('products')
        .update({
          last_edited_at: new Date().toISOString(),
          last_edited_by: profile.value?.id
        })
        .eq('id', productId)
      if (updateError) throw updateError
    }

    await loadInitialData()
    showBulkThemesModal.value = false
    selectedIds.value = []
  } catch (err) {
    console.error('Error saving themes:', err)
    alert('Fejl ved gemning: ' + err.message)
  } finally {
    bulkThemesAdding.value = false
  }
}

onMounted(async () => {
  const { data: { session: s } } = await supabase.auth.getSession()
  session.value = s
  if (s) {
    const { data } = await supabase.from('profiles').select('*').eq('id', s.user.id).single()
    profile.value = data
    loadInitialData()
  }

  supabase.auth.onAuthStateChange(async (_event, newSession) => {
    if (newSession) {
      session.value = newSession
      const { data } = await supabase.from('profiles').select('*').eq('id', newSession.user.id).single()
      profile.value = data
      if (products.value.length === 0) loadInitialData()
    } else {
      session.value = null; profile.value = null; products.value = []
    }
  })
})
</script>

<style scoped>
.header-cell {
  @apply text-[11px] font-bold text-slate-500 uppercase tracking-[0.12em];
}
.stat-group {
  @apply flex items-center gap-2;
}
.stat-label {
  @apply text-[9px] font-black text-slate-400 uppercase tracking-widest;
}
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.stat-value {
  @apply text-xs font-black text-slate-700;
}
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-thumb { @apply bg-slate-200  hover:bg-slate-300; }
</style>
