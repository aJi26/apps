<script setup>
import { ref, computed } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';
import PotretDetailModal from '@/Components/PotretDetailModal.vue';
import EmptyState from '@/Components/EmptyState.vue';

const props = defineProps({
  userId: {
    type: [String, Number],
    required: true,
  },
  user: {
    type: Object,
    required: true,
  },
  goals: {
    type: Array,
    default: () => [],
  },
  quizzes: {
    type: Array,
    default: () => [],
  },
  userPotrets: {
    type: Array,
    default: () => [],
  },
  activityHistory: {
    type: Array,
    default: () => [],
  },
});

const goBack = () => {
  router.get('/admin/users');
};

const activeTab = ref('Overview');
const tabs = ['Overview', 'Potret', 'Goals', 'Quiz', 'Activity'];

// Goals filter
const goalFilter = ref('Active');
const filteredGoals = computed(() => {
  if (goalFilter.value === 'All') return props.goals;
  return props.goals.filter(g => g.status.toLowerCase() === goalFilter.value.toLowerCase());
});

// Potret modal state
const isModalOpen = ref(false);
const selectedPhotoIndex = ref(0);

const openPhotoModal = (index) => {
  selectedPhotoIndex.value = index;
  isModalOpen.value = true;
};

const nextPhoto = () => {
  if (selectedPhotoIndex.value < props.userPotrets.length - 1) {
    selectedPhotoIndex.value++;
  } else {
    selectedPhotoIndex.value = 0;
  }
};

const prevPhoto = () => {
  if (selectedPhotoIndex.value > 0) {
    selectedPhotoIndex.value--;
  } else {
    selectedPhotoIndex.value = props.userPotrets.length - 1;
  }
};
</script>

