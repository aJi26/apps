<script setup>
import { ref, computed } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import PotretDetailModal from '@/Components/PotretDetailModal.vue';
import EmptyState from '@/Components/EmptyState.vue';

const props = defineProps({
  user: {
    type: Object,
    required: true,
  },
  photos: {
    type: Array,
    default: () => [],
  },
});

const viewMode = ref('detail'); // 'detail' (Panel 11) or 'grid'
const activeIndex = ref(0);
const isModalOpen = ref(false);

const currentPhoto = computed(() => {
  if (props.photos.length === 0) return null;
  return props.photos[activeIndex.value] || props.photos[0];
});

const nextPhoto = () => {
  if (activeIndex.value < props.photos.length - 1) {
    activeIndex.value++;
  } else {
    activeIndex.value = 0;
  }
};

const prevPhoto = () => {
  if (activeIndex.value > 0) {
    activeIndex.value--;
  } else {
    activeIndex.value = props.photos.length - 1;
  }
};

const selectPhoto = (index) => {
  activeIndex.value = index;
  viewMode.value = 'detail';
};
</script>

<template>
  <Head :title="`${user.name}'s Potret Gallery`" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1 space-y-4">
        
        <!-- Header Nav (Panel 11) -->
        <div class="flex items-center justify-between">
          <Link href="/admin/daily-potret" class="text-[#2C3E35] p-1 -ml-1 hover:opacity-70 transition">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </Link>
          <h1 class="text-lg font-serif font-bold text-[#2C3E35]">Potret Gallery</h1>
          <div class="flex items-center gap-1">
            <button 
              @click="viewMode = viewMode === 'detail' ? 'grid' : 'detail'" 
              type="button"
              class="p-1.5 text-[#2C3E35] hover:bg-[#E8ECE9] rounded-xl transition"
              :title="viewMode === 'detail' ? 'Switch to Grid View' : 'Switch to Detail View'"
            >
              <svg v-if="viewMode === 'detail'" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
              <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            </button>
          </div>
        </div>

        <!-- MODE 1: DETAIL CAROUSEL (Panel 11) -->
        <div v-if="viewMode === 'detail' && currentPhoto" class="space-y-4 animate-in fade-in duration-200">
          
          <!-- Top Carousel Control: < 1 / 12 > -->
          <div class="flex items-center justify-between text-[#2C3E35] bg-white border border-[#EAE7E1] py-2 px-4 rounded-2xl shadow-xs">
            <button 
              @click="prevPhoto" 
              type="button" 
              class="p-1 text-[#2C3E35] hover:opacity-60 transition"
              title="Previous photo"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/></svg>
            </button>

            <span class="text-xs font-semibold tracking-wider text-[#2C3E35]">
              {{ activeIndex + 1 }} / {{ photos.length }}
            </span>

            <button 
              @click="nextPhoto" 
              type="button" 
              class="p-1 text-[#2C3E35] hover:opacity-60 transition"
              title="Next photo"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/></svg>
            </button>
          </div>

          <!-- Large Main Photo Frame (Panel 11) -->
          <div class="relative aspect-[3/4] w-full overflow-hidden rounded-[2.5rem] bg-gray-100 shadow-md border border-[#EAE7E1] group cursor-pointer" @click="isModalOpen = true">
            <img 
              :src="currentPhoto.image_url" 
              :alt="currentPhoto.date" 
              class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-102" 
            />
            
            <div class="absolute inset-x-0 bottom-0 h-20 bg-gradient-to-t from-black/60 to-transparent pointer-events-none"></div>
            <div class="absolute bottom-4 left-5 text-white">
              <p class="text-xs font-medium opacity-90">{{ currentPhoto.date }}</p>
              <p class="text-xs font-bold drop-shadow-xs">{{ currentPhoto.uploaded_at || currentPhoto.date }}</p>
            </div>
          </div>

          <!-- User Card & Action Buttons (Panel 11) -->
          <div class="bg-white border border-[#EAE7E1] rounded-3xl p-4 shadow-xs space-y-4">
            <div class="flex items-center gap-3">
              <img :src="user.avatar" alt="Avatar" class="w-11 h-11 rounded-full object-cover border border-[#EAE7E1]">
              <div>
                <h4 class="text-sm font-bold text-[#2C3E35] font-serif">{{ user.name }}</h4>
                <p class="text-[11px] text-[#8A9992]">{{ currentPhoto.uploaded_at || currentPhoto.date }}</p>
              </div>
            </div>

            <div class="flex gap-2.5">
              <a
                :href="currentPhoto.image_url"
                target="_blank"
                download
                class="flex flex-1 items-center justify-center gap-1.5 rounded-2xl border border-[#EAE7E1] bg-[#FAF7F2] py-3 text-xs font-semibold text-[#2C3E35] transition hover:bg-[#E8ECE9]"
              >
                <svg class="h-4 w-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                Download
              </a>

              <Link
                :href="'/admin/users/' + user.id"
                class="flex flex-1 items-center justify-center gap-1.5 rounded-2xl bg-[#2C3E35] py-3 text-xs font-bold text-white transition hover:bg-[#202e27] shadow-sm"
              >
                View Details
              </Link>
            </div>
          </div>

        </div>

        <!-- MODE 2: GRID VIEW (Panel 6 Style) -->
        <div v-else-if="viewMode === 'grid' && photos.length > 0" class="space-y-3 animate-in fade-in duration-200">
          <div class="flex items-center justify-between">
            <span class="text-xs font-bold text-[#2C3E35] uppercase tracking-wider font-serif">All Photos</span>
            <span class="text-xs text-[#8A9992]">{{ photos.length }} photos</span>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div
              v-for="(photo, idx) in photos"
              :key="photo.id"
              @click="selectPhoto(idx)"
              class="group relative aspect-square overflow-hidden rounded-2xl bg-white border border-[#EAE7E1] shadow-xs cursor-pointer hover:shadow-md transition"
            >
              <img :src="photo.image_url" :alt="photo.date" class="h-full w-full object-cover transition duration-300 group-hover:scale-105" />
              <div class="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/60 to-transparent p-2 text-center text-[10px] text-white font-medium">
                {{ photo.date }}
              </div>
            </div>
          </div>
        </div>

        <EmptyState 
          v-else 
          title="No Potret Photos" 
          description="User hasn't uploaded any daily portraits yet." 
        />

      </div>

      <!-- Bottom Nav -->
      <BottomNav />

    </div>

    <!-- Modal Popup Detail Foto -->
    <PotretDetailModal
      :is-open="isModalOpen"
      :photo="currentPhoto"
      :photos="photos"
      :current-index="activeIndex"
      @close="isModalOpen = false"
      @prev="prevPhoto"
      @next="nextPhoto"
    />
  </div>
</template>
