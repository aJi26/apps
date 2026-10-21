<script setup>
import { ref } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';

const props = defineProps({
  adminProfile: {
    type: Object,
    required: true,
  },
});

const currentView = ref('settings'); // 'settings' (Panel 15) or 'profile' (Panel 16)
const isEditing = ref(false);

const handleLogout = () => {
  if (confirm('Are you sure you want to log out?')) {
    router.post('/admin/logout');
  }
};
</script>

<template>
  <Head :title="currentView === 'profile' ? 'Profile — Her Space' : 'Settings — Her Space'" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center p-0 md:p-6 font-sans select-none">
    <div class="w-full max-w-md bg-[#FAF7F2] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1">
        
        <!-- ================= MODE 1: SETTINGS (Panel 15) ================= -->
        <div v-if="currentView === 'settings'" class="space-y-5 animate-in fade-in duration-200">
          
          <!-- Header (Panel 15) -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <Link href="/admin/dashboard" class="p-1 -ml-1 text-[#2C3E35] hover:opacity-70 transition">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
              </Link>
              <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Settings</h1>
            </div>
            <div class="w-6"></div>
          </div>

          <!-- Profile Header Card (Clickable to Profile View) -->
          <div 
            @click="currentView = 'profile'"
            class="flex items-center gap-4 p-4 bg-white border border-[#EAE7E1] rounded-3xl shadow-xs hover:border-[#2C3E35]/40 transition cursor-pointer"
          >
            <img :src="adminProfile.avatar" alt="Admin Avatar" class="w-14 h-14 rounded-full object-cover border border-[#EAE7E1]">
            <div class="flex-1 min-w-0">
              <h2 class="text-sm font-bold text-[#2C3E35] font-serif truncate">{{ adminProfile.name }}</h2>
              <p class="text-xs text-[#8A9992] truncate mt-0.5">{{ adminProfile.email }}</p>
              <span class="inline-block mt-1.5 px-2.5 py-0.5 rounded-full text-[9px] font-bold bg-[#E8ECE9] text-[#2C3E35]">
                {{ adminProfile.role }}
              </span>
            </div>
            <svg class="w-5 h-5 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
          </div>

          <!-- Settings List Options (Panel 15) -->
          <div class="space-y-3">
            
            <!-- 1. Profile & Account -->
            <div 
              @click="currentView = 'profile'"
              class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:border-[#2C3E35]/30 hover:shadow-sm transition"
            >
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#E8ECE9] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Profile & Account</h4>
                  <p class="text-[10px] text-[#8A9992]">Manage your profile information</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>

            <!-- 2. Notifications -->
            <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:border-[#2C3E35]/30 hover:shadow-sm transition">
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Notifications</h4>
                  <p class="text-[10px] text-[#8A9992]">App and email notifications</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>

            <!-- 3. Privacy & Security -->
            <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:border-[#2C3E35]/30 hover:shadow-sm transition">
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Privacy & Security</h4>
                  <p class="text-[10px] text-[#8A9992]">Password, session, and data</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>

            <!-- 4. Appearance -->
            <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:border-[#2C3E35]/30 hover:shadow-sm transition">
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Appearance</h4>
                  <p class="text-[10px] text-[#8A9992]">Light / Cream theme</p>
                </div>
              </div>
              <span class="text-[10px] font-semibold text-[#2C3E35] bg-[#E8ECE9] px-2 py-0.5 rounded-full">Light</span>
            </div>

            <!-- 5. Help & Support -->
            <div class="p-4 bg-white border border-[#EAE7E1] rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:border-[#2C3E35]/30 hover:shadow-sm transition">
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Help & Support</h4>
                  <p class="text-[10px] text-[#8A9992]">FAQs and system report</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>

          </div>

          <!-- Log Out Button -->
          <button 
            @click="handleLogout"
            type="button" 
            class="w-full py-3.5 px-4 bg-[#FEEAE6] hover:bg-[#fedbd5] text-[#D96B5B] rounded-2xl text-xs font-bold transition flex items-center justify-center gap-2 mt-4"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
            Log Out
          </button>
        </div>

        <!-- ================= MODE 2: PROFILE (Panel 16) ================= -->
        <div v-else class="space-y-6 animate-in fade-in duration-200">
          
          <!-- Header (Panel 16) -->
          <div class="flex items-center justify-between">
            <button @click="currentView = 'settings'" type="button" class="text-[#2C3E35] p-1 -ml-1 hover:opacity-70 transition">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </button>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Profile</h1>
            <div class="w-6"></div>
          </div>

          <!-- Profile Big Avatar Card (Panel 16) -->
          <div class="bg-white border border-[#EAE7E1] rounded-3xl p-6 text-center shadow-xs flex flex-col items-center">
            <div class="relative mb-3">
              <img :src="adminProfile.avatar" alt="Admin Avatar" class="w-20 h-20 rounded-full object-cover shadow-sm border-2 border-[#EAE7E1]">
              <div class="absolute bottom-0 right-0 w-6 h-6 rounded-full bg-[#2C3E35] text-white flex items-center justify-center border-2 border-white shadow-xs">
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
              </div>
            </div>

            <h2 class="text-base font-bold text-[#2C3E35] font-serif">{{ adminProfile.name }}</h2>
            <p class="text-xs text-[#8A9992] mt-0.5">{{ adminProfile.email }}</p>

            <button 
              type="button"
              @click="isEditing = !isEditing"
              class="mt-4 px-5 py-2 bg-[#FAF7F2] border border-[#EAE7E1] hover:bg-[#E8ECE9] text-[#2C3E35] text-xs font-semibold rounded-full shadow-xs transition"
            >
              {{ isEditing ? 'Done' : 'Edit Profile' }}
            </button>
          </div>

          <!-- Profile Details List (Panel 16) -->
          <div class="bg-white border border-[#EAE7E1] rounded-3xl p-5 shadow-xs space-y-4">
            
            <!-- Full Name -->
            <div class="flex items-center gap-3.5">
              <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
              </div>
              <div>
                <span class="text-[10px] text-[#8A9992] font-medium block">Full Name</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ adminProfile.name }}</span>
              </div>
            </div>

            <!-- Birthday -->
            <div class="flex items-center gap-3.5">
              <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 002-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
              </div>
              <div>
                <span class="text-[10px] text-[#8A9992] font-medium block">Birthday</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ adminProfile.birthday || '14 February 1998' }}</span>
              </div>
            </div>

            <!-- Email -->
            <div class="flex items-center gap-3.5">
              <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
              </div>
              <div>
                <span class="text-[10px] text-[#8A9992] font-medium block">Email</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ adminProfile.email }}</span>
              </div>
            </div>

            <!-- Phone -->
            <div class="flex items-center gap-3.5">
              <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
              </div>
              <div>
                <span class="text-[10px] text-[#8A9992] font-medium block">Phone</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ adminProfile.phone || '+62 812 3456 7890' }}</span>
              </div>
            </div>

            <!-- Joined -->
            <div class="flex items-center gap-3.5">
              <div class="w-8 h-8 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] flex items-center justify-center text-[#2C3E35] shrink-0">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
              </div>
              <div>
                <span class="text-[10px] text-[#8A9992] font-medium block">Joined</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ adminProfile.joined || '12 October 2025' }}</span>
              </div>
            </div>

          </div>

        </div>

      </div>

      <!-- Bottom Nav -->
      <BottomNav />

    </div>
  </div>
</template>