<template>
  <Head :title="`${user.name} — Her Space User Detail`" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1 space-y-5">
        
        <!-- Header Navigation (Panel 5) -->
        <div class="flex items-center justify-between">
          <button @click="goBack" type="button" class="text-[#2C3E35] hover:opacity-70 transition p-1 -ml-1">
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

        <!-- User Profile Card (Panel 5) -->
        <div class="flex items-center gap-4 bg-white border border-[#EAE7E1] rounded-3xl p-4 shadow-xs">
          <img :src="user.avatar" alt="Avatar" class="w-14 h-14 rounded-full object-cover shadow-xs border border-[#EAE7E1]">
          <div class="min-w-0 flex-1">
            <h2 class="text-base font-bold text-[#2C3E35] font-serif truncate">{{ user.name }}</h2>
            <p class="text-xs text-[#8A9992] truncate mt-0.5">{{ user.email }}</p>
          </div>
        </div>

        <!-- Pill Tabs Navigation (Panel 5-9) -->
        <div class="flex bg-white/80 border border-[#EAE7E1] p-1 rounded-2xl overflow-x-auto shadow-xs">
          <button 
            v-for="tab in tabs" 
            :key="tab"
            @click="activeTab = tab"
            type="button"
            class="flex-1 min-w-[62px] py-2 text-xs font-semibold rounded-xl transition text-center whitespace-nowrap"
            :class="activeTab === tab ? 'bg-[#2C3E35] text-white shadow-sm' : 'text-[#8A9992] hover:text-[#2C3E35]'"
          >
            {{ tab }}
          </button>
        </div>

        <!-- TAB 1: OVERVIEW (Panel 5) -->
        <div v-if="activeTab === 'Overview'" class="space-y-5 animate-in fade-in duration-200">
          <div>
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider mb-3">Personal Information</h3>
            <div class="bg-white border border-[#EAE7E1] rounded-2xl p-4 space-y-3.5 shadow-xs">
              
              <!-- Birthday -->
              <div class="flex items-center gap-3.5">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 002-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                </div>
                <div>
                  <span class="text-[10px] text-[#8A9992] font-medium block">Birthday</span>
                  <span class="text-xs font-bold text-[#2C3E35]">{{ user.birthday }}</span>
                </div>
              </div>

              <!-- Joined Her Space -->
              <div class="flex items-center gap-3.5">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <div>
                  <span class="text-[10px] text-[#8A9992] font-medium block">Joined Her Space</span>
                  <span class="text-xs font-bold text-[#2C3E35]">{{ user.joined }}</span>
                </div>
              </div>

              <!-- Last Login -->
              <div class="flex items-center gap-3.5">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"/></svg>
                </div>
                <div>
                  <span class="text-[10px] text-[#8A9992] font-medium block">Last Login</span>
                  <span class="text-xs font-bold text-[#2C3E35]">{{ user.lastLogin }}</span>
                </div>
              </div>

              <!-- Today's Potret -->
              <div class="flex items-center gap-3.5">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                </div>
                <div>
                  <span class="text-[10px] text-[#8A9992] font-medium block">Today's Potret</span>
                  <span class="text-xs font-bold text-[#2C3E35]">{{ user.todayPotret }}</span>
                </div>
              </div>

            </div>
          </div>

          <!-- Quick Stats (Panel 5) -->
          <div>
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider mb-3">Quick Stats</h3>
            <div class="grid grid-cols-2 gap-3">
              <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs">
                <div class="flex items-center gap-2 mb-1">
                  <span class="text-base">📸</span>
                  <span class="text-[10px] text-[#8A9992] font-medium">Total Check-ins</span>
                </div>
                <span class="text-2xl font-bold text-[#2C3E35]">{{ user.stats.checkIns }}</span>
              </div>
              <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs">
                <div class="flex items-center gap-2 mb-1">
                  <span class="text-base">🎯</span>
                  <span class="text-[10px] text-[#8A9992] font-medium">Goals</span>
                </div>
                <span class="text-2xl font-bold text-[#2C3E35]">{{ user.stats.goals }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- TAB 2: POTRET GALLERY (Panel 6) -->
        <div v-else-if="activeTab === 'Potret'" class="space-y-4 animate-in fade-in duration-200">
          <div class="flex justify-between items-center">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Potret Gallery</h3>
            <!-- Month filter dropdown -->
            <div class="px-3 py-1 bg-white border border-[#EAE7E1] rounded-xl text-[11px] font-semibold text-[#2C3E35] flex items-center gap-1">
              <span>October 2025</span>
              <svg class="w-3.5 h-3.5 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
            </div>
          </div>

          <div v-if="userPotrets.length > 0" class="grid grid-cols-2 gap-3">
            <div 
              v-for="(item, index) in userPotrets" 
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

          <EmptyState 
            v-else 
            title="No Potret Photos" 
            description="User hasn't uploaded any daily portraits yet." 
          />
        </div>

        <!-- TAB 3: GOALS (Panel 7) -->
        <div v-else-if="activeTab === 'Goals'" class="space-y-4 animate-in fade-in duration-200">
          <div class="flex justify-between items-center">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Goals</h3>
            <!-- Filter pills -->
            <div class="flex gap-1.5">
              <button 
                v-for="pill in ['Active', 'Completed', 'All']" 
                :key="pill"
                @click="goalFilter = pill"
                type="button"
                class="px-2.5 py-1 rounded-full text-[10px] font-semibold transition"
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
              
              <!-- Progress Bar -->
              <div class="w-full bg-[#FAF7F2] h-2 rounded-full overflow-hidden border border-[#EAE7E1]">
                <div class="bg-[#2C3E35] h-full transition-all duration-500 rounded-full" :style="{ width: goal.progress }"></div>
              </div>
            </div>
          </div>

          <EmptyState 
            v-else 
            title="No Goals Found" 
            description="No goals matching the selected filter." 
          />
        </div>

        <!-- TAB 4: QUIZ (Panel 8) -->
        <div v-else-if="activeTab === 'Quiz'" class="space-y-3 animate-in fade-in duration-200">
          <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider mb-2">Quiz History</h3>
          
          <div v-if="quizzes.length > 0" class="space-y-3">
            <div 
              v-for="quiz in quizzes" 
              :key="quiz.id" 
              class="p-3.5 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs flex items-center justify-between"
            >
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-[#FEF3C7] text-[#D97706] flex items-center justify-center shrink-0">
                  <span class="text-base">✨</span>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">{{ quiz.title }}</h4>
                  <p class="text-[10px] text-[#8A9992] mt-0.5">{{ quiz.date }} • {{ quiz.score }}</p>
                </div>
              </div>
              <span class="px-2.5 py-1 rounded-full text-[9px] font-bold bg-[#E8ECE9] text-[#2C3E35]">
                {{ quiz.status }}
              </span>
            </div>
          </div>

          <EmptyState 
            v-else 
            title="No Quizzes Taken" 
            description="User hasn't completed any self-discovery quizzes yet." 
          />
        </div>

        <!-- TAB 5: ACTIVITY HISTORY (Panel 9) -->
        <div v-else-if="activeTab === 'Activity'" class="space-y-3 animate-in fade-in duration-200">
          <div class="flex justify-between items-center mb-1">
            <h3 class="text-xs font-bold text-[#2C3E35] font-serif uppercase tracking-wider">Activity History</h3>
            <span class="text-[10px] text-[#8A9992] bg-white px-2 py-0.5 rounded-lg border border-[#EAE7E1]">All</span>
          </div>

          <div v-if="activityHistory.length > 0" class="space-y-2.5">
            <div 
              v-for="item in activityHistory" 
              :key="item.id" 
              class="flex items-center justify-between p-3 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs"
            >
              <div class="flex items-center gap-3 min-w-0">
                <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-sm shrink-0">
                  <span v-if="item.type === 'Check-in'">📸</span>
                  <span v-else-if="item.type === 'Goals'">🎯</span>
                  <span v-else-if="item.type === 'Quiz'">✨</span>
                  <span v-else>🌿</span>
                </div>
                <div class="min-w-0">
                  <p class="text-xs font-bold text-[#2C3E35] truncate">{{ item.action }}</p>
                  <p class="text-[10px] text-[#8A9992]">{{ item.date }}</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992] shrink-0 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>
          </div>

          <EmptyState 
            v-else 
            title="No Activity Log" 
            description="No recent activity recorded for this user." 
          />
        </div>

      </div>

      <!-- Bottom Nav -->
      <BottomNav />

    </div>

    <!-- Modal Detail Foto (Panel 11) -->
    <PotretDetailModal
      :is-open="isModalOpen"
      :photo="userPotrets[selectedPhotoIndex]"
      :photos="userPotrets"
      :current-index="selectedPhotoIndex"
      @close="isModalOpen = false"
      @prev="prevPhoto"
      @next="nextPhoto"
    />
  </div>
</template>
