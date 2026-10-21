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

const applySearch = () => {
  router.get('/admin/daily-potret', {
    search: search.value || undefined,
  }, { preserveState: true, preserveScroll: true, replace: true });
};
</script>

<template>
  <Head title="Potret Gallery — Her Space Monitor" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1">
        <!-- Header (Panel 10) -->
        <div class="flex items-center justify-between mb-5">
          <div class="flex items-center gap-2">
            <Link href="/admin/dashboard" class="p-1 -ml-1 text-[#2C3E35] hover:opacity-70 transition">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </Link>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Potret Gallery</h1>
          </div>
          <div class="w-6"></div>
        </div>

        <!-- Search Bar (Panel 10) -->
        <div class="relative mb-4">
          <span class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
            <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          </span>
          <input 
            v-model="search"
            type="text" 
            placeholder="Search user..." 
            @keydown.enter.prevent="applySearch"
            class="w-full pl-11 pr-4 py-3 bg-white border border-[#EAE7E1] rounded-2xl text-xs text-[#2C3E35] placeholder-[#8A9992] focus:outline-none focus:ring-2 focus:ring-[#2C3E35] shadow-xs transition"
          >
        </div>

        <!-- Filter Dropdown Pills (Panel 10) -->
        <div class="flex items-center gap-2.5 mb-5">
          <div class="flex-1 px-3 py-2 bg-white border border-[#EAE7E1] rounded-2xl text-xs font-semibold text-[#2C3E35] flex items-center justify-between shadow-xs">
            <span>All Users</span>
            <svg class="w-3.5 h-3.5 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
          </div>

          <div class="flex-1 px-3 py-2 bg-white border border-[#EAE7E1] rounded-2xl text-xs font-semibold text-[#2C3E35] flex items-center justify-between shadow-xs">
            <span>Oct 2025</span>
            <svg class="w-3.5 h-3.5 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
          </div>
        </div>

        <!-- User Gallery Items List (Panel 10) -->
        <div v-if="users.data.length > 0" class="space-y-3">
          <Link 
            v-for="user in users.data" 
            :key="user.id"
            :href="'/admin/daily-potret/' + user.id"
            class="flex items-center justify-between p-3.5 bg-white border border-[#EAE7E1] rounded-2xl hover:shadow-md hover:border-[#2C3E35]/30 transition cursor-pointer"
          >
            <div class="flex items-center gap-3.5">
              <img :src="user.avatar" alt="Avatar" class="w-11 h-11 rounded-full object-cover border border-[#EAE7E1]">
              <div>
                <h3 class="text-xs font-bold text-[#2C3E35]">{{ user.name }}</h3>
                <p class="text-[11px] text-[#8A9992] mt-0.5">{{ user.photosCount }} photos</p>
              </div>
            </div>
            <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
          </Link>
        </div>

        <EmptyState 
          v-else 
          title="No Potret Found" 
          description="No users with daily Potret photos match your search." 
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
