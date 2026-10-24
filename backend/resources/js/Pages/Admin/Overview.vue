<script setup>
import { computed } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import FloralDecor from '@/Components/FloralDecor.vue';
import EmptyState from '@/Components/EmptyState.vue';


const props = defineProps({
  stats: {
    type: Object,
    default: () => ({
      totalUsers: 48,
      todayCheckIns: 42,
      totalGoals: 28,
      totalQuizzes: 16,
    }),
  },
  activities: {
    type: Array,
    default: () => [],
  },
  upcomingBirthdays: {
    type: Array,
    default: () => [],
  },
  dashboardDate: {
    type: String,
    required: true,
  },
  adminName: {
    type: String,
    required: true,
  },
});

const greeting = computed(() => {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
});
</script>

<template>
  <Head title="Overview — Her Space Monitor" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1 space-y-6">
        
        <!-- Header (Panel 3) -->
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-2xl font-serif font-bold text-[#2C3E35] italic tracking-wide">Her Space ♡</h1>
            <p class="text-sm font-bold text-[#2C3E35] mt-1 font-serif flex items-center gap-1.5">
              <span>{{ greeting }}, {{ adminName }}</span>
              <span>🌿</span>
            </p>
            <p class="text-[11px] text-[#8A9992] font-medium mt-0.5">{{ dashboardDate }}</p>
          </div>
          
          <Link 
            href="/admin/analytics" 
            class="p-2.5 bg-white border border-[#EAE7E1] text-[#2C3E35] rounded-2xl hover:bg-[#E8ECE9] shadow-xs transition"
            title="View Summary Analytics"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
            </svg>
          </Link>
        </div>

        <!-- 2x2 Stats Grid (Panel 3) -->
        <div class="grid grid-cols-2 gap-3.5">
          <!-- Total Users -->
          <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs transition hover:shadow-md">
            <div class="w-8 h-8 rounded-xl bg-[#E8ECE9] text-[#2C3E35] flex items-center justify-center mb-2.5">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
            </div>
            <span class="text-[11px] text-[#8A9992] font-medium block">Total Users</span>
            <div class="flex items-baseline justify-between mt-0.5">
              <span class="text-2xl font-bold text-[#2C3E35]">{{ stats.totalUsers }}</span>
              <span class="text-[10px] font-semibold text-[#2C3E35] bg-[#E8ECE9] px-1.5 py-0.5 rounded-full">↑ 12%</span>
            </div>
            <span class="text-[9px] text-[#8A9992] mt-1 block">vs last week</span>
          </div>

          <!-- Today Check-ins -->
          <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs transition hover:shadow-md">
            <div class="w-8 h-8 rounded-xl bg-[#FEEAE6] text-[#D96B5B] flex items-center justify-center mb-2.5">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 002-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            </div>
            <span class="text-[11px] text-[#8A9992] font-medium block">Today Check-ins</span>
            <div class="flex items-baseline justify-between mt-0.5">
              <span class="text-2xl font-bold text-[#2C3E35]">{{ stats.todayCheckIns }}</span>
              <span class="text-[10px] font-semibold text-[#D96B5B] bg-[#FEEAE6] px-1.5 py-0.5 rounded-full">↑ 8%</span>
            </div>
            <span class="text-[9px] text-[#8A9992] mt-1 block">vs yesterday</span>
          </div>

          <!-- Goals -->
          <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs transition hover:shadow-md">
            <div class="w-8 h-8 rounded-xl bg-[#E8ECE9] text-[#2C3E35] flex items-center justify-center mb-2.5">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            </div>
            <span class="text-[11px] text-[#8A9992] font-medium block">Goals</span>
            <div class="flex items-baseline justify-between mt-0.5">
              <span class="text-2xl font-bold text-[#2C3E35]">{{ stats.totalGoals }}</span>
              <span class="text-[10px] font-semibold text-[#2C3E35] bg-[#E8ECE9] px-1.5 py-0.5 rounded-full">↑ 6%</span>
            </div>
            <span class="text-[9px] text-[#8A9992] mt-1 block">completed</span>
          </div>

          <!-- Quizzes -->
          <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs transition hover:shadow-md">
            <div class="w-8 h-8 rounded-xl bg-[#FEF3C7] text-[#D97706] flex items-center justify-center mb-2.5">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/></svg>
            </div>
            <span class="text-[11px] text-[#8A9992] font-medium block">Quizzes</span>
            <div class="flex items-baseline justify-between mt-0.5">
              <span class="text-2xl font-bold text-[#2C3E35]">{{ stats.totalQuizzes }}</span>
              <span class="text-[10px] font-semibold text-[#D97706] bg-[#FEF3C7] px-1.5 py-0.5 rounded-full">↑ 4%</span>
            </div>
            <span class="text-[9px] text-[#8A9992] mt-1 block">completed</span>
          </div>
        </div>

        <!-- Recent Activity Section (Panel 3) -->
        <div>
          <div class="flex justify-between items-center mb-3">
            <h2 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Recent Activity</h2>
            <Link href="/admin/activity" class="text-[11px] text-[#2C3E35] font-bold hover:underline">View all</Link>
          </div>

          <div v-if="activities.length > 0" class="space-y-2.5">
            <div 
              v-for="act in activities" 
              :key="act.id" 
              class="flex items-center gap-3 p-3 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs hover:border-[#2C3E35]/30 transition"
            >
              <img :src="act.avatar" alt="Avatar" class="w-9 h-9 rounded-full object-cover border border-[#EAE7E1]">
              <div class="flex-1 min-w-0">
                <h3 class="text-xs font-bold text-[#2C3E35] truncate">{{ act.name }}</h3>
                <p class="text-[11px] text-[#8A9992] truncate">{{ act.action }}</p>
              </div>
              <span class="text-[10px] text-[#8A9992] whitespace-nowrap">{{ act.time }}</span>
            </div>
          </div>

          <EmptyState 
            v-else 
            title="Belum ada aktivitas terbaru" 
            description="Aktivitas pengguna akan muncul di sini secara otomatis." 
          />
        </div>

        <!-- Upcoming Birthdays (Panel 13) -->
        <div class="bg-white border border-[#EAE7E1] rounded-3xl p-5 shadow-xs relative overflow-hidden">
          <div class="flex justify-between items-center mb-3">
            <div>
              <h2 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Upcoming Birthdays</h2>
              <p class="text-[10px] text-[#8A9992]">This Month</p>
            </div>
            <span class="text-[10px] font-semibold text-[#2C3E35] bg-[#E8ECE9] px-2.5 py-0.5 rounded-full">
              {{ upcomingBirthdays.length }} upcoming
            </span>
          </div>

          <div v-if="upcomingBirthdays.length" class="space-y-2.5 mb-4">
            <Link
              v-for="birthday in upcomingBirthdays"
              :key="birthday.id"
              :href="'/admin/users/' + birthday.id"
              class="flex items-center justify-between p-2.5 rounded-2xl border border-[#EAE7E1] hover:bg-[#FAF7F2] transition"
            >
              <div class="flex items-center gap-3">
                <img :src="birthday.avatar" alt="Avatar" class="w-8 h-8 rounded-full object-cover">
                <div>
                  <p class="text-xs font-bold text-[#2C3E35]">{{ birthday.name }}</p>
                  <p class="text-[10px] text-[#8A9992]">{{ birthday.birthday }}</p>
                </div>
              </div>
              <span class="text-[10px] font-semibold text-[#2C3E35] bg-[#E8ECE9] px-2 py-0.5 rounded-full">
                {{ birthday.daysUntil === 0 ? 'Today 🎉' : `in ${birthday.daysUntil} days` }}
              </span>
            </Link>
          </div>

          <p v-else class="text-xs text-center text-[#8A9992] py-4">No upcoming birthdays.</p>

          <!-- Delicate floral artwork at bottom of birthday card (Panel 13) -->
          <FloralDecor variant="bottom" class="opacity-70 mt-2" />
        </div>

      </div>

      <!-- Bottom Navigation -->
      <BottomNav />

    </div>
  </div>
</template>
