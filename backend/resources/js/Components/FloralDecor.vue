<script setup>
defineProps({
  variant: {
    type: String,
    default: 'bottom', // 'bottom', 'center', 'sprout'
  },
  className: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div v-if="variant === 'sprout'" :class="className" class="flex justify-center items-center">
    <!-- Delicate sprout icon -->
    <svg class="w-8 h-8 text-[#2C3E35]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
      <path d="M7 20h10" />
      <path d="M12 20v-8" />
      <path d="M12 12c0-4.5 3.5-7 8-7-0.5 4.5-3.5 7-8 7z" fill="#E8ECE9" stroke="#2C3E35" />
      <path d="M12 15c0-3.5-2.5-5.5-6-5.5 0.5 3.5 2.5 5.5 6 5.5z" fill="#E8ECE9" stroke="#2C3E35" />
    </svg>
  </div>

  <div v-else-if="variant === 'center'" :class="className" class="flex flex-col items-center justify-center py-6">
    <!-- Delicate flower bouquet for motivational / empty states -->
    <svg class="w-44 h-36" viewBox="0 0 200 160" fill="none" xmlns="http://www.w3.org/2000/svg">
      <!-- Stems -->
      <path d="M100 150 C95 120, 75 90, 65 65" stroke="#4A6155" stroke-width="1.6" stroke-linecap="round"/>
      <path d="M100 150 C100 115, 100 80, 100 50" stroke="#4A6155" stroke-width="1.6" stroke-linecap="round"/>
      <path d="M100 150 C105 120, 125 90, 135 65" stroke="#4A6155" stroke-width="1.6" stroke-linecap="round"/>
      
      <!-- Leaves -->
      <path d="M88 120 C75 118, 70 110, 72 105 C78 108, 85 114, 88 120 Z" fill="#E8ECE9" stroke="#4A6155" stroke-width="1.2"/>
      <path d="M112 125 C125 123, 130 115, 128 110 C122 113, 115 119, 112 125 Z" fill="#E8ECE9" stroke="#4A6155" stroke-width="1.2"/>
      <path d="M80 95 C68 93, 62 86, 64 81 C70 84, 77 90, 80 95 Z" fill="#E8ECE9" stroke="#4A6155" stroke-width="1.2"/>
      <path d="M120 100 C132 98, 138 91, 136 86 C130 89, 123 95, 120 100 Z" fill="#E8ECE9" stroke="#4A6155" stroke-width="1.2"/>

      <!-- Left Flower: Soft Pink Blossom -->
      <circle cx="65" cy="55" r="7" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1.2"/>
      <circle cx="55" cy="50" r="6" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1.2"/>
      <circle cx="75" cy="50" r="6" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1.2"/>
      <circle cx="60" cy="40" r="6" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1.2"/>
      <circle cx="70" cy="40" r="6" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1.2"/>
      <circle cx="65" cy="47" r="4" fill="#F3D19C"/>

      <!-- Center Flower: Wildflower Daisy -->
      <circle cx="100" cy="35" r="7" fill="#FFFFFF" stroke="#8A9992" stroke-width="1.2"/>
      <circle cx="89" cy="30" r="6" fill="#FFFFFF" stroke="#8A9992" stroke-width="1.2"/>
      <circle cx="111" cy="30" r="6" fill="#FFFFFF" stroke="#8A9992" stroke-width="1.2"/>
      <circle cx="94" cy="20" r="6" fill="#FFFFFF" stroke="#8A9992" stroke-width="1.2"/>
      <circle cx="106" cy="20" r="6" fill="#FFFFFF" stroke="#8A9992" stroke-width="1.2"/>
      <circle cx="100" cy="27" r="4.5" fill="#E8B86D"/>

      <!-- Right Flower: Sage/Cream Bell Flower -->
      <path d="M135 60 C130 48, 140 45, 140 45 C140 45, 150 48, 145 60 Z" fill="#FAF7F2" stroke="#4A6155" stroke-width="1.2"/>
      <circle cx="140" cy="42" r="3" fill="#D98A7E"/>
      <circle cx="130" cy="55" r="4" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1"/>
      <circle cx="148" cy="58" r="4" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1"/>
    </svg>
  </div>

  <div v-else :class="className" class="w-full flex justify-center overflow-hidden pointer-events-none opacity-85">
    <!-- Delicate wildflower border illustration -->
    <svg class="w-full max-w-sm h-20 text-[#8A9992]" viewBox="0 0 360 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <!-- Ground line subtle -->
      <path d="M10 75 Q180 72 350 75" stroke="#EAE7E1" stroke-width="1.5" stroke-dasharray="2 4"/>
      
      <!-- Flower 1 -->
      <path d="M40 75 Q45 55 42 35" stroke="#4A6155" stroke-width="1.3"/>
      <circle cx="42" cy="32" r="4.5" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1"/>
      <circle cx="36" cy="30" r="3.5" fill="#FEEAE6"/>
      <circle cx="48" cy="30" r="3.5" fill="#FEEAE6"/>
      <circle cx="42" cy="25" r="3.5" fill="#FEEAE6"/>
      <circle cx="42" cy="30" r="2.5" fill="#F5C067"/>

      <!-- Leaf 1 -->
      <path d="M41 55 Q30 50 34 44 Q40 50 41 55" fill="#E8ECE9" stroke="#4A6155" stroke-width="1"/>

      <!-- Flower 2 (Tall slender) -->
      <path d="M90 75 Q85 45 92 20" stroke="#4A6155" stroke-width="1.3"/>
      <circle cx="92" cy="18" r="3.5" fill="#FAF7F2" stroke="#4A6155" stroke-width="1"/>
      <circle cx="92" cy="24" r="3" fill="#FAF7F2" stroke="#4A6155" stroke-width="1"/>
      <circle cx="89" cy="30" r="2.5" fill="#E8ECE9"/>
      <circle cx="95" cy="30" r="2.5" fill="#E8ECE9"/>

      <!-- Flower 3 (Wild Daisy) -->
      <path d="M150 75 Q152 50 148 28" stroke="#4A6155" stroke-width="1.4"/>
      <circle cx="148" cy="26" r="4.5" fill="#FFFFFF" stroke="#8A9992" stroke-width="1"/>
      <circle cx="142" cy="24" r="3.5" fill="#FFFFFF"/>
      <circle cx="154" cy="24" r="3.5" fill="#FFFFFF"/>
      <circle cx="148" cy="19" r="3.5" fill="#FFFFFF"/>
      <circle cx="148" cy="24" r="2.8" fill="#E8B86D"/>
      <path d="M150 58 Q162 55 160 48 Q152 52 150 58" fill="#E8ECE9" stroke="#4A6155" stroke-width="1"/>

      <!-- Flower 4 -->
      <path d="M210 75 Q215 52 208 32" stroke="#4A6155" stroke-width="1.3"/>
      <circle cx="208" cy="30" r="4.5" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1"/>
      <circle cx="203" cy="27" r="3.5" fill="#FEEAE6"/>
      <circle cx="213" cy="27" r="3.5" fill="#FEEAE6"/>
      <circle cx="208" cy="22" r="3.5" fill="#FEEAE6"/>
      <circle cx="208" cy="28" r="2.5" fill="#F5C067"/>
      <path d="M211 50 Q200 46 203 40 Q208 45 211 50" fill="#E8ECE9" stroke="#4A6155" stroke-width="1"/>

      <!-- Flower 5 (Tall) -->
      <path d="M270 75 Q268 45 272 18" stroke="#4A6155" stroke-width="1.3"/>
      <circle cx="272" cy="16" r="3.5" fill="#FAF7F2" stroke="#4A6155" stroke-width="1"/>
      <circle cx="272" cy="22" r="3" fill="#FAF7F2" stroke="#4A6155" stroke-width="1"/>
      <circle cx="269" cy="28" r="2.5" fill="#E8ECE9"/>
      <circle cx="275" cy="28" r="2.5" fill="#E8ECE9"/>
      <path d="M270 54 Q282 50 280 43 Q273 47 270 54" fill="#E8ECE9" stroke="#4A6155" stroke-width="1"/>

      <!-- Flower 6 (Blossom) -->
      <path d="M320 75 Q318 52 322 35" stroke="#4A6155" stroke-width="1.3"/>
      <circle cx="322" cy="33" r="4.5" fill="#FEEAE6" stroke="#D98A7E" stroke-width="1"/>
      <circle cx="316" cy="30" r="3.5" fill="#FEEAE6"/>
      <circle cx="328" cy="30" r="3.5" fill="#FEEAE6"/>
      <circle cx="322" cy="25" r="3.5" fill="#FEEAE6"/>
      <circle cx="322" cy="31" r="2.5" fill="#F5C067"/>
    </svg>
  </div>
</template>

