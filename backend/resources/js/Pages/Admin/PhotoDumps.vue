<template>
    <div class="p-6 bg-gray-50 min-h-screen">
        <div class="max-w-7xl mx-auto">
            <h1 class="text-2xl font-bold text-gray-800 mb-6">User Photo Dumps Gallery</h1>
            
            <div v-if="photoDumps.length === 0" class="text-gray-500">
                Belum ada foto yang diunggah oleh user.
            </div>

            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                <!-- Looping semua foto -->
                <div v-for="dump in photoDumps" :key="dump.id" class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
                    
                    <!-- Menampilkan Gambar -->
                    <img :src="dump.image_url" alt="Photo Dump" class="w-full h-48 object-cover bg-gray-100" />
                    
                    <div class="p-4">
                        <p class="font-bold text-gray-800 truncate">{{ dump.user_name }}</p>
                        <p class="text-sm text-gray-500 mb-4">{{ dump.date }}</p>
                        
                        <!-- TOMBOL DOWNLOAD (Mengarah ke Route Download) -->
                        <a :href="`/admin/photo-dumps/${dump.id}/download`" 
                           class="block w-full text-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-md transition-colors">
                            Download Asli
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
defineProps({
    photoDumps: {
        type: Array,
        required: true
    }
});
</script>