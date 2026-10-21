<script setup>
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import EmptyState from '@/Components/EmptyState.vue';

const props = defineProps({
  users: {
    type: Object,
    required: true,
  },
  filters: {
    type: Object,
    required: true,
  },
});

const search = ref(props.filters.search);
const activeFilter = ref(props.filters.status);

const applyFilters = () => {
  router.get('/admin/users', {
    search: search.value || undefined,
    status: activeFilter.value === 'All' ? undefined : activeFilter.value,
  }, { preserveState: true, preserveScroll: true, replace: true });
};

const setFilter = (filter) => {
  activeFilter.value = filter;
  applyFilters();
};
</script>

<template>
  <Head title="Users — Her Space Monitor" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1">
        <!-- Header (Panel 4) -->
        <div class="flex justify-between items-center mb-5">
          <div class="flex items-center gap-2">
            <Link href="/admin/dashboard" class="p-1 -ml-1 text-[#2C3E35] hover:opacity-70 transition">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </Link>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Users</h1>
          </div>
          <button type="button" class="text-[#2C3E35] p-2 hover:bg-[#E8ECE9] rounded-2xl transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"/></svg>
          </button>
        </div>

        <!-- Search Bar (Panel 4) -->
        <div class="relative mb-4">
          <span class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
             <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          </span>
          <input 
            v-model="search"
            type="text" 
            placeholder="Search name, email, or username..." 
            @keydown.enter.prevent="applyFilters"
            class="w-full pl-11 pr-4 py-3 bg-white border border-[#EAE7E1] rounded-2xl text-xs text-[#2C3E35] placeholder-[#8A9992] focus:outline-none focus:ring-2 focus:ring-[#2C3E35] shadow-xs transition"
          >
        </div>

        <!-- Filter Badges (Panel 4) -->
        <div class="flex gap-2 mb-5">
          <button 
            v-for="filter in ['All', 'Active', 'Inactive']" 
            :key="filter"
            @click="setFilter(filter)"
            class="px-5 py-2 rounded-full text-xs font-semibold transition transform active:scale-95"
            :class="activeFilter === filter ? 'bg-[#2C3E35] text-white shadow-sm' : 'bg-white border border-[#EAE7E1] text-[#8A9992] hover:text-[#2C3E35] hover:bg-[#E8ECE9]'"
          >
            {{ filter }}
          </button>
        </div>

        <!-- User List Items (Panel 4) -->
        <div v-if="users.data.length > 0" class="space-y-3">
          <Link 
            v-for="user in users.data" 
            :key="user.id"
            :href="'/admin/users/' + user.id"
            class="flex items-center justify-between p-3.5 bg-white border border-[#EAE7E1] rounded-2xl hover:shadow-md hover:border-[#2C3E35]/30 transition cursor-pointer"
          >
            <div class="flex items-center gap-3.5 min-w-0">
              <img :src="user.avatar" alt="Avatar" class="w-11 h-11 rounded-full object-cover shrink-0 border border-[#EAE7E1]">
              <div class="min-w-0">
                <div class="flex items-center gap-2">
                  <h3 class="text-xs font-bold text-[#2C3E35] truncate">{{ user.name }}</h3>
                  <span 
                    class="px-2 py-0.5 rounded-full text-[9px] font-bold shrink-0"
                    :class="user.status === 'Active' ? 'bg-[#E8ECE9] text-[#2C3E35]' : 'bg-[#FEEAE6] text-[#D96B5B]'"
                  >
                    {{ user.status }}
                  </span>
                </div>
                <p class="text-[11px] text-[#8A9992] truncate mt-0.5">{{ user.email }}</p>
                <p class="text-[10px] text-[#8A9992] mt-1 flex items-center gap-1">
                  <span>{{ user.joinedDate || '12 Oct 2025' }}</span>
                  <span>•</span>
                  <span>{{ user.joinedDaysAgo || user.lastActive }}</span>
                </p>
              </div>
            </div>
            <svg class="w-4 h-4 text-[#8A9992] shrink-0 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
          </Link>
        </div>

        <EmptyState 
          v-else 
          title="No users found" 
          description="Try adjusting your search query or filter." 
        />

        <!-- Pagination -->
        <div v-if="users.links && users.links.length > 3" class="mt-6 flex flex-wrap justify-center gap-2">
          <Link
            v-for="link in users.links"
            :key="link.label"
            :href="link.url || '#'"
            :class="[
              'rounded-xl px-3 py-1.5 text-xs font-medium transition',
              link.active ? 'bg-[#2C3E35] text-white shadow-xs' : 'bg-white border border-[#EAE7E1] text-[#2C3E35] hover:bg-[#E8ECE9]',
              !link.url && 'pointer-events-none opacity-40',
            ]"
            v-html="link.label"
          />
        </div>
      </div>

      <!-- Bottom Nav -->
      <BottomNav />

    </div>
  </div>
</template>
