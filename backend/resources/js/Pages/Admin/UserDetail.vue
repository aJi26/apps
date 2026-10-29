<script setup>
import { ref, computed } from 'vue';
import { Head, router } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import PotretDetailModal from '@/Components/PotretDetailModal.vue';
import EmptyState from '@/Components/EmptyState.vue';

const props = defineProps({
  userId: { type: [String, Number], required: true },
  user: { type: Object, required: true },
  goals: { type: Array, default: () => [] },
  notes: { type: Array, default: () => [] },
  wishlists: { type: Array, default: () => [] },
  userPotrets: { type: Array, default: () => [] },
  userPhotoDumps: { type: Array, default: () => [] },
  activityHistory: { type: Array, default: () => [] },
});

const goBack = () => router.get('/admin/users');

const activeTab = ref('Overview');
const tabs = ['Overview', 'Potret', 'Dump', 'Notes', 'Goals', 'Wishlist', 'Activity'];

// Filter Bulan Potret
const selectedMonth = ref('All');
const availableMonths = computed(() => {
  const months = new Set(props.userPotrets.map(p => p.month_year).filter(Boolean));
  return ['All', ...Array.from(months)];
});

const filteredPotrets = computed(() => {
  if (selectedMonth.value === 'All') return props.userPotrets;
  return props.userPotrets.filter(p => p.month_year === selectedMonth.value);
});

// Goals filter
const goalFilter = ref('Active');
const filteredGoals = computed(() => {
  if (goalFilter.value === 'All') return props.goals;
  return props.goals.filter(g => g.status.toLowerCase() === goalFilter.value.toLowerCase());
});

// Filter Aktivitas Interaktif
const activityTypeFilter = ref('All');
const filteredActivities = computed(() => {
  if (activityTypeFilter.value === 'All') return props.activityHistory;
  return props.activityHistory.filter(act => 
    (act.type || 'Other').toLowerCase() === activityTypeFilter.value.toLowerCase()
  );
});

// Potret modal state
const isModalOpen = ref(false);
const selectedPhotoIndex = ref(0);

const openPhotoModal = (index) => {
  selectedPhotoIndex.value = index;
  isModalOpen.value = true;
};

const nextPhoto = () => {
  selectedPhotoIndex.value = selectedPhotoIndex.value < filteredPotrets.value.length - 1 ? selectedPhotoIndex.value + 1 : 0;
};

const prevPhoto = () => {
  selectedPhotoIndex.value = selectedPhotoIndex.value > 0 ? selectedPhotoIndex.value - 1 : filteredPotrets.value.length - 1;
};

const deletePhoto = (photoId) => {
  if (confirm('Apakah Anda yakin ingin menghapus foto potret ini?')) {
    router.delete(`/admin/portraits/${photoId}`, {
      preserveScroll: true,
      onSuccess: () => {
        isModalOpen.value = false;
        if (selectedPhotoIndex.value > 0) {
          selectedPhotoIndex.value--;
        }
      },
    });
  }
};

// Dump modal state
const isDumpModalOpen = ref(false);
const selectedDumpIndex = ref(0);

const openDumpModal = (index) => {
  selectedDumpIndex.value = index;
  isDumpModalOpen.value = true;
};

const nextDump = () => {
  selectedDumpIndex.value = selectedDumpIndex.value < props.userPhotoDumps.length - 1 ? selectedDumpIndex.value + 1 : 0;
};

const prevDump = () => {
  selectedDumpIndex.value = selectedDumpIndex.value > 0 ? selectedDumpIndex.value - 1 : props.userPhotoDumps.length - 1;
};

const deleteDump = (photoId) => {
  if (confirm('Apakah Anda yakin ingin menghapus foto photo dump ini?')) {
    router.delete(`/admin/photo-dumps/${photoId}`, {
      preserveScroll: true,
      onSuccess: () => {
        isDumpModalOpen.value = false;
        if (selectedDumpIndex.value > 0) {
          selectedDumpIndex.value--;
        }
      },
    });
  }
};

// State untuk Modal Detail Notes, Wishlist & Activity
const selectedNote = ref(null);
const selectedWishlist = ref(null);
const selectedActivity = ref(null);
</script>

