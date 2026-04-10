<template>
  <!-- ── Collapsed row ──────────────────────────────────────── -->
  <tr
    class="group transition-colors duration-150 cursor-pointer border-b last:border-0"
    :class="expanded
      ? 'bg-red-50/40 border-red-100'
      : 'hover:bg-gray-50 border-gray-100'"
    @click="toggle"
  >
    <!-- Status -->
    <td class="py-5 whitespace-nowrap relative" :class="expanded ? 'pl-5 pr-4' : 'pl-6 pr-4'">
      <span v-if="expanded" class="absolute left-0 top-2 bottom-2 w-1 rounded-r-full bg-[#E30613]" />
      <div class="flex items-center gap-2">
        <span class="h-2 w-2  flex-shrink-0" :class="isActive ? 'bg-green-500' : 'bg-gray-300'" />
        <span class="text-sm font-medium" :class="isActive ? 'text-green-700' : 'text-gray-400'">
          {{ isActive ? 'Aktiv' : 'Ikke aktiv' }}
        </span>
      </div>
    </td>

    <!-- Name -->
    <td class="px-4 py-5" @click.stop>
      <div v-if="editingRowName" class="flex items-center gap-2">
        <input
          v-model="rowNameDraft"
          ref="rowNameInput"
          class="input-field text-sm font-semibold"
          @keyup.enter="saveRowName"
          @keyup.escape="editingRowName = false"
        />
        <button @click="saveRowName" :disabled="savingRowName" class="btn-primary py-1.5 text-xs">{{ savingRowName ? '…' : 'Gem' }}</button>
        <button @click="editingRowName = false" class="btn-ghost py-1.5 text-xs">✕</button>
      </div>
      <div v-else class="group/name flex items-center gap-2 min-w-0">
        <span
          class="text-sm font-semibold truncate transition-colors cursor-copy"
          :class="expanded ? 'text-[#E30613]' : 'text-gray-900'"
          @click="copyText(localProduct.name, 'name')"
          title="Klik for at kopiere"
        >{{ localProduct.name }}</span>
        <span v-if="localProduct.version_number > 1"
          class="flex-shrink-0 text-[10px] font-bold  px-1.5 py-0.5 bg-indigo-100 text-indigo-600">
          v{{ localProduct.version_number }}
        </span>
        <span v-if="copied === 'name'" class="text-xs text-green-500 font-medium flex-shrink-0">✓</span>
        <button
          v-else-if="isAdmin"
          @click="startEditRowName"
          class="flex-shrink-0 p-1 rounded text-gray-300 hover:text-[#E30613] opacity-0 group-hover/name:opacity-100 transition-all"
          title="Omdøb"
        ><Pencil :size="12" /></button>
      </div>
    </td>

    <!-- Price -->
    <td class="px-4 py-5 whitespace-nowrap" @click.stop="copyText(eurToDkk(localProduct.price_eur), 'price')">
      <div class="group/p inline-flex items-center gap-1.5 cursor-copy">
        <span class="text-sm font-semibold tabular-nums text-gray-900">{{ eurToDkk(localProduct.price_eur) }}</span>
        <span v-if="copied === 'price'" class="text-xs text-green-500 font-medium">✓</span>
        <ClipboardCopy v-else :size="12" class="text-gray-300 opacity-0 group-hover/p:opacity-100 transition-opacity" />
      </div>
    </td>

    <!-- Themes -->
    <td class="px-4 py-5 whitespace-nowrap">
      <div class="flex items-center gap-1">
        <span
          v-for="theme in (localProduct.themes ?? []).slice(0, 2)" :key="theme.id"
          class="inline-flex items-center  px-2.5 py-0.5 text-xs font-medium bg-gray-100 text-gray-600"
        >{{ theme.name }}</span>
        <span v-if="(localProduct.themes?.length ?? 0) > 2"
          class="inline-flex items-center  px-2 py-0.5 text-xs font-medium bg-gray-200 text-gray-500">
          +{{ localProduct.themes.length - 2 }}
        </span>
        <span v-if="!localProduct.themes?.length" class="text-sm text-gray-300">–</span>
      </div>
    </td>

    <!-- Latest activity (click for log) -->
    <td class="px-4 py-5 whitespace-nowrap" @click.stop="openLog">
      <div class="group/date flex flex-col gap-0.5 cursor-pointer">
        <span class="text-sm tabular-nums text-gray-700 group-hover/date:text-[#E30613] transition-colors">
          {{ localProduct.last_edited_at ? lastEditedFormatted : createdFormatted }}
        </span>
        <span class="text-[10px] font-medium uppercase tracking-wider flex items-center gap-1"
          :class="localProduct.last_edited_at ? 'text-gray-400' : 'text-gray-300'">
          {{ localProduct.last_edited_at ? 'Ændret' : 'Oprettet' }}
          <History :size="10" class="opacity-0 group-hover/date:opacity-100 transition-opacity" />
        </span>
      </div>
    </td>

    <!-- Actions -->
    <td class="pl-4 pr-6 py-5 text-right whitespace-nowrap" @click.stop>
      <div class="flex items-center justify-end gap-2">
        <button
          @click="toggle"
          class="inline-flex items-center gap-1.5 whitespace-nowrap px-3 py-1.5 text-sm font-medium transition-all duration-150"
          :class="expanded
            ? 'bg-[#E30613] text-white'
            : 'opacity-0 group-hover:opacity-100 text-gray-500 hover:text-gray-900 hover:bg-gray-100'"
        >
          {{ expanded ? 'Luk' : 'Se detaljer' }}
          <ChevronDown :size="14" class="transition-transform duration-200" :class="{ 'rotate-180': expanded }" />
        </button>
        <button
          v-if="isAdmin"
          @click="openDuplicateModal"
          :disabled="duplicating"
          class="p-1.5 text-gray-300 hover:text-gray-600 hover:bg-gray-100 opacity-0 group-hover:opacity-100 transition-all duration-150"
          title="Dubler produkt"
        ><Copy :size="15" /></button>
      </div>
    </td>
  </tr>

  <!-- ── Expanded panel ─────────────────────────────────────── -->
  <tr v-if="expanded">
    <td colspan="6" class="border-b border-red-100 bg-red-50/20">
      <div class="mx-6 my-4 border border-gray-100 overflow-hidden bg-white">

        <!-- Stamdata -->
        <div class="px-8 py-6 bg-white">
          <div class="flex items-center justify-between mb-5">
            <h4 class="text-xs font-bold text-gray-500 uppercase tracking-widest flex items-center gap-2">
              <span class="h-3.5 w-0.5  bg-[#E30613]" />
              Stamdata
            </h4>
            <div v-if="isAdmin" class="flex gap-2">
              <template v-if="!editingMeta">
                <button @click="startEditMeta" class="btn-ghost text-xs">
                  <Pencil :size="12" /> Rediger
                </button>
                <button @click="confirmArchive" class="btn-ghost text-xs">
                  <Archive :size="12" /> Arkivér
                </button>
                <button @click="confirmDelete" class="btn-danger text-xs">
                  <Trash2 :size="12" /> Slet
                </button>
              </template>
              <template v-else>
                <button @click="saveMeta" :disabled="savingMeta" class="btn-primary text-xs">
                  {{ savingMeta ? 'Gemmer…' : 'Gem ændringer' }}
                </button>
                <button @click="cancelEditMeta" class="btn-ghost text-xs">Annuller</button>
              </template>
            </div>
          </div>

          <div class="grid grid-cols-3 gap-8">
            <!-- UNICAT -->
            <div>
              <div class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">UNICAT Navn</div>
              <input v-if="editingMeta" v-model="metaForm.unicat_name" class="input-field text-sm" placeholder="DEPRESSOR, TONGUE, wooden" />
              <div v-else @click="copyText(localProduct.unicat_name, 'unicat')"
                class="group/c relative text-sm text-gray-800 cursor-copy flex items-start gap-2 hover:text-gray-600 transition-colors">
                <span>{{ localProduct.unicat_name || '–' }}</span>
                <span v-if="copied === 'unicat'" class="text-xs text-green-500 font-medium flex-shrink-0">✓</span>
                <ClipboardCopy v-else-if="localProduct.unicat_name" :size="12" class="text-gray-300 mt-0.5 flex-shrink-0 opacity-0 group-hover/c:opacity-100 transition-opacity" />
              </div>
            </div>

            <!-- Description -->
            <div>
              <div class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Fundraising-beskrivelse</div>
              <textarea v-if="editingMeta" v-model="metaForm.description" rows="3" class="input-field text-sm resize-none" />
              <div v-else @click="copyText(localProduct.description, 'desc')"
                class="group/c relative text-sm text-gray-800 leading-relaxed cursor-copy flex items-start gap-2 hover:text-gray-600 transition-colors">
                <span>{{ localProduct.description || '–' }}</span>
                <span v-if="copied === 'desc'" class="text-xs text-green-500 font-medium flex-shrink-0">✓</span>
                <ClipboardCopy v-else-if="localProduct.description" :size="12" class="text-gray-300 mt-0.5 flex-shrink-0 opacity-0 group-hover/c:opacity-100 transition-opacity" />
              </div>
            </div>

            <!-- Price example -->
            <div>
              <div class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Priseksempel</div>
              <input v-if="editingMeta" v-model="metaForm.price_example" class="input-field text-sm" placeholder="X stk. til behandling…" />
              <div v-else @click="copyText(localProduct.price_example, 'example')"
                class="group/c relative text-sm text-gray-800 cursor-copy flex items-start gap-2 hover:text-gray-600 transition-colors">
                <span>{{ localProduct.price_example || '–' }}</span>
                <span v-if="copied === 'example'" class="text-xs text-green-500 font-medium flex-shrink-0">✓</span>
                <ClipboardCopy v-else-if="localProduct.price_example" :size="12" class="text-gray-300 mt-0.5 flex-shrink-0 opacity-0 group-hover/c:opacity-100 transition-opacity" />
              </div>
            </div>

            <!-- Price EUR (edit only) -->
            <div v-if="editingMeta">
              <div class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Pris (EUR)</div>
              <input v-model.number="metaForm.price_eur" type="number" step="0.0001" min="0" class="input-field text-sm w-36" />
            </div>

            <!-- Themes (edit only) -->
            <div v-if="editingMeta" class="col-span-2">
              <div class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Temaer</div>
              <div class="flex flex-wrap gap-3">
                <label v-for="theme in allThemes" :key="theme.id" class="inline-flex items-center gap-1.5 text-sm cursor-pointer text-gray-700">
                  <input type="checkbox" :value="theme.id" v-model="metaForm.themeIds" class="rounded border-gray-300 accent-[#E30613]" />
                  {{ theme.name }}
                </label>
              </div>
            </div>
          </div>

          <div v-if="metaError" class="mt-4 text-sm text-red-600">{{ metaError }}</div>
        </div>

        <!-- Versioner -->
        <div class="px-8 py-5 bg-indigo-50/30 border-t border-gray-100">
          <div class="flex items-center justify-between mb-4">
            <h4 class="text-xs font-bold text-gray-500 uppercase tracking-widest flex items-center gap-2">
              <span class="h-3.5 w-0.5  bg-indigo-300" />
              Versioner
              <span class="text-[10px] font-bold  px-1.5 py-0.5 bg-indigo-100 text-indigo-600 normal-case tracking-normal">
                {{ loadingVersions ? '…' : versions.length }}
              </span>
            </h4>
            <button v-if="isAdmin" @click.stop="openVersionModal" class="btn-ghost text-xs flex items-center gap-1.5">
              <GitBranch :size="12" /> Ny version
            </button>
          </div>

          <div v-if="loadingVersions" class="text-sm text-gray-400 italic">Henter versioner…</div>
          <div v-else-if="!versions.length" class="text-sm text-gray-400 italic">Ingen andre versioner.</div>
          <div v-else class="space-y-1.5">
            <div
              v-for="v in versions" :key="v.id"
              class="flex items-center gap-3 px-3 py-2 text-sm"
              :class="v.id === localProduct.id ? 'bg-indigo-50 border border-indigo-100' : 'bg-white border border-gray-100'"
            >
              <span class="flex-shrink-0 text-[10px] font-bold  px-1.5 py-0.5"
                :class="v.id === localProduct.id ? 'bg-indigo-600 text-white' : 'bg-indigo-100 text-indigo-600'">
                v{{ v.version_number }}
              </span>
              <span class="flex-1 font-medium truncate" :class="v.id === localProduct.id ? 'text-indigo-700' : 'text-gray-700'">
                {{ v.name }}
              </span>
              <span class="text-xs tabular-nums text-gray-400">{{ eurToDkk(v.price_eur) }}</span>
              <span v-if="v.is_archived" class="text-[10px] font-semibold text-amber-600 bg-amber-50  px-1.5 py-0.5">Arkiveret</span>
              <span v-else-if="v.id === localProduct.id" class="text-[10px] font-semibold text-indigo-600">Denne</span>
              <span class="text-xs text-gray-300 tabular-nums">{{ fmt(v.created_at) }}</span>
            </div>
          </div>
        </div>

        <!-- Kanalstyring -->
        <div class="border-t border-gray-100 bg-slate-50/60">
          <!-- Tab bar -->
          <div class="flex items-center gap-0 px-8 pt-5 pb-0 border-b border-gray-200">
            <h4 class="text-xs font-bold text-gray-400 uppercase tracking-widest mr-6 pb-3 flex items-center gap-2 whitespace-nowrap">
              <span class="h-3.5 w-0.5  bg-slate-300" />
              Kanalstyring
            </h4>
            <button
              v-for="ch in CHANNELS"
              :key="ch.key"
              @click.stop="activeChannel = ch.key"
              class="relative pb-3 px-4 text-sm font-medium transition-colors whitespace-nowrap flex items-center gap-2"
              :class="activeChannel === ch.key
                ? 'text-gray-900'
                : 'text-gray-400 hover:text-gray-600'"
            >
              {{ ch.label }}
              <span
                class="inline-flex items-center justify-center  px-1.5 py-0.5 text-[10px] font-bold tabular-nums min-w-[18px]"
                :class="placementsFor(ch.key).length
                  ? ch.badge
                  : 'bg-gray-100 text-gray-400'"
              >{{ placementsFor(ch.key).length }}</span>
              <!-- Active underline -->
              <span v-if="activeChannel === ch.key" class="absolute bottom-0 left-0 right-0 h-0.5 bg-[#E30613] rounded-t-full" />
            </button>
          </div>

          <!-- Active channel panel -->
          <div class="px-8 py-5">
            <template v-for="ch in CHANNELS" :key="ch.key">
              <div v-if="activeChannel === ch.key">
                <!-- Placements list -->
                <div class="space-y-2 mb-3">
                  <div v-if="!placementsFor(ch.key).length && addingChannel !== ch.key"
                    class="text-sm text-gray-400 italic">
                    Ingen placeringer for {{ ch.label }} endnu.
                  </div>

                  <div v-for="p in placementsFor(ch.key)" :key="p.id">
                    <!-- View -->
                    <div v-if="editingPlacementId !== p.id"
                      class="group/pl flex items-center gap-4 bg-white border border-gray-100 hover:border-gray-200 px-4 py-3 transition-all">
                      <div class="min-w-0 flex-1 flex items-center gap-6">
                        <div class="min-w-[160px]">
                          <div class="text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-0.5">Titel</div>
                          <div class="text-sm font-medium text-gray-800 truncate">{{ p.title || '–' }}</div>
                        </div>
                        <div class="min-w-0 flex-1">
                          <div class="text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-0.5">URL</div>
                          <a v-if="p.url" :href="p.url" target="_blank" rel="noopener noreferrer"
                            class="text-sm text-[#E30613] hover:underline truncate block" @click.stop>
                            {{ p.url }}
                          </a>
                          <span v-else class="text-sm text-gray-400">–</span>
                        </div>
                      </div>
                      <div class="flex gap-1 opacity-0 group-hover/pl:opacity-100 transition-opacity flex-shrink-0">
                        <button @click.stop="startEditPlacement(p)" class="p-1.5 rounded-md text-gray-400 hover:text-[#E30613] hover:bg-red-50 transition-colors"><Pencil :size="13" /></button>
                        <button @click.stop="deletePlacement(p)" class="p-1.5 rounded-md text-gray-400 hover:text-red-500 hover:bg-red-50 transition-colors"><Trash2 :size="13" /></button>
                      </div>
                    </div>

                    <!-- Edit inline -->
                    <div v-else class="rounded-lg border border-[#E30613]/30 bg-red-50/20 px-4 py-3 flex items-end gap-3">
                      <div class="flex-1">
                        <div class="text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-1">Titel</div>
                        <input v-model="editPlacementForm.title" class="input-field text-sm" placeholder="Titel" />
                      </div>
                      <div class="flex-1">
                        <div class="text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-1">URL</div>
                        <input v-model="editPlacementForm.url" type="url" class="input-field text-sm" placeholder="https://…" />
                      </div>
                      <div class="flex gap-2 flex-shrink-0 pb-0.5">
                        <button @click="savePlacement(p)" :disabled="savingPlacement" class="btn-primary text-xs py-2 px-3">{{ savingPlacement ? '…' : 'Gem' }}</button>
                        <button @click="cancelEditPlacement" class="btn-ghost text-xs py-2 px-3">Annuller</button>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Add form -->
                <div v-if="addingChannel === ch.key" class="rounded-lg border border-[#E30613]/30 bg-red-50/20 px-4 py-3 flex items-end gap-3 mb-3">
                  <div class="flex-1">
                    <div class="text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-1">Titel</div>
                    <input v-model="addForm.title" class="input-field text-sm" placeholder="Titel" />
                  </div>
                  <div class="flex-1">
                    <div class="text-[10px] font-semibold text-gray-400 uppercase tracking-wider mb-1">URL</div>
                    <input v-model="addForm.url" type="url" class="input-field text-sm" placeholder="https://…" />
                  </div>
                  <div class="flex gap-2 flex-shrink-0 pb-0.5">
                    <button @click="addPlacement(ch.key)" :disabled="savingPlacement" class="btn-primary text-xs py-2 px-3">{{ savingPlacement ? '…' : 'Tilføj' }}</button>
                    <button @click="addingChannel = null" class="btn-ghost text-xs py-2 px-3">Annuller</button>
                  </div>
                </div>

                <button v-if="addingChannel !== ch.key" @click.stop="openAddPlacement(ch.key)"
                  class="border border-dashed border-gray-200 px-4 py-2 text-xs text-gray-400 hover:text-[#E30613] hover:border-[#E30613]/40 transition-colors flex items-center gap-1.5">
                  <Plus :size="13" /> Tilføj placering
                </button>
              </div>
            </template>
          </div>
        </div>

        <!-- Audit log -->
        <div class="px-8 py-3 bg-gray-50 border-t border-gray-100 flex items-center gap-8 text-xs text-gray-400">
          <span>Oprettet <span class="text-gray-600">{{ createdFormatted }}</span></span>
          <span v-if="localProduct.last_edited_at">
            Sidst redigeret af <span class="text-gray-600 font-medium">{{ lastEditorName }}</span>
            · {{ lastEditedFormatted }}
          </span>
        </div>
      </div>
    </td>
  </tr>

  <!-- ── Activity log popover ─────────────────────────────── -->
  <Teleport to="body">
    <div v-if="showLog" class="fixed inset-0 z-50" @click.self="showLog = false">
      <div
        class="absolute bg-white border border-gray-200 w-[380px] overflow-hidden"
        :style="logStyle"
      >
        <div class="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-gray-50">
          <div>
            <h4 class="text-sm font-semibold text-gray-900">Aktivitetslog</h4>
            <p class="text-xs text-gray-400 truncate max-w-[260px]">{{ localProduct.name }}</p>
          </div>
          <button @click="showLog = false" class="p-1.5  hover:bg-gray-200 text-gray-400 transition-colors">
            <X :size="15" />
          </button>
        </div>
        <div class="max-h-[360px] overflow-y-auto">
          <div v-if="loadingLog" class="py-10 flex items-center justify-center text-gray-400 text-sm">
            Henter log…
          </div>
          <div v-else-if="!logEntries.length" class="py-10 text-center text-sm text-gray-400 italic">
            Ingen aktivitet registreret endnu.
          </div>
          <ul v-else class="divide-y divide-gray-50">
            <li v-for="entry in logEntries" :key="entry.id" class="flex gap-3 px-4 py-3">
              <span class="mt-0.5 flex-shrink-0 h-6 w-6  flex items-center justify-center text-[11px]"
                :class="logBadgeClass(entry.action)">
                {{ logIcon(entry.action) }}
              </span>
              <div class="min-w-0">
                <p class="text-sm text-gray-800">{{ entry.description }}</p>
                <p class="text-xs text-gray-400 mt-0.5">
                  {{ entry.user_name }} · {{ fmt(entry.created_at) }}
                </p>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </Teleport>

  <!-- ── Version modal ────────────────────────────────────── -->
  <Teleport to="body">
    <div v-if="showVersionModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/25" @click.self="showVersionModal = false">
      <div class="bg-white border border-gray-200 w-full max-w-sm p-6">
        <h3 class="text-sm font-semibold text-gray-900 mb-1">Ny version</h3>
        <p class="text-xs text-gray-400 mb-4">Opretter en ny version i samme produktfamilie. Placeringer kopieres ikke.</p>
        <input
          v-model="versionName"
          ref="versionInput"
          class="input-field text-sm mb-4"
          placeholder="Produktnavn…"
          @keyup.enter="confirmCreateVersion"
          @keyup.escape="showVersionModal = false"
        />
        <div class="flex justify-end gap-2">
          <button @click="showVersionModal = false" class="btn-ghost">Annuller</button>
          <button @click="confirmCreateVersion" :disabled="creatingVersion || !versionName.trim()" class="btn-primary">
            {{ creatingVersion ? 'Opretter…' : 'Opret version' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>

  <!-- ── Duplicate modal ────────────────────────────────────── -->
  <Teleport to="body">
    <div v-if="showDuplicateModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/25" @click.self="showDuplicateModal = false">
      <div class="bg-white border border-gray-200 w-full max-w-sm p-6">
        <h3 class="text-sm font-semibold text-gray-900 mb-1">Dubler produkt</h3>
        <p class="text-xs text-gray-400 mb-4">Vælg navn til kopien — placements kopieres ikke.</p>
        <input
          v-model="duplicateName"
          ref="duplicateInput"
          class="input-field text-sm mb-4"
          placeholder="Produktnavn…"
          @keyup.enter="confirmDuplicate"
          @keyup.escape="showDuplicateModal = false"
        />
        <div class="flex justify-end gap-2">
          <button @click="showDuplicateModal = false" class="btn-ghost">Annuller</button>
          <button @click="confirmDuplicate" :disabled="duplicating || !duplicateName.trim()" class="btn-primary">
            {{ duplicating ? 'Kopierer…' : 'Dubler' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { ref, computed, nextTick } from 'vue'
import { ChevronDown, Copy, Pencil, Trash2, Plus, ClipboardCopy, X, History, Archive, GitBranch } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase.js'
import { useCurrency } from '@/composables/useCurrency.js'
import { useActivityLog } from '@/composables/useActivityLog.js'

const props = defineProps({
  product:   { type: Object, required: true },
  allThemes: { type: Array,  default: () => [] },
  isAdmin:   { type: Boolean, default: false },
  profile:   { type: Object, required: true }
})
const emit = defineEmits(['deleted', 'duplicated', 'updated', 'archived'])

const { eurToDkk } = useCurrency()
const { log, fetchLog } = useActivityLog(props.profile)

const CHANNELS = [
  { key: 'landingpage', label: 'LP',    badge: 'bg-blue-50 text-blue-700' },
  { key: 'some',        label: 'SoMe',  badge: 'bg-violet-50 text-violet-600' },
  { key: 'print',       label: 'Print', badge: 'bg-amber-50 text-amber-600' },
  { key: 'paid',        label: 'Paid',  badge: 'bg-emerald-50 text-emerald-600' }
]

const expanded        = ref(false)
const localProduct    = ref({ ...props.product })
const localPlacements = ref([...(props.product.placements ?? [])])
const activeChannel   = ref('landingpage')

const versions        = ref([])
const loadingVersions = ref(false)

const isActive = computed(() => localPlacements.value.length > 0)

async function toggle() {
  expanded.value = !expanded.value
  if (expanded.value && localProduct.value.product_family_id) {
    loadingVersions.value = true
    const { data } = await supabase.from('products')
      .select('id, name, version_number, price_eur, created_at, is_archived')
      .eq('product_family_id', localProduct.value.product_family_id)
      .order('version_number', { ascending: true })
    versions.value = data ?? []
    loadingVersions.value = false
  }
}

function placementsFor(ch) { return localPlacements.value.filter(p => p.channel === ch) }
function countFor(ch)      { return placementsFor(ch).length }

const copied = ref(null)
function copyText(text, key) {
  if (!text) return
  navigator.clipboard.writeText(text).then(() => {
    copied.value = key
    setTimeout(() => { copied.value = null }, 1500)
  })
}

const editingRowName = ref(false)
const rowNameDraft   = ref('')
const rowNameInput   = ref(null)
const savingRowName  = ref(false)

function startEditRowName() {
  rowNameDraft.value   = localProduct.value.name
  editingRowName.value = true
  nextTick(() => rowNameInput.value?.focus())
}

async function saveRowName() {
  if (!rowNameDraft.value.trim()) return
  savingRowName.value = true
  const oldName = localProduct.value.name
  const { data, error } = await supabase.from('products')
    .update({ name: rowNameDraft.value.trim(), last_edited_by: props.profile.id, last_edited_at: new Date().toISOString() })
    .eq('id', localProduct.value.id).select().single()
  if (!error) {
    localProduct.value = { ...localProduct.value, name: data.name, last_edited_at: data.last_edited_at }
    editingRowName.value = false
    emit('updated', localProduct.value)
    log(localProduct.value.id, 'name_updated', `Navn ændret fra "${oldName}" til "${data.name}"`)
  }
  savingRowName.value = false
}

const editingMeta = ref(false)
const metaForm    = ref({})
const savingMeta  = ref(false)
const metaError   = ref('')

function startEditMeta() {
  metaForm.value = {
    unicat_name:   localProduct.value.unicat_name   ?? '',
    description:   localProduct.value.description   ?? '',
    price_example: localProduct.value.price_example ?? '',
    price_eur:     localProduct.value.price_eur      ?? 0,
    themeIds:      (localProduct.value.themes ?? []).map(t => t.id)
  }
  editingMeta.value = true
  metaError.value   = ''
}
function cancelEditMeta() { editingMeta.value = false }

async function saveMeta() {
  savingMeta.value = true
  metaError.value  = ''
  const { data, error } = await supabase.from('products')
    .update({
      unicat_name:    metaForm.value.unicat_name    || null,
      description:    metaForm.value.description    || null,
      price_example:  metaForm.value.price_example  || null,
      price_eur:      metaForm.value.price_eur,
      last_edited_by: props.profile.id,
      last_edited_at: new Date().toISOString()
    })
    .eq('id', localProduct.value.id).select().single()

  if (error) { metaError.value = error.message; savingMeta.value = false; return }

  await supabase.from('product_themes').delete().eq('product_id', localProduct.value.id)
  if (metaForm.value.themeIds.length) {
    await supabase.from('product_themes').insert(
      metaForm.value.themeIds.map(tid => ({ product_id: localProduct.value.id, theme_id: tid }))
    )
  }

  const newThemes = props.allThemes.filter(t => metaForm.value.themeIds.includes(t.id))
  localProduct.value = { ...data, themes: newThemes, placements: localPlacements.value, editor: localProduct.value.editor }
  editingMeta.value = false
  savingMeta.value  = false
  emit('updated', localProduct.value)
  log(localProduct.value.id, 'product_updated', 'Stamdata opdateret')
}

async function confirmDelete() {
  if (!confirm(`Slet "${localProduct.value.name}" permanent? Kan ikke fortrydes.`)) return
  const { error } = await supabase.from('products').delete().eq('id', localProduct.value.id)
  if (!error) emit('deleted', localProduct.value.id)
  else alert('Fejl: ' + error.message)
}

async function confirmArchive() {
  if (!confirm(`Arkivér "${localProduct.value.name}"?\nProduktet kan genaktiveres fra arkiv-fanen.`)) return
  const now = new Date().toISOString()
  const { error } = await supabase.from('products')
    .update({ is_archived: true, archived_at: now, archived_by: props.profile.id })
    .eq('id', localProduct.value.id)
  if (!error) {
    log(localProduct.value.id, 'product_updated', 'Produkt arkiveret')
    emit('archived', localProduct.value.id)
  } else alert('Fejl: ' + error.message)
}

const addingChannel   = ref(null)
const addForm         = ref({ title: '', url: '' })
const savingPlacement = ref(false)

function openAddPlacement(channel) {
  addingChannel.value      = channel
  addForm.value            = { title: '', url: '' }
  editingPlacementId.value = null
}
async function addPlacement(channel) {
  savingPlacement.value = true
  const { data, error } = await supabase.from('placements')
    .insert({ product_id: localProduct.value.id, channel, title: addForm.value.title, url: addForm.value.url })
    .select().single()
  if (!error) {
    localPlacements.value.push(data)
    addingChannel.value = null
    const ch = CHANNELS.find(c => c.key === channel)
    log(localProduct.value.id, 'placement_added', `Placering tilføjet på ${ch?.label ?? channel}${addForm.value.title ? ': ' + addForm.value.title : ''}`)
  } else alert('Fejl: ' + error.message)
  savingPlacement.value = false
}

const editingPlacementId = ref(null)
const editPlacementForm  = ref({ title: '', url: '' })

function startEditPlacement(p) {
  addingChannel.value      = null
  editingPlacementId.value = p.id
  editPlacementForm.value  = { title: p.title, url: p.url }
}
function cancelEditPlacement() { editingPlacementId.value = null }

async function savePlacement(p) {
  savingPlacement.value = true
  const { data, error } = await supabase.from('placements')
    .update({ title: editPlacementForm.value.title, url: editPlacementForm.value.url })
    .eq('id', p.id).select().single()
  if (!error) {
    const idx = localPlacements.value.findIndex(x => x.id === p.id)
    if (idx !== -1) localPlacements.value[idx] = data
    editingPlacementId.value = null
    const ch = CHANNELS.find(c => c.key === p.channel)
    log(localProduct.value.id, 'placement_updated', `Placering opdateret på ${ch?.label ?? p.channel}`)
  } else alert('Fejl: ' + error.message)
  savingPlacement.value = false
}

async function deletePlacement(p) {
  if (!confirm('Slet denne placering?')) return
  const { error } = await supabase.from('placements').delete().eq('id', p.id)
  if (!error) {
    localPlacements.value = localPlacements.value.filter(x => x.id !== p.id)
    const ch = CHANNELS.find(c => c.key === p.channel)
    log(localProduct.value.id, 'placement_deleted', `Placering slettet fra ${ch?.label ?? p.channel}${p.title ? ': ' + p.title : ''}`)
  } else alert('Fejl: ' + error.message)
}

const showDuplicateModal = ref(false)
const duplicateName      = ref('')
const duplicating        = ref(false)
const duplicateInput     = ref(null)

function openDuplicateModal() {
  duplicateName.value      = localProduct.value.name + ' (kopi)'
  showDuplicateModal.value = true
  nextTick(() => duplicateInput.value?.select())
}

async function confirmDuplicate() {
  if (!duplicateName.value.trim()) return
  duplicating.value = true
  const { data: newProduct, error } = await supabase.from('products')
    .insert({
      name:           duplicateName.value.trim(),
      unicat_name:    localProduct.value.unicat_name,
      description:    localProduct.value.description,
      price_example:  localProduct.value.price_example,
      price_eur:      localProduct.value.price_eur,
      version_number: 1,
      last_edited_by: props.profile.id,
      last_edited_at: new Date().toISOString()
    }).select().single()

  if (error) { alert('Fejl: ' + error.message); duplicating.value = false; return }

  const themeIds = (localProduct.value.themes ?? []).map(t => t.id)
  if (themeIds.length) {
    await supabase.from('product_themes').insert(
      themeIds.map(tid => ({ product_id: newProduct.id, theme_id: tid }))
    )
  }

  await supabase.from('products').update({ product_family_id: newProduct.id }).eq('id', newProduct.id)
  const duped = { ...newProduct, product_family_id: newProduct.id, themes: props.allThemes.filter(t => themeIds.includes(t.id)), placements: [] }
  emit('duplicated', duped)
  log(newProduct.id, 'product_created', `Produkt dubleret fra "${localProduct.value.name}"`)
  showDuplicateModal.value = false
  duplicating.value        = false
}

const showVersionModal  = ref(false)
const versionName       = ref('')
const versionInput      = ref(null)
const creatingVersion   = ref(false)

function openVersionModal() {
  const nextNum = Math.max(...(versions.value.map(v => v.version_number ?? 1)), 1) + 1
  versionName.value      = `${localProduct.value.name} (v${nextNum})`
  showVersionModal.value = true
  nextTick(() => versionInput.value?.select())
}

async function confirmCreateVersion() {
  if (!versionName.value.trim()) return
  creatingVersion.value = true

  const nextNum = Math.max(...(versions.value.map(v => v.version_number ?? 1)), 1) + 1
  const familyId = localProduct.value.product_family_id ?? localProduct.value.id

  const { data: newProduct, error } = await supabase.from('products')
    .insert({
      name:              versionName.value.trim(),
      unicat_name:       localProduct.value.unicat_name,
      description:       localProduct.value.description,
      price_example:     localProduct.value.price_example,
      price_eur:         localProduct.value.price_eur,
      product_family_id: familyId,
      version_number:    nextNum,
      last_edited_by:    props.profile.id,
      last_edited_at:    new Date().toISOString()
    })
    .select()
    .single()

  if (error) { alert('Fejl: ' + error.message); creatingVersion.value = false; return }

  const themeIds = (localProduct.value.themes ?? []).map(t => t.id)
  if (themeIds.length) {
    await supabase.from('product_themes').insert(themeIds.map(tid => ({ product_id: newProduct.id, theme_id: tid })))
  }

  log(newProduct.id, 'product_created', `Ny version v${nextNum} oprettet fra "${localProduct.value.name}"`)
  emit('duplicated', { ...newProduct, themes: props.allThemes.filter(t => themeIds.includes(t.id)), placements: [] })
  versions.value = [...versions.value, { id: newProduct.id, name: newProduct.name, version_number: nextNum, price_eur: newProduct.price_eur, created_at: newProduct.created_at, is_archived: false }]
  showVersionModal.value = false
  creatingVersion.value  = false
}

const lastEditorName = computed(() =>
  localProduct.value.editor?.full_name || localProduct.value.editor?.email || 'Ukendt'
)
function fmt(iso) {
  if (!iso) return '–'
  return new Date(iso).toLocaleString('da-DK', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}
const lastEditedFormatted = computed(() => fmt(localProduct.value.last_edited_at))
const createdFormatted    = computed(() => fmt(localProduct.value.created_at))

const showLog    = ref(false)
const loadingLog = ref(false)
const logEntries = ref([])
const logStyle   = ref({})

async function openLog(event) {
  const rect = event.currentTarget.getBoundingClientRect()
  const top  = Math.min(rect.bottom + 8, window.innerHeight - 420)
  const left = Math.min(rect.left, window.innerWidth - 396)
  logStyle.value = { top: top + 'px', left: left + 'px' }

  showLog.value    = true
  loadingLog.value = true
  logEntries.value = await fetchLog(localProduct.value.id)
  loadingLog.value = false
}

const ACTION_META = {
  product_created:   { icon: '✦', cls: 'bg-emerald-50 text-emerald-600' },
  product_updated:   { icon: '✎', cls: 'bg-blue-50 text-blue-600' },
  name_updated:      { icon: '✎', cls: 'bg-blue-50 text-blue-600' },
  placement_added:   { icon: '+', cls: 'bg-violet-50 text-violet-600' },
  placement_updated: { icon: '✎', cls: 'bg-amber-50 text-amber-600' },
  placement_deleted: { icon: '✕', cls: 'bg-red-50 text-red-500' },
}

function logIcon(action)       { return ACTION_META[action]?.icon ?? '·' }
function logBadgeClass(action) { return ACTION_META[action]?.cls  ?? 'bg-gray-100 text-gray-500' }
</script>
