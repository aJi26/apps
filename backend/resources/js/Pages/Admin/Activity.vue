<script setup>
import { ref, computed } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import EmptyState from '@/Components/EmptyState.vue';

const filterOptions = ['All', 'Check-in', 'Goals', 'Quiz'];

const props = defineProps({
  activities: {
    type: [Object, Array],
    default: () => ({ data: [], links: [] }),
  },
  filters: {
    type: Object,
    default: () => ({ search: '', type: 'All' }),
  },
});

const search = ref(props.filters?.search || '');
const activeFilter = ref(props.filters?.type || 'All');

const activityList = computed(() => {
  if (Array.isArray(props.activities)) {
    return props.activities;
  }
  return props.activities?.data || [];
});

const paginationLinks = computed(() => {
  if (props.activities && Array.isArray(props.activities.links)) {
    return props.activities.links;
  }
  return [];
});

const applyFilters = () => {
  router.get('/admin/activity', {
    search: search.value || undefined,
    type: activeFilter.value === 'All' ? undefined : activeFilter.value,
  }, { preserveState: true, preserveScroll: true, replace: true });
};

const setFilter = (filter) => {
  activeFilter.value = filter;
  applyFilters();
};
</script>

<template>
  <Head title="Activity Dashboard — Her Space Monitor" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1">
        <!-- Header (Panel 12) -->
        <div class="flex items-center justify-between mb-5">
          <div class="flex items-center gap-2">
            <Link href="/admin/dashboard" class="p-1 -ml-1 text-[#2C3E35] hover:opacity-70 transition">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </Link>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Activity</h1>
          </div>
          <div class="w-6"></div>
        </div>

        <!-- Filter Badges (Panel 12) -->
        <div class="flex gap-2 mb-4 overflow-x-auto pb-1">
          <button 
            v-for="filter in filterOptions" 
            :key="filter"
            @click="setFilter(filter)"
            type="button"
            class="px-5 py-2 rounded-full text-xs font-semibold whitespace-nowrap transition transform active:scale-95 cursor-pointer"
            :class="activeFilter === filter ? 'bg-[#2C3E35] text-white shadow-xs' : 'bg-white border border-[#EAE7E1] text-[#8A9992] hover:text-[#2C3E35] hover:bg-[#E8ECE9]'"
          >
            {{ filter }}
          </button>
        </div>

        <!-- Search Bar -->
        <div class="relative mb-5">
          <span class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
             <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          </span>
          <input 
            v-model="search"
            type="text" 
            placeholder="Search activity or user..." 
            @keydown.enter.prevent="applyFilters"
            class="w-full pl-11 pr-4 py-3 bg-white border border-[#EAE7E1] rounded-2xl text-xs text-[#2C3E35] placeholder-[#8A9992] focus:outline-none focus:ring-2 focus:ring-[#2C3E35] shadow-xs transition"
          >
        </div>

        <!-- Activity Timeline Items (Panel 12) -->
        <div v-if="activityList.length > 0" class="space-y-3">
          <div 
            v-for="item in activityList" 
            :key="item.id" 
            class="flex items-start gap-3.5 p-3.5 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs hover:border-[#2C3E35]/30 transition"
          >
            <img :src="item.avatar" alt="Avatar" class="w-10 h-10 rounded-full object-cover shrink-0 border border-[#EAE7E1] mt-0.5">
            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between">
                <h3 class="text-xs font-bold text-[#2C3E35] truncate">{{ item.name }}</h3>
                <span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-[#E8ECE9] text-[#2C3E35]">
                  {{ item.type }}
                </span>
              </div>
              <p class="text-xs text-[#8A9992] mt-0.5 truncate">{{ item.action }}</p>
              <p class="text-[10px] text-[#8A9992] mt-1">{{ item.time }}</p>
            </div>
          </div>
        </div>

        <EmptyState 
          v-else 
          title="No activity recorded" 
          description="Activities from user actions will be logged here." 
        />

        <!-- Pagination -->
        <div v-if="paginationLinks.length > 3" class="mt-6 flex flex-wrap justify-center gap-2">
          <Link
            v-for="link in paginationLinks"
            :key="link.label"
            :href="link.url || '#'"
            :class="[
              'rounded-xl px-3 py-1.5 text-xs font-medium transition',
              link.active ? 'bg-[#2C3E35] text-white shadow-xs' : 'bg-white border border-[#EAE7E1] text-[#2C3E35] hover:bg-[#E8ECE9]',
              !link.url && 'pointer-events-none opacity-40',
            ]"
          >
            <span v-html="link.label"></span>
          </Link>
        </div>
      </div>

      <!-- Bottom Nav -->
      <BottomNav />

    </div>
  </div>
</template>
