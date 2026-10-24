<script setup>
import { ref, reactive, watch } from 'vue';
import { Head, Link, router } from '@inertiajs/vue3';
import BottomNav from '@/Components/BottomNav.vue';

const props = defineProps({
  adminProfile: {
    type: Object,
    required: true,
  },
  accounts: {
    type: Array,
    default: () => [],
  },
});

// Navigation state: settings, profile, accounts, notifications
const currentView = ref('settings');
const isEditingProfile = ref(false);

// ---------------------------------------------------------------------
// 1. EDIT PROFIL & UPLOAD FOTO (REAL DATABASE)
// ---------------------------------------------------------------------
const avatarPreview = ref(props.adminProfile.avatar);
const avatarFile = ref(null);

const profileForm = reactive({
  name: props.adminProfile.name || 'Admin Her Space',
  email: props.adminProfile.email || 'admin@herspace.com',
  phone: props.adminProfile.phone || '+62 812 3456 7890',
  birthday: props.adminProfile.birthday || '1998-02-14',
});

const handlePhotoChange = (e) => {
  const file = e.target.files[0];
  if (file) {
    avatarFile.value = file;
    avatarPreview.value = URL.createObjectURL(file);
  }
};

const handleSaveProfile = () => {
  router.post('/admin/profile', {
    name: profileForm.name,
    email: profileForm.email,
    phone: profileForm.phone,
    birthday: profileForm.birthday,
    avatar: avatarFile.value,
  }, {
    onSuccess: () => {
      isEditingProfile.value = false;
      alert('Profil berhasil diperbarui!');
    },
    onError: (errors) => {
      alert(Object.values(errors).join('\n'));
    }
  });
};

// ---------------------------------------------------------------------
// 2. FULL CRUD KELOLA AKUN (USER & ADMIN) - REAL DATABASE
// ---------------------------------------------------------------------
const showAddAccountModal = ref(false);
const editingAccount = ref(null);

const accountForm = reactive({
  id: null,
  name: '',
  email: '',
  role: 'User',
  status: 'Active',
});

const openAddAccountModal = () => {
  editingAccount.value = null;
  accountForm.id = null;
  accountForm.name = '';
  accountForm.email = '';
  accountForm.role = 'User';
  accountForm.status = 'Active';
  showAddAccountModal.value = true;
};

const openEditAccountModal = (acc) => {
  editingAccount.value = acc;
  accountForm.id = acc.id;
  accountForm.name = acc.name;
  accountForm.email = acc.email;
  accountForm.role = acc.role;
  accountForm.status = acc.status;
  showAddAccountModal.value = true;
};

const saveAccount = () => {
  if (!accountForm.name || !accountForm.email) {
    alert('Mohon isi nama dan email.');
    return;
  }

  if (editingAccount.value) {
    // UPDATE AKUN VIA POST
    router.post(`/admin/users/${accountForm.id}/update`, {
      name: accountForm.name,
      email: accountForm.email,
    }, {
      onSuccess: () => {
        showAddAccountModal.value = false;
        alert('Akun berhasil diperbarui!');
      },
      onError: (errors) => {
        alert(Object.values(errors).join('\n'));
      }
    });
  } else {
    // TAMBAH AKUN BARU
    router.post('/admin/users', {
      name: accountForm.name,
      email: accountForm.email,
      password: 'password123',
      is_active: true,
    }, {
      onSuccess: () => {
        showAddAccountModal.value = false;
        alert('Akun baru berhasil ditambahkan!');
      },
      onError: (errors) => {
        alert(Object.values(errors).join('\n'));
      }
    });
  }
};

const deleteAccount = (id) => {
  if (confirm('Apakah Anda yakin ingin menghapus akun ini secara permanen?')) {
    // HAPUS AKUN VIA POST
    router.post(`/admin/users/${id}/delete`, {}, {
      onSuccess: () => alert('Akun berhasil dihapus!'),
      onError: (errors) => {
        alert(Object.values(errors).join('\n'));
      }
    });
  }
};

// ---------------------------------------------------------------------
// 4. NOTIFICATIONS (DENGAN LOCALSTORAGE)
// ---------------------------------------------------------------------
const savedNotifs = JSON.parse(localStorage.getItem('admin_notifications') || 'null');

const notifications = reactive(savedNotifs || {
  checkinAlerts: true,
  goalReminders: true,
  systemUpdates: true,
});

// Otomatis simpan ke localStorage setiap ada sakelar notifikasi yang diubah
watch(notifications, (newVal) => {
  localStorage.setItem('admin_notifications', JSON.stringify(newVal));
}, { deep: true });

const handleLogout = () => {
  if (confirm('Apakah Anda yakin ingin keluar?')) {
    router.post('/admin/logout');
  }
};
</script>

