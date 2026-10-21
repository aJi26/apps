<script setup>
import { ref } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import FloralDecor from '@/Components/FloralDecor.vue';

const props = defineProps({
  engagementData: {
    type: Array,
    default: () => [
      { day: '14 Oct', count: 20 },
      { day: '16 Oct', count: 32 },
      { day: '18 Oct', count: 38 },
      { day: '20 Oct', count: 42 },
    ],
  },
  summaryStats: {
    type: Object,
    default: () => ({
      completed: 42,
      notCompletedPercent: '6%',
    }),
  },
});

const activeCategory = ref('Check-ins');
const categories = ['Check-ins', 'Goals', 'Quizzes'];
</script>

<template>
  <Head title="Quick Summary — Her Space Monitor" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1 space-y-6">
        <!-- Header (Panel 14) -->
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <Link href="/admin/dashboard" class="p-1 -ml-1 text-[#2C3E35] hover:opacity-70 transition">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </Link>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35] italic">Her Space ♡</h1>
          </div>
          <button type="button" class="text-[#2C3E35] p-2 hover:bg-[#E8ECE9] rounded-2xl transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"/></svg>
          </button>
        </div>

        <div>
          <h2 class="text-lg font-serif font-bold text-[#2C3E35]">Quick Summary</h2>
          <p class="text-xs text-[#8A9992] mt-0.5">Application engagement overview</p>
        </div>

        <!-- Category Tabs: [Check-ins] [Goals] [Quizzes] (Panel 14) -->
        <div class="flex bg-white border border-[#EAE7E1] p-1 rounded-2xl shadow-xs">
          <button 
            v-for="cat in categories" 
            :key="cat"
            @click="activeCategory = cat"
            type="button"
            class="flex-1 py-2 text-xs font-semibold rounded-xl transition text-center"
            :class="activeCategory === cat ? 'bg-[#2C3E35] text-white shadow-xs' : 'text-[#8A9992] hover:text-[#2C3E35]'"
          >
            {{ cat }}
          </button>
        </div>

        <!-- Chart Card (Panel 14) -->
        <div class="bg-white border border-[#EAE7E1] rounded-3xl p-5 shadow-xs space-y-4">
          <div class="flex justify-between items-center">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">{{ activeCategory }} Activity</h3>
            <!-- Legend -->
            <div class="flex items-center gap-3 text-[10px]">
              <div class="flex items-center gap-1.5">
                <span class="w-2 h-2 rounded-full bg-[#2C3E35]"></span>
                <span class="text-[#8A9992] font-medium">Completed</span>
              </div>
              <div class="flex items-center gap-1.5">
                <span class="w-2 h-2 rounded-full bg-[#D96B5B]"></span>
                <span class="text-[#8A9992] font-medium">Not completed</span>
              </div>
            </div>
          </div>

          <!-- SVG Smooth Line Chart (Panel 14) -->
          <div class="relative w-full h-48 pt-2">
            <!-- Grid horizontal lines -->
            <div class="absolute inset-x-0 top-6 border-b border-dashed border-[#EAE7E1]"></div>
            <div class="absolute inset-x-0 top-18 border-b border-dashed border-[#EAE7E1]"></div>
            <div class="absolute inset-x-0 top-30 border-b border-dashed border-[#EAE7E1]"></div>
            <div class="absolute inset-x-0 bottom-8 border-b border-[#EAE7E1]"></div>

            <!-- Left Y-Axis Labels -->
            <div class="absolute left-0 inset-y-0 flex flex-col justify-between text-[9px] text-[#8A9992] pb-8 pointer-events-none">
              <span>60</span>
              <span>40</span>
              <span>20</span>
              <span>0</span>
            </div>

            <!-- SVG Curves -->
            <svg class="w-full h-full pl-6 pb-8" viewBox="0 0 320 150" fill="none" preserveAspectRatio="none">
              <!-- Gradient fill under green line -->
              <defs>
                <linearGradient id="greenGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#2C3E35" stop-opacity="0.25"/>
                  <stop offset="100%" stop-color="#2C3E35" stop-opacity="0.0"/>
                </linearGradient>
                <linearGradient id="coralGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stop-color="#D96B5B" stop-opacity="0.15"/>
                  <stop offset="100%" stop-color="#D96B5B" stop-opacity="0.0"/>
                </linearGradient>
              </defs>

              <!-- Completed Path Area -->
              <path d="M 20 110 Q 90 90, 160 50 T 300 25 L 300 140 L 20 140 Z" fill="url(#greenGradient)"/>
              
              <!-- Completed Line (Green) -->
              <path d="M 20 110 Q 90 90, 160 50 T 300 25" fill="none" stroke="#2C3E35" stroke-width="2.5" stroke-linecap="round"/>
              <circle cx="20" cy="110" r="4" fill="#FFFFFF" stroke="#2C3E35" stroke-width="2"/>
              <circle cx="110" cy="80" r="4" fill="#FFFFFF" stroke="#2C3E35" stroke-width="2"/>
              <circle cx="200" cy="40" r="4" fill="#FFFFFF" stroke="#2C3E35" stroke-width="2"/>
              <circle cx="300" cy="25" r="4" fill="#FFFFFF" stroke="#2C3E35" stroke-width="2"/>

              <!-- Not completed Line (Coral) -->
              <path d="M 20 135 Q 90 120, 160 125 T 300 115" fill="none" stroke="#D96B5B" stroke-width="2" stroke-linecap="round" stroke-dasharray="3 3"/>
              <circle cx="20" cy="135" r="3.5" fill="#FFFFFF" stroke="#D96B5B" stroke-width="1.8"/>
              <circle cx="110" cy="122" r="3.5" fill="#FFFFFF" stroke="#D96B5B" stroke-width="1.8"/>
              <circle cx="200" cy="122" r="3.5" fill="#FFFFFF" stroke="#D96B5B" stroke-width="1.8"/>
              <circle cx="300" cy="115" r="3.5" fill="#FFFFFF" stroke="#D96B5B" stroke-width="1.8"/>
            </svg>

            <!-- Bottom X-Axis Labels (Panel 14) -->
            <div class="absolute inset-x-0 bottom-1 pl-6 flex justify-between text-[10px] text-[#8A9992] font-semibold">
              <span>14 Oct</span>
              <span>16 Oct</span>
              <span>18 Oct</span>
              <span>20 Oct</span>
            </div>
          </div>

          <!-- Bottom Stat Badges (Panel 14) -->
          <div class="grid grid-cols-2 gap-3 pt-2">
            <div class="p-3.5 bg-[#FAF7F2] border border-[#EAE7E1] rounded-2xl flex items-center gap-3">
              <div class="w-8 h-8 rounded-xl bg-[#E8ECE9] text-[#2C3E35] flex items-center justify-center font-bold">
                ✓
              </div>
              <div>
                <span class="text-[10px] text-[#8A9992] font-medium block">Completed</span>
                <span class="text-xl font-bold text-[#2C3E35]">{{ summaryStats.completed }}</span>
              </div>
            </div>

            <div class="p-3.5 bg-[#FAF7F2] border border-[#EAE7E1] rounded-2xl flex items-center gap-3">
              <div class="w-8 h-8 rounded-xl bg-[#FEEAE6] text-[#D96B5B] flex items-center justify-center font-bold">
                !
              </div>
              <div>
                <span class="text-[10px] text-[#8A9992] font-medium block">Not completed</span>
                <span class="text-xl font-bold text-[#2C3E35]">{{ summaryStats.notCompletedPercent }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Motivational Quote from Panel 17 -->
        <div class="bg-white border border-[#EAE7E1] rounded-3xl p-6 text-center space-y-2 shadow-xs">
          <FloralDecor variant="center" class="py-1" />
          <p class="font-serif italic text-sm text-[#2C3E35] font-semibold max-w-[220px] mx-auto leading-relaxed">
            "Better insights for a brighter Her Space ♡"
          </p>
        </div>

      </div>

      <!-- Bottom Nav -->
      <BottomNav />

    </div>
  </div>
</template>
