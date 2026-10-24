<script setup>
import { ref, computed } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import EmptyState from '@/Components/EmptyState.vue';


const props = defineProps({
  users: { type: Object, required: true },
  filters: { type: Object, required: true },
});

const search = ref('');
const activeFilter = ref('All');

// List data mentah dari server
const rawUsers = computed(() => {
  return Array.isArray(props.users) ? props.users : (props.users?.data || []);
});

// Pencarian Instan 100% di Frontend (Tanpa Loading / Tanpa Request Server)
const filteredUsers = computed(() => {
  const query = search.value.toLowerCase().trim();

  return rawUsers.value.filter(user => {
    const matchSearch = !query || 
      user.name.toLowerCase().includes(query) || 
      user.email.toLowerCase().includes(query);
      
    const matchStatus = activeFilter.value === 'All' || 
      user.status.toLowerCase() === activeFilter.value.toLowerCase();

    return matchSearch && matchStatus;
  });
});
</script>

<template>
  <Head title="Users — Her Space Monitor" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <div class="p-6 overflow-y-auto flex-1">
        <!-- Header -->
        <div class="flex justify-between items-center mb-5">
          <div class="flex items-center gap-2">
            <Link href="/admin/dashboard" class="p-1 -ml-1 text-[#2C3E35] hover:opacity-70 transition">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </Link>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Users</h1>
          </div>
        </div>

        <!-- Input Search Instan -->
        <div class="relative mb-4">
          <span class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
             <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          </span>
          <input 
            v-model="search"
            type="text" 
            placeholder="Search name or email..." 
            class="w-full pl-11 pr-4 py-3 bg-white border border-[#EAE7E1] rounded-2xl text-xs text-[#2C3E35] placeholder-[#8A9992] focus:outline-none focus:ring-2 focus:ring-[#2C3E35] shadow-xs transition"
          >
        </div>

        <!-- Filter Status Badges -->
        <div class="flex gap-2 mb-5">
          <button 
            v-for="filter in ['All', 'Active', 'Inactive']" 
            :key="filter"
            @click="activeFilter = filter"
            class="px-5 py-2 rounded-full text-xs font-semibold transition transform active:scale-95"
            :class="activeFilter === filter ? 'bg-[#2C3E35] text-white shadow-sm' : 'bg-white border border-[#EAE7E1] text-[#8A9992] hover:text-[#2C3E35] hover:bg-[#E8ECE9]'"
          >
            {{ filter }}
          </button>
        </div>

        <!-- User List Items -->
        <div v-if="filteredUsers.length > 0" class="space-y-3">
          <Link 
            v-for="user in filteredUsers" 
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
              </div>
            </div>
            <svg class="w-4 h-4 text-[#8A9992] shrink-0 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
          </Link>
        </div>

        <EmptyState v-else title="No users found" description="Try adjusting your search query or filter." />
      </div>

      <BottomNav />
    </div>
  </div>
</template>