<template>
  <Head title="Settings — Her Space Monitor" />

  <div class="min-h-screen flex justify-center p-0 md:p-6 font-sans select-none bg-[#FAF7F2]">
    <div class="w-full max-w-md bg-[#FAF7F2] text-[#2C3E35] md:bg-white md:shadow-xl md:rounded-[2.5rem] md:border border-[#EAE7E1] overflow-hidden flex flex-col h-screen md:h-[840px] justify-between">
      
      <!-- Content Area -->
      <div class="p-6 overflow-y-auto flex-1">
        
        <!-- ================= 1. MENU UTAMA SETTINGS ================= -->
        <div v-if="currentView === 'settings'" class="space-y-5 animate-in fade-in duration-200">
          
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <Link href="/admin/dashboard" class="p-1 -ml-1 hover:opacity-70 transition text-[#2C3E35]">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
              </Link>
              <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Settings</h1>
            </div>
          </div>

          <!-- Card Profil Admin -->
          <div class="flex items-center gap-4 p-4 border rounded-3xl shadow-xs transition bg-white text-[#2C3E35] border-[#EAE7E1]">
            <img :src="avatarPreview" alt="Admin Avatar" class="w-14 h-14 rounded-full object-cover border border-[#EAE7E1]">
            <div class="flex-1 min-w-0">
              <h2 class="text-sm font-bold font-serif truncate text-[#2C3E35]">{{ profileForm.name }}</h2>
              <p class="text-xs truncate mt-0.5 text-[#8A9992]">{{ profileForm.email }}</p>
              <span class="inline-block mt-1.5 px-2.5 py-0.5 rounded-full text-[9px] font-bold bg-[#E8ECE9] text-[#2C3E35]">
                {{ adminProfile.role || 'Super Admin' }}
              </span>
            </div>
          </div>

          <!-- List Opsi Settings -->
          <div class="space-y-3">
            
            <!-- Menu Profile & Account -->
            <div 
              @click="currentView = 'profile'"
              class="p-4 border rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:shadow-sm transition bg-white text-[#2C3E35] border-[#EAE7E1]"
            >
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#E8ECE9] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Profile Saya</h4>
                  <p class="text-[10px] text-[#8A9992]">Edit foto & informasi diri</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>

            <!-- Menu Kelola Akun -->
            <div 
              @click="currentView = 'accounts'"
              class="p-4 border rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:shadow-sm transition bg-white text-[#2C3E35] border-[#EAE7E1]"
            >
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Kelola Akun</h4>
                  <p class="text-[10px] text-[#8A9992]">Tambah, edit, & hapus akun user/admin</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>

            <!-- Menu Notifications -->
            <div 
              @click="currentView = 'notifications'"
              class="p-4 border rounded-2xl shadow-xs flex items-center justify-between cursor-pointer hover:shadow-sm transition bg-white text-[#2C3E35] border-[#EAE7E1]"
            >
              <div class="flex items-center gap-3.5">
                <div class="w-9 h-9 rounded-xl bg-[#FAF7F2] border border-[#EAE7E1] text-[#2C3E35] flex items-center justify-center shrink-0">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                </div>
                <div>
                  <h4 class="text-xs font-bold text-[#2C3E35]">Notifications</h4>
                  <p class="text-[10px] text-[#8A9992]">Pengaturan pengingat & sistem</p>
                </div>
              </div>
              <svg class="w-4 h-4 text-[#8A9992]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/></svg>
            </div>

          </div>

          <!-- Tombol Log Out -->
          <button 
            @click="handleLogout"
            type="button" 
            class="w-full py-3.5 px-4 bg-[#FEEAE6] hover:bg-[#fedbd5] text-[#D96B5B] rounded-2xl text-xs font-bold transition flex items-center justify-center gap-2 mt-4 cursor-pointer"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
            Log Out
          </button>
        </div>

        <!-- ================= 2. TAB PROFILE & EDIT FOTO ================= -->
        <div v-else-if="currentView === 'profile'" class="space-y-5 animate-in fade-in duration-200">
          <div class="flex items-center justify-between">
            <button @click="currentView = 'settings'" type="button" class="p-1 -ml-1 hover:opacity-70 transition text-[#2C3E35]">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </button>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Profile Saya</h1>
            <div class="w-6"></div>
          </div>

          <!-- Foto & Input File Upload -->
          <div class="border rounded-3xl p-6 text-center shadow-xs flex flex-col items-center relative bg-white text-[#2C3E35] border-[#EAE7E1]">
            <div class="relative mb-3 group">
              <img :src="avatarPreview" alt="Admin Avatar" class="w-20 h-20 rounded-full object-cover shadow-sm border-2 border-[#EAE7E1]">
              <label v-if="isEditingProfile" class="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center cursor-pointer text-white text-[10px] font-bold opacity-0 group-hover:opacity-100 transition">
                Ganti Foto
                <input type="file" accept="image/*" class="hidden" @change="handlePhotoChange">
              </label>
            </div>

            <h2 class="text-base font-bold font-serif text-[#2C3E35]">{{ profileForm.name }}</h2>
            <p class="text-xs mt-0.5 text-[#8A9992]">{{ profileForm.email }}</p>

            <button 
              type="button"
              @click="isEditingProfile = !isEditingProfile"
              class="mt-4 px-5 py-2 bg-[#FAF7F2] border border-[#EAE7E1] hover:bg-[#E8ECE9] text-[#2C3E35] text-xs font-semibold rounded-full shadow-xs transition"
            >
              {{ isEditingProfile ? 'Batal Edit' : 'Edit Profil' }}
            </button>
          </div>

          <!-- Form Edit Profil Admin -->
          <div v-if="isEditingProfile" class="border rounded-3xl p-5 shadow-xs space-y-4 bg-white text-[#2C3E35] border-[#EAE7E1]">
            <h3 class="text-xs font-bold uppercase font-serif text-[#2C3E35]">Edit Informasi</h3>
            
            <div>
              <label class="block text-[11px] font-semibold mb-1 text-[#8A9992]">Nama Lengkap</label>
              <input v-model="profileForm.name" type="text" class="w-full px-3 py-2 bg-[#FAF7F2] border border-[#EAE7E1] rounded-xl text-xs text-[#2C3E35] focus:outline-none">
            </div>

            <div>
              <label class="block text-[11px] font-semibold mb-1 text-[#8A9992]">Email</label>
              <input v-model="profileForm.email" type="email" class="w-full px-3 py-2 bg-[#FAF7F2] border border-[#EAE7E1] rounded-xl text-xs text-[#2C3E35] focus:outline-none">
            </div>

            <div>
              <label class="block text-[11px] font-semibold mb-1 text-[#8A9992]">Telepon</label>
              <input v-model="profileForm.phone" type="text" class="w-full px-3 py-2 bg-[#FAF7F2] border border-[#EAE7E1] rounded-xl text-xs text-[#2C3E35] focus:outline-none">
            </div>

            <div>
              <label class="block text-[11px] font-semibold mb-1 text-[#8A9992]">Tanggal Lahir</label>
              <input v-model="profileForm.birthday" type="date" class="w-full px-3 py-2 bg-[#FAF7F2] border border-[#EAE7E1] rounded-xl text-xs text-[#2C3E35] focus:outline-none">
            </div>

            <button @click="handleSaveProfile" class="w-full py-2.5 bg-[#2C3E35] text-white text-xs font-bold rounded-xl shadow-xs hover:bg-[#202e27]">
              Simpan Perubahan
            </button>
          </div>

          <!-- Mode Read-Only -->
          <div v-else class="border rounded-3xl p-5 shadow-xs space-y-4 bg-white text-[#2C3E35] border-[#EAE7E1]">
            <div class="flex items-center gap-3.5">
              <span class="text-base">👤</span>
              <div>
                <span class="text-[10px] block text-[#8A9992]">Nama Lengkap</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ profileForm.name }}</span>
              </div>
            </div>

            <div class="flex items-center gap-3.5">
              <span class="text-base">✉️</span>
              <div>
                <span class="text-[10px] block text-[#8A9992]">Email</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ profileForm.email }}</span>
              </div>
            </div>

            <div class="flex items-center gap-3.5">
              <span class="text-base">📞</span>
              <div>
                <span class="text-[10px] block text-[#8A9992]">Telepon</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ profileForm.phone }}</span>
              </div>
            </div>

            <div class="flex items-center gap-3.5">
              <span class="text-base">🎂</span>
              <div>
                <span class="text-[10px] block text-[#8A9992]">Tanggal Lahir</span>
                <span class="text-xs font-bold text-[#2C3E35]">{{ profileForm.birthday }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- ================= 3. TAB KELOLA AKUN ================= -->
        <div v-else-if="currentView === 'accounts'" class="space-y-5 animate-in fade-in duration-200">
          <div class="flex items-center justify-between">
            <button @click="currentView = 'settings'" type="button" class="p-1 -ml-1 hover:opacity-70 transition text-[#2C3E35]">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </button>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Kelola Akun</h1>
            <button @click="openAddAccountModal" class="px-3 py-1 bg-[#2C3E35] text-white text-xs font-bold rounded-xl shadow-xs">
              + Tambah
            </button>
          </div>

          <div class="border rounded-3xl p-4 shadow-xs space-y-3 bg-white text-[#2C3E35] border-[#EAE7E1]">
            <h3 class="text-xs font-bold font-serif uppercase tracking-wider mb-2 text-[#2C3E35]">Daftar Akun Pengguna</h3>
            
            <div 
              v-for="acc in props.accounts" 
              :key="acc.id"
              class="p-3.5 bg-[#FAF7F2] border border-[#EAE7E1] rounded-2xl flex items-center justify-between"
            >
              <div class="min-w-0 flex-1 pr-2">
                <div class="flex items-center gap-2">
                  <h4 class="text-xs font-bold text-[#2C3E35] truncate">{{ acc.name }}</h4>
                  <span class="px-2 py-0.2 rounded-full text-[8px] font-bold bg-[#E8ECE9] text-[#2C3E35]">{{ acc.role }}</span>
                </div>
                <p class="text-[10px] text-[#8A9992] truncate mt-0.5">{{ acc.email }}</p>
              </div>

              <!-- Action CRUD Buttons -->
              <div class="flex items-center gap-1.5 shrink-0">
                <button @click="openEditAccountModal(acc)" class="p-1.5 text-xs text-[#2C3E35] bg-white border rounded-lg hover:bg-gray-50">
                  ✏️
                </button>
                <button @click="deleteAccount(acc.id)" class="p-1.5 text-xs text-red-600 bg-white border rounded-lg hover:bg-red-50">
                  🗑️
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- ================= 4. TAB NOTIFICATIONS ================= -->
        <div v-else-if="currentView === 'notifications'" class="space-y-5 animate-in fade-in duration-200">
          <div class="flex items-center justify-between">
            <button @click="currentView = 'settings'" type="button" class="p-1 -ml-1 hover:opacity-70 transition text-[#2C3E35]">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7"/></svg>
            </button>
            <h1 class="text-xl font-serif font-bold text-[#2C3E35]">Notifications</h1>
            <div class="w-6"></div>
          </div>

          <div class="border rounded-3xl p-5 shadow-xs space-y-4 bg-white text-[#2C3E35] border-[#EAE7E1]">
            <div class="flex items-center justify-between">
              <div>
                <h4 class="text-xs font-bold text-[#2C3E35]">Notifikasi Check-in</h4>
                <p class="text-[10px] text-[#8A9992]">Alert saat user mengunggah potret harian</p>
              </div>
              <input v-model="notifications.checkinAlerts" type="checkbox" class="w-4 h-4 accent-[#2C3E35]">
            </div>

            <div class="flex items-center justify-between">
              <div>
                <h4 class="text-xs font-bold text-[#2C3E35]">Pengingat Goals</h4>
                <p class="text-[10px] text-[#8A9992]">Pemberitahuan perubahan pencapaian target</p>
              </div>
              <input v-model="notifications.goalReminders" type="checkbox" class="w-4 h-4 accent-[#2C3E35]">
            </div>

            <div class="flex items-center justify-between">
              <div>
                <h4 class="text-xs font-bold text-[#2C3E35]">Pembaruan Sistem</h4>
                <p class="text-[10px] text-[#8A9992]">Informasi pemeliharaan server & database</p>
              </div>
              <input v-model="notifications.systemUpdates" type="checkbox" class="w-4 h-4 accent-[#2C3E35]">
            </div>
          </div>
        </div>

      </div>

      <BottomNav />
    </div>

    <!-- MODAL CRUD TAMBAH / EDIT AKUN -->
    <div v-if="showAddAccountModal" class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-3xl max-w-sm w-full p-5 space-y-4">
        <h3 class="font-bold text-sm text-[#2C3E35]">{{ editingAccount ? 'Edit Akun' : 'Tambah Akun Baru' }}</h3>
        
        <div>
          <label class="block text-[11px] font-semibold text-[#8A9992] mb-1">Nama Pengguna</label>
          <input v-model="accountForm.name" type="text" placeholder="Masukkan nama" class="w-full px-3 py-2 bg-[#FAF7F2] border border-[#EAE7E1] rounded-xl text-xs text-[#2C3E35] focus:outline-none">
        </div>

        <div>
          <label class="block text-[11px] font-semibold text-[#8A9992] mb-1">Email</label>
          <input v-model="accountForm.email" type="email" placeholder="user@herspace.com" class="w-full px-3 py-2 bg-[#FAF7F2] border border-[#EAE7E1] rounded-xl text-xs text-[#2C3E35] focus:outline-none">
        </div>

        <div class="flex gap-2 pt-2">
          <button @click="showAddAccountModal = false" class="flex-1 py-2 bg-gray-100 text-gray-700 rounded-xl text-xs font-bold">Batal</button>
          <button @click="saveAccount" class="flex-1 py-2 bg-[#2C3E35] text-white rounded-xl text-xs font-bold">Simpan</button>
        </div>
      </div>
    </div>

  </div>
</template>