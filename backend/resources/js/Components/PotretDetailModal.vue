<script setup>
import { computed } from 'vue';
import { Link } from '@inertiajs/vue3';

const props = defineProps({
  isOpen: Boolean,
  photo: Object,
  photos: {
    type: Array,
    default: () => [],
  },
  currentIndex: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['close', 'prev', 'next']);

const hasMultiple = computed(() => props.photos.length > 1);
const displayIndex = computed(() => {
  if (props.photos.length === 0) return '1 / 1';
  return `${props.currentIndex + 1} / ${props.photos.length}`;
});

const currentPhoto = computed(() => {
  if (props.photos.length > 0 && props.photos[props.currentIndex]) {
    return props.photos[props.currentIndex];
  }
  return props.photo;
});
</script>

<template>
  <div
    v-if="isOpen && currentPhoto"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm transition-all"
    @click.self="emit('close')"
  >
    <div class="relative w-full max-w-sm overflow-hidden rounded-[2.5rem] bg-[#FAF7F2] p-5 shadow-2xl border border-[#EAE7E1] animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Header Navigation: <  1 / 12  > and close -->
      <div class="mb-4 flex items-center justify-between text-[#2C3E35]">
        <button
          @click="emit('close')"
          type="button"
          class="flex h-8 w-8 items-center justify-center rounded-full hover:bg-[#E8ECE9] transition"
        >
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>

        <!-- Carousel Index Indicator with arrows -->
        <div class="flex items-center gap-2 px-3 py-1 bg-white border border-[#EAE7E1] rounded-full shadow-xs">
          <button 
            v-if="hasMultiple"
            @click.stop="emit('prev')"
            type="button" 
            class="text-[#8A9992] hover:text-[#2C3E35] p-0.5 transition"
            title="Previous"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
          </button>

          <span class="text-xs font-semibold tracking-wider text-[#2C3E35]">
            {{ displayIndex }}
          </span>

          <button 
            v-if="hasMultiple"
            @click.stop="emit('next')"
            type="button" 
            class="text-[#8A9992] hover:text-[#2C3E35] p-0.5 transition"
            title="Next"
          >
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7"/></svg>
          </button>
        </div>

        <button
          @click="emit('close')"
          type="button"
          class="flex h-8 w-8 items-center justify-center rounded-full hover:bg-[#E8ECE9] text-[#8A9992] hover:text-[#2C3E35] transition"
        >
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Main Photo Frame -->
      <div class="relative aspect-[3/4] w-full overflow-hidden rounded-[2rem] bg-gray-100 shadow-md border border-[#EAE7E1]">
        <img 
          :src="currentPhoto.image_url || currentPhoto.url" 
          :alt="currentPhoto.date" 
          class="h-full w-full object-cover transition-transform duration-300 hover:scale-105" 
        />
        
        <!-- Subtle gradient overlay at bottom of photo -->
        <div class="absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-black/50 to-transparent pointer-events-none"></div>
        <div class="absolute bottom-3 left-4 text-white text-xs font-medium drop-shadow-md">
          {{ currentPhoto.date }}
        </div>
      </div>

      <!-- Info & Actions -->
      <div class="mt-4 px-1">
        <div class="mb-4 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <img 
              v-if="currentPhoto.avatar" 
              :src="currentPhoto.avatar" 
              alt="Avatar" 
              class="w-10 h-10 rounded-full object-cover border border-[#EAE7E1]"
            />
            <div v-else class="w-10 h-10 rounded-full bg-[#E8ECE9] text-[#2C3E35] font-bold flex items-center justify-center text-xs">
              {{ (currentPhoto.user_name || 'U').substring(0, 2).toUpperCase() }}
            </div>
            <div>
              <h4 class="text-sm font-bold text-[#2C3E35] font-serif">{{ currentPhoto.user_name || 'User Potret' }}</h4>
              <p class="text-[11px] text-[#8A9992]">{{ currentPhoto.uploaded_at || currentPhoto.time || currentPhoto.date }}</p>
            </div>
          </div>
        </div>

        <div class="flex gap-2.5">
          <a
            :href="currentPhoto.image_url || currentPhoto.url"
            target="_blank"
            download
            class="flex flex-1 items-center justify-center gap-1.5 rounded-2xl border border-[#EAE7E1] bg-white py-3 text-xs font-semibold text-[#2C3E35] transition hover:bg-[#E8ECE9] shadow-xs"
          >
            <svg class="h-4 w-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Download
          </a>

          <button
            @click="emit('close')"
            type="button"
            class="flex flex-1 items-center justify-center gap-1.5 rounded-2xl bg-[#2C3E35] py-3 text-xs font-bold text-white transition hover:bg-[#202e27] shadow-sm"
          >
            View Details
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
