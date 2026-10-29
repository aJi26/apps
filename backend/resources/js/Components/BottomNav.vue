<script setup>
import { computed } from 'vue';
import { Link, usePage } from '@inertiajs/vue3';

const page = usePage();
const currentUrl = computed(() => page.url || '');

const isCurrent = (path) => {
  const url = currentUrl.value;
  if (path === '/admin/dashboard') {
    return url === '/admin/dashboard' || url === '/admin';
  }
  return url.startsWith(path);
};
</script>

<template>
  <div class="sticky bottom-0 left-0 right-0 mt-auto border-t border-[#EAE7E1] bg-white/95 backdrop-blur-md px-4 py-2.5 flex justify-between items-center text-[10px] font-medium z-30 shadow-[0_-4px_12px_rgba(44,62,53,0.03)]">
    <!-- 1. Overview -->
    <Link 
      href="/admin/dashboard" 
      class="flex flex-col items-center flex-1 transition-all duration-200"
      :class="isCurrent('/admin/dashboard') ? 'text-[#2C3E35] font-bold scale-105' : 'text-[#8A9992] hover:text-[#2C3E35]'"
    >
      <div class="p-1 rounded-xl transition" :class="isCurrent('/admin/dashboard') ? 'bg-[#E8ECE9]/70' : ''">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
        </svg>
      </div>
      <span class="mt-0.5">Overview</span>
    </Link>

    <!-- 2. Users -->
    <Link 
      href="/admin/users" 
      class="flex flex-col items-center flex-1 transition-all duration-200"
      :class="isCurrent('/admin/users') ? 'text-[#2C3E35] font-bold scale-105' : 'text-[#8A9992] hover:text-[#2C3E35]'"
    >
      <div class="p-1 rounded-xl transition" :class="isCurrent('/admin/users') ? 'bg-[#E8ECE9]/70' : ''">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
        </svg>
      </div>
      <span class="mt-0.5">Users</span>
    </Link>

    <!-- 3. Potret (Center Icon Button) -->
    <Link 
      href="/admin/daily-potret" 
      class="flex flex-col items-center flex-1 transition-all duration-200"
      :class="isCurrent('/admin/daily-potret') ? 'text-[#2C3E35] font-bold scale-105' : 'text-[#8A9992] hover:text-[#2C3E35]'"
    >
      <div 
        class="w-10 h-10 -mt-3 rounded-full flex items-center justify-center transition shadow-md"
        :class="isCurrent('/admin/daily-potret') ? 'bg-[#2C3E35] text-white ring-4 ring-[#E8ECE9]' : 'bg-[#FAF7F2] border border-[#EAE7E1] text-[#2C3E35] hover:bg-[#E8ECE9]'"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
        </svg>
      </div>
      <span class="mt-0.5">Potret</span>
    </Link>

    <!-- 4. Activity -->
    <Link 
      href="/admin/activity" 
      class="flex flex-col items-center flex-1 transition-all duration-200 cursor-pointer"
      :class="isCurrent('/admin/activity') ? 'text-[#2C3E35] font-bold scale-105' : 'text-[#8A9992] hover:text-[#2C3E35]'"
    >
      <div class="p-1 rounded-xl transition" :class="isCurrent('/admin/activity') ? 'bg-[#E8ECE9]/70' : ''">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z"/>
        </svg>
      </div>
      <span class="mt-0.5">Activity</span>
    </Link>

    <!-- 5. Settings -->
    <Link 
      href="/admin/settings" 
      class="flex flex-col items-center flex-1 transition-all duration-200"
      :class="isCurrent('/admin/settings') ? 'text-[#2C3E35] font-bold scale-105' : 'text-[#8A9992] hover:text-[#2C3E35]'"
    >
      <div class="p-1 rounded-xl transition" :class="isCurrent('/admin/settings') ? 'bg-[#E8ECE9]/70' : ''">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
        </svg>
      </div>
      <span class="mt-0.5">Settings</span>
    </Link>
  </div>
</template>