<template>
  <Head :title="`${user.name} — Her Space User Detail`" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <div class="p-6 overflow-y-auto flex-1 space-y-5">
        
        <!-- Header Nav -->
        <div class="flex items-center justify-between">
          <button @click="goBack" type="button" class="text-[#2C3E35] hover:opacity-70 transition p-1 -ml-1 cursor-pointer">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
          </button>
          <h1 class="text-lg font-serif font-bold text-[#2C3E35]">User Detail</h1>
          <span 
            class="px-2.5 py-0.5 rounded-full text-[10px] font-bold"
            :class="user.status === 'Active' ? 'bg-[#E8ECE9] text-[#2C3E35]' : 'bg-[#FEEAE6] text-[#D96B5B]'"
          >
            {{ user.status }}
          </span>
        </div>

        <!-- User Profile Card -->
        <div class="flex items-center gap-4 bg-white border border-[#EAE7E1] rounded-3xl p-4 shadow-xs">
          <img :src="user.avatar" alt="Avatar" class="w-14 h-14 rounded-full object-cover shadow-xs border border-[#EAE7E1]">
          <div class="min-w-0 flex-1">
            <h2 class="text-base font-bold text-[#2C3E35] font-serif truncate">{{ user.name }}</h2>
            <p class="text-xs text-[#8A9992] truncate mt-0.5">{{ user.email }}</p>
          </div>
        </div>

        <!-- Pill Tabs Navigation -->
        <div class="flex bg-white/80 border border-[#EAE7E1] p-1 rounded-2xl overflow-x-auto shadow-xs">
          <button 
            v-for="tab in tabs" 
            :key="tab"
            @click="activeTab = tab"
            type="button"
            class="flex-1 min-w-[62px] py-2 text-xs font-semibold rounded-xl transition text-center whitespace-nowrap cursor-pointer"
            :class="activeTab === tab ? 'bg-[#2C3E35] text-white shadow-sm' : 'text-[#8A9992] hover:text-[#2C3E35]'"
          >
            {{ tab }}
          </button>
        </div>

        <!-- TAB 1: OVERVIEW -->
        <div v-if="activeTab === 'Overview'" class="space-y-5">
          <div>
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider mb-3">Personal Information</h3>
            <div class="bg-white border border-[#EAE7E1] rounded-2xl p-4 space-y-3.5 shadow-xs">
              <div class="flex items-center gap-3.5">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 002-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                </div>
                <div>
                  <span class="text-[10px] text-[#8A9992] font-medium block">Birthday</span>
                  <span class="text-xs font-bold text-[#2C3E35]">{{ user.birthday }}</span>
                </div>
              </div>
              <div class="flex items-center gap-3.5">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <div>
                  <span class="text-[10px] text-[#8A9992] font-medium block">Joined Her Space</span>
                  <span class="text-xs font-bold text-[#2C3E35]">{{ user.joined }}</span>
                </div>
              </div>
              <div class="flex items-center gap-3.5">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"/></svg>
                </div>
                <div>
                  <span class="text-[10px] text-[#8A9992] font-medium block">Last Login</span>
                  <span class="text-xs font-bold text-[#2C3E35]">{{ user.lastLogin }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- TAB 2: POTRET GALLERY -->
        <div v-else-if="activeTab === 'Potret'" class="space-y-4">
          <div class="flex justify-between items-center">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Potret Gallery</h3>
            <select 
              v-model="selectedMonth" 
              class="px-2.5 py-1 bg-white border border-[#EAE7E1] rounded-xl text-[11px] font-semibold text-[#2C3E35] focus:outline-none cursor-pointer"
            >
              <option v-for="m in availableMonths" :key="m" :value="m">{{ m }}</option>
            </select>
          </div>

          <div v-if="filteredPotrets.length > 0" class="grid grid-cols-2 gap-3">
            <div 
              v-for="(item, index) in filteredPotrets" 
              :key="item.id" 
              @click="openPhotoModal(index)"
              class="group relative aspect-square rounded-2xl overflow-hidden border border-[#EAE7E1] bg-white shadow-xs cursor-pointer hover:shadow-md transition"
            >
              <img :src="item.url" class="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105">
              <div class="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/60 to-transparent text-white text-[10px] p-2 text-center font-medium">
                {{ item.date }}
              </div>
            </div>
          </div>

          <EmptyState v-else title="No Potret Photos" description="User hasn't uploaded any daily portraits yet." />
        </div>

        <!-- TAB 3: DUMP -->
        <div v-else-if="activeTab === 'Dump'" class="space-y-4">
          <div class="flex justify-between items-center">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Photo Dump Gallery</h3>
            <span class="text-xs text-[#8A9992]">{{ userPhotoDumps.length }} photos</span>
          </div>

          <div v-if="userPhotoDumps.length > 0" class="grid grid-cols-2 gap-3">
            <div 
              v-for="(item, index) in userPhotoDumps" 
              :key="item.id" 
              @click="openDumpModal(index)"
              class="group relative aspect-square rounded-2xl overflow-hidden border border-[#EAE7E1] bg-white shadow-xs cursor-pointer hover:shadow-md transition"
            >
              <img :src="item.image_url" class="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105" alt="Photo Dump">

              <div class="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/60 to-transparent text-white text-[10px] p-2 text-center font-medium pointer-events-none">
                {{ item.date }}
              </div>
            </div>
          </div>

          <EmptyState v-else title="No Photo Dumps" description="User hasn't uploaded any photo dumps yet." />
        </div>

        <!-- TAB 4: NOTES -->
        <div v-else-if="activeTab === 'Notes'" class="space-y-3">
          <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider mb-2">User Notes</h3>
          <div v-if="notes.length > 0" class="space-y-3">
            <div 
              v-for="note in notes" 
              :key="note.id" 
              @click="selectedNote = note"
              class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs cursor-pointer hover:border-[#2C3E35]/40 transition"
            >
              <div class="flex justify-between items-start mb-1">
                <h4 class="text-xs font-bold text-[#2C3E35]">{{ note.title || 'Untitled Note' }}</h4>
                <span class="text-[10px] text-[#8A9992]">{{ note.date }}</span>
              </div>
              <p class="text-xs text-gray-600 line-clamp-2 mt-1">{{ note.content }}</p>
            </div>
          </div>
          <EmptyState v-else title="No Notes Found" description="User hasn't written any notes yet." />
        </div>

        <!-- TAB 5: GOALS -->
        <div v-else-if="activeTab === 'Goals'" class="space-y-4">
          <div class="flex justify-between items-center">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Goals</h3>
            <div class="flex gap-1.5">
              <button 
                v-for="pill in ['Active', 'Completed', 'All']" 
                :key="pill"
                @click="goalFilter = pill"
                type="button"
                class="px-2.5 py-1 rounded-full text-[10px] font-semibold transition cursor-pointer"
                :class="goalFilter === pill ? 'bg-[#2C3E35] text-white shadow-xs' : 'bg-white border border-[#EAE7E1] text-[#8A9992] hover:text-[#2C3E35]'"
              >
                {{ pill }}
              </button>
            </div>
          </div>

          <div v-if="filteredGoals.length > 0" class="space-y-3">
            <div 
              v-for="goal in filteredGoals" 
              :key="goal.id" 
              class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs hover:border-[#2C3E35]/30 transition"
            >
              <div class="flex items-center gap-3 mb-2.5">
                <div class="w-8 h-8 rounded-xl bg-[#E8ECE9] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <span class="text-sm">🎯</span>
                </div>
                <div class="flex-1 min-w-0">
                  <h4 class="text-xs font-bold text-[#2C3E35] truncate">{{ goal.title }}</h4>
                  <p class="text-[10px] text-[#8A9992]">{{ goal.target_date }}</p>
                </div>
                <span class="text-xs font-bold text-[#2C3E35]">{{ goal.progress }}</span>
              </div>
              <div class="w-full bg-[#FAF7F2] h-2.5 rounded-full overflow-hidden border border-[#EAE7E1]">
                <div class="bg-[#2C3E35] h-full transition-all duration-500 rounded-full" :style="{ width: goal.progress }"></div>
              </div>
            </div>
          </div>

          <EmptyState v-else title="No Goals Found" description="No goals matching the selected filter." />
        </div>

        <!-- TAB 6: WISHLIST -->
        <div v-else-if="activeTab === 'Wishlist'" class="space-y-3">
          <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider mb-2">User Wishlist</h3>
          <div v-if="wishlists.length > 0" class="space-y-3">
            <div 
              v-for="item in wishlists" 
              :key="item.id" 
              @click="selectedWishlist = item"
              class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs cursor-pointer hover:border-[#2C3E35]/40 transition flex items-center justify-between"
            >
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-[#FEF3C7] text-[#D97706] flex items-center justify-center shrink-0">
                  <span class="text-base">🎁</span>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">{{ item.title }}</h4>
                  <p class="text-[10px] text-[#8A9992] mt-0.5">{{ item.category || 'General' }} • {{ item.price ? 'Rp ' + item.price : 'No Price' }}</p>
                </div>
              </div>
              <span class="px-2.5 py-1 rounded-full text-[9px] font-bold bg-[#E8ECE9] text-[#2C3E35]">
                {{ item.status || 'Wanted' }}
              </span>
            </div>
          </div>
          <EmptyState v-else title="No Wishlist Found" description="User hasn't added any wishlists yet." />
        </div>

        <!-- TAB 7: ACTIVITY HISTORY -->
        <div v-else-if="activeTab === 'Activity'" class="space-y-3">
          <div class="flex justify-between items-center mb-1">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Activity History</h3>
            
            <select 
              v-model="activityTypeFilter" 
              class="px-2.5 py-1 bg-white border border-[#EAE7E1] rounded-xl text-[10px] font-semibold text-[#2C3E35] focus:outline-none cursor-pointer"
            >
              <option value="All">All Types</option>
              <option value="Check-in">Check-in</option>
              <option value="Photo Dump">Photo Dump</option>
              <option value="Goals">Goals</option>
              <option value="Notes">Notes</option>
              <option value="Wishlist">Wishlist</option>
              <option value="Other">Other</option>
            </select>
          </div>

          <div v-if="filteredActivities.length > 0" class="space-y-2.5">
            <div 
              v-for="item in filteredActivities" 
              :key="item.id" 
              @click="selectedActivity = item"
              class="flex items-center justify-between p-3 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs cursor-pointer hover:border-[#2C3E35]/40 transition"
            >
              <div class="flex items-center gap-3 min-w-0">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-sm shrink-0">
                  <span>🌿</span>
                </div>
                <div class="min-w-0">
                  <p class="text-xs font-bold text-[#2C3E35] truncate">{{ item.action }}</p>
                  <p class="text-[10px] text-[#8A9992]">{{ item.date }}</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992] shrink-0 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>
          </div>

          <EmptyState v-else title="No Activity Log" description="No activity matches the selected filter." />
        </div>

      </div>

      <BottomNav />
    </div>

    <!-- Modal Detail Foto Potret -->
    <PotretDetailModal
      :is-open="isModalOpen"
      :photo="filteredPotrets[selectedPhotoIndex]"
      :photos="filteredPotrets"
      :current-index="selectedPhotoIndex"
      @close="isModalOpen = false"
      @prev="prevPhoto"
      @next="nextPhoto"
      @delete="deletePhoto"
    />

    <!-- Modal Detail Foto Dump -->
    <PotretDetailModal
      :is-open="isDumpModalOpen"
      :photo="userPhotoDumps[selectedDumpIndex]"
      :photos="userPhotoDumps"
      :current-index="selectedDumpIndex"
      @close="isDumpModalOpen = false"
      @prev="prevDump"
      @next="nextDump"
      @delete="deleteDump"
    />

    <!-- Modal Detail Note -->
    <div v-if="selectedNote" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl max-w-sm w-full p-6 space-y-4 shadow-xl">
        <h3 class="font-bold text-base text-[#2C3E35]">{{ selectedNote.title || 'Note Detail' }}</h3>
        <p class="text-xs text-gray-700 whitespace-pre-line leading-relaxed bg-[#FAF7F2] p-4 rounded-2xl border border-[#EAE7E1]">{{ selectedNote.content }}</p>
        <p class="text-[10px] text-[#8A9992]">Created at: {{ selectedNote.date }}</p>
        <button @click="selectedNote = null" class="w-full py-2.5 bg-[#2C3E35] text-white rounded-2xl text-xs font-bold cursor-pointer">
          Close
        </button>
      </div>
    </div>

    <!-- Modal Detail Wishlist -->
    <div v-if="selectedWishlist" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl max-w-sm w-full p-6 space-y-4 shadow-xl">
        <div class="flex justify-between items-center">
          <h3 class="font-bold text-base text-[#2C3E35]">{{ selectedWishlist.title }}</h3>
          <span class="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#E8ECE9] text-[#2C3E35]">{{ selectedWishlist.status }}</span>
        </div>
        <div class="bg-[#FAF7F2] p-4 rounded-2xl border border-[#EAE7E1] space-y-2 text-xs">
          <p><span class="font-semibold text-gray-500">Category:</span> {{ selectedWishlist.category || '-' }}</p>
          <p><span class="font-semibold text-gray-500">Price:</span> {{ selectedWishlist.price ? 'Rp ' + selectedWishlist.price : '-' }}</p>
          <p><span class="font-semibold text-gray-500">Description:</span> {{ selectedWishlist.description || '-' }}</p>
          <p v-if="selectedWishlist.url"><span class="font-semibold text-gray-500">Link:</span> <a :href="selectedWishlist.url" target="_blank" class="text-blue-600 underline truncate block">{{ selectedWishlist.url }}</a></p>
        </div>
        <button @click="selectedWishlist = null" class="w-full py-2.5 bg-[#2C3E35] text-white rounded-2xl text-xs font-bold cursor-pointer">
          Close
        </button>
      </div>
    </div>

    <!-- Modal Detail Aktivitas -->
    <div v-if="selectedActivity" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl max-w-sm w-full p-6 space-y-4 shadow-xl">
        <h3 class="font-bold text-base text-[#2C3E35]">Detail Aktivitas</h3>
        <p class="text-xs text-gray-700 font-medium">{{ selectedActivity.action }}</p>
        <div class="bg-[#FAF7F2] p-3 rounded-2xl border border-[#EAE7E1] text-[11px] text-[#8A9992]">
          Waktu: {{ selectedActivity.date }} ({{ selectedActivity.time }})
        </div>
        <button @click="selectedActivity = null" class="w-full py-2.5 bg-[#2C3E35] text-white rounded-2xl text-xs font-bold cursor-pointer">
          Close
        </button>
      </div>
    </div>
  </div>
</template>