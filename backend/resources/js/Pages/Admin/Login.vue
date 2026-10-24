<script setup>
import { ref } from 'vue';
import { Head, useForm } from '@inertiajs/vue3';
import FloralDecor from '@/Components/FloralDecor.vue';


const showSplash = ref(false);

const form = useForm({
  email: 'admin@herspace.com',
  password: 'admin123',
  remember: true,
});

const showPassword = ref(false);

const handleLogin = () => {
  form.post('/admin/login', {
    replace: true, // Mencegah tombol back browser kembali ke halaman login setelah masuk dashboard
  });
};
</script>

<template>
  <Head title="Admin Login — Her Space" />

  <div class="min-h-screen bg-[#FAF7F2] flex justify-center items-center p-0 md:p-6 font-sans select-none">
    
    <!-- Mobile frame container -->
    <div class="w-full max-w-sm bg-[#FAF7F2] md:bg-white md:shadow-2xl md:rounded-[2.5rem] md:border border-[#EAE7E1] relative z-10 flex flex-col justify-between min-h-[640px] h-screen md:h-auto overflow-hidden">
      
      <!-- MODE 1: SPLASH SCREEN (Panel 1) -->
      <div v-if="showSplash" class="relative flex-1 flex flex-col justify-between p-6 bg-gradient-to-b from-[#2C3E35]/15 via-[#FAF7F2]/50 to-[#FAF7F2]">
        <!-- Top decorative area -->
        <div class="pt-12 text-center">
          <FloralDecor variant="sprout" class="mb-4 text-[#2C3E35]" />
          <h1 class="text-3xl font-serif text-[#2C3E35] font-bold tracking-wide italic">Her Space ♡</h1>
          <p class="text-xs text-[#8A9992] tracking-widest uppercase mt-1.5 font-semibold">Admin Monitor</p>
          <p class="text-xs text-[#2C3E35] mt-6 max-w-[200px] mx-auto italic font-serif leading-relaxed">
            Monitoring progress, celebrating every step.
          </p>
        </div>

        <FloralDecor variant="center" class="my-auto opacity-90" />

        <!-- Bottom Sheet / Action -->
        <div class="bg-white rounded-[2rem] p-6 border border-[#EAE7E1] shadow-lg text-center space-y-4">
          <div class="w-10 h-1 bg-[#EAE7E1] rounded-full mx-auto -mt-2 mb-3"></div>
          <FloralDecor variant="sprout" class="text-[#2C3E35]" />
          <button 
            @click="showSplash = false"
            type="button"
            class="w-full py-3.5 bg-[#2C3E35] hover:bg-[#202e27] text-white text-xs font-bold rounded-2xl shadow-md transition transform active:scale-95"
          >
            Login
          </button>
        </div>
      </div>

      <!-- MODE 2: LOGIN FORM (Panel 2) -->
      <div v-else class="flex-1 flex flex-col justify-between p-6 md:p-8">
        <div>
          <!-- Top subtle switcher for Splash Preview -->
          <div class="flex justify-end mb-2">
            <button 
              @click="showSplash = true" 
              type="button" 
              class="text-[10px] text-[#8A9992] hover:text-[#2C3E35] font-medium tracking-wide flex items-center gap-1 transition"
              title="Preview Splash Screen"
            >
              <span>Splash view</span>
              <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
            </button>
          </div>

          <!-- Brand Header -->
          <div class="text-center mt-2 mb-8">
            <h1 class="text-2xl font-serif text-[#2C3E35] tracking-wide font-bold italic">Her Space ♡</h1>
            <p class="text-[11px] text-[#8A9992] tracking-widest uppercase mt-1 font-semibold">Admin Monitor</p>
          </div>

          <!-- Greeting -->
          <div class="mb-6">
            <h2 class="text-lg font-bold text-[#2C3E35] font-serif">Welcome back,</h2>
            <p class="text-xs text-[#8A9992] mt-0.5">please login to continue</p>
          </div>

          <!-- Form Login -->
          <form @submit.prevent="handleLogin" class="space-y-4">
            <div>
              <label class="block text-xs font-semibold text-[#2C3E35] mb-1.5">Email address</label>
              <input 
                v-model="form.email"
                type="email" 
                placeholder="admin@herspace.com"
                class="w-full px-4 py-3 bg-white border border-[#EAE7E1] rounded-2xl text-xs text-[#2C3E35] placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#2C3E35] shadow-xs transition"
                required
              >
              <p v-if="form.errors.email" class="mt-1 text-[11px] text-red-600 font-medium">{{ form.errors.email }}</p>
            </div>

            <div>
              <label class="block text-xs font-semibold text-[#2C3E35] mb-1.5">Password</label>
              <div class="relative">
                <input 
                  v-model="form.password"
                  :type="showPassword ? 'text' : 'password'" 
                  placeholder="••••••••"
                  class="w-full px-4 py-3 bg-white border border-[#EAE7E1] rounded-2xl text-xs text-[#2C3E35] placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#2C3E35] shadow-xs transition pr-10"
                  required
                >
                <button 
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-[#2C3E35] transition"
                >
                  <svg v-if="!showPassword" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                  <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858-5.908a8.88 8.88 0 012.122-.063c4.478 0 8.268 2.943 9.542 7a9.97 9.97 0 01-2.43 3.864M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3l18 18"/></svg>
                </button>
              </div>
            </div>

            <!-- Remember & Forgot -->
            <div class="flex items-center justify-between text-[11px] pt-1">
              <label class="flex items-center text-[#2C3E35] cursor-pointer">
                <input v-model="form.remember" type="checkbox" class="rounded border-[#EAE7E1] text-[#2C3E35] focus:ring-[#2C3E35] mr-2">
                Remember me
              </label>
              <a href="#" class="text-[#8A9992] hover:text-[#2C3E35] font-medium transition">Forgot password?</a>
            </div>

            <!-- Login Button in Forest Green (#2C3E35) -->
            <button 
              type="submit"
              :disabled="form.processing"
              class="w-full py-3.5 bg-[#2C3E35] text-white text-xs font-bold rounded-2xl shadow-md hover:bg-[#202e27] active:scale-[0.99] transition mt-4"
            >
              {{ form.processing ? 'Signing in...' : 'Login' }}
            </button>
          </form>
        </div>

        <!-- Bottom Floral Illustration matching Panel 2 -->
        <div class="pt-6">
          <FloralDecor variant="bottom" />
        </div>
      </div>

    </div>
  </div>
</template>
