/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
    './storage/framework/views/*.php',
    './resources/views/**/*.blade.php',
    './resources/js/**/*.vue',
  ],
  theme: {
    extend: {
      colors: {
        'her-bg': '#FAF7F2',
        'her-dark': '#2C3E35',
        'her-sage': '#4A6155',
        'her-sage-light': '#E8ECE9',
        'her-pink': '#FEEAE6',
        'her-border': '#EAE7E1',
        'her-muted': '#8A9992',
      },
      fontFamily: {
        serif: ['Playfair Display', 'serif'],
        sans: ['Plus Jakarta Sans', 'sans-serif'],
      },
      borderRadius: {
        '3xl': '24px',
        '2xl': '20px',
      }
    },
  },
  plugins: [],
};