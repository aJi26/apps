<script setup>
defineProps({
  title: {
    type: String,
    default: 'No data available',
  },
  description: {
    type: String,
    default: 'This section is empty for now. Check back later.',
  },
});
</script>

<template>
  <div class="flex flex-col items-center justify-center py-12 px-6 text-center">
    <!-- Girl illustration with botanical plants / flowers -->
    <div class="relative w-36 h-36 mb-4 flex items-center justify-center">
      <div class="absolute inset-0 bg-[#E8ECE9]/60 rounded-full blur-xl"></div>
      <svg class="relative w-32 h-32" viewBox="0 0 140 140" fill="none" xmlns="http://www.w3.org/2000/svg">
        <!-- Background soft warm aura -->
        <circle cx="70" cy="70" r="54" fill="#FAF7F2" stroke="#EAE7E1" stroke-width="2"/>
        
        <!-- Foliage / Plants Left & Right -->
        <path d="M28 85 C22 68, 32 50, 42 55 C42 68, 35 80, 28 85 Z" fill="#E8ECE9" stroke="#4A6155" stroke-width="1.2"/>
        <path d="M112 85 C118 68, 108 50, 98 55 C98 68, 105 80, 112 85 Z" fill="#E8ECE9" stroke="#4A6155" stroke-width="1.2"/>
        <path d="M35 105 C25 95, 30 80, 42 85 C40 98, 38 102, 35 105 Z" fill="#DCE5DF" stroke="#4A6155" stroke-width="1"/>
        <path d="M105 105 C115 95, 110 80, 98 85 C100 98, 102 102, 105 105 Z" fill="#DCE5DF" stroke="#4A6155" stroke-width="1"/>
        
        <!-- Hair back -->
        <path d="M48 65 C45 88, 52 110, 56 115 L84 115 C88 110, 95 88, 92 65 Z" fill="#5A4738"/>
        
        <!-- Shoulders / Dress -->
        <path d="M45 118 C52 104, 60 100, 70 100 C80 100, 88 104, 95 118 Z" fill="#2C3E35"/>
        <path d="M60 100 L70 108 L80 100 Z" fill="#FEEAE6"/>

        <!-- Neck -->
        <rect x="66" y="86" width="8" height="15" rx="3" fill="#FADAC7"/>

        <!-- Head / Face -->
        <ellipse cx="70" cy="70" rx="16" ry="19" fill="#FFE2D1"/>
        
        <!-- Hair Front / Bangs -->
        <path d="M54 66 C54 52, 60 46, 70 46 C80 46, 86 52, 86 66 C82 58, 76 57, 70 57 C64 57, 58 58, 54 66 Z" fill="#5A4738"/>
        <path d="M53 66 C52 74, 53 82, 55 86 C56 82, 56 74, 55 66 Z" fill="#5A4738"/>
        <path d="M87 66 C88 74, 87 82, 85 86 C84 82, 84 74, 85 66 Z" fill="#5A4738"/>

        <!-- Facial Features -->
        <!-- Eyes (gentle closed smile) -->
        <path d="M62 70 Q65 73 68 70" stroke="#403227" stroke-width="1.5" stroke-linecap="round"/>
        <path d="M72 70 Q75 73 78 70" stroke="#403227" stroke-width="1.5" stroke-linecap="round"/>
        <!-- Blush -->
        <circle cx="61" cy="74" r="3" fill="#FDB8B0" opacity="0.6"/>
        <circle cx="79" cy="74" r="3" fill="#FDB8B0" opacity="0.6"/>
        <!-- Smile -->
        <path d="M68 78 Q70 80 72 78" stroke="#D96B5B" stroke-width="1.3" stroke-linecap="round"/>

        <!-- Flower hair pin -->
        <circle cx="84" cy="55" r="3.5" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1"/>
        <circle cx="84" cy="55" r="1.5" fill="#F5C067"/>
      </svg>
    </div>

    <!-- Text -->
    <h3 class="text-sm font-bold text-[#2C3E35] mb-1 font-serif">{{ title }}</h3>
    <p class="text-xs text-[#8A9992] max-w-xs">{{ description }}</p>
  </div>
</template>

