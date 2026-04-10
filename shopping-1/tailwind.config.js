/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts}'],
  theme: {
    extend: {
      colors: {
        msf: {
          // Primary navy
          navy:     '#E30613',
          'navy-80':'#C4050F',
          'navy-60':'#a00410',
          // Accents
          red:      '#E30613',
          // UI greys
          bg:       '#F4F7FE',
          'bg-alt': '#EEF2FB',
          border:   '#DDE3F0',
          muted:    '#6B7A9F',
          // Status
          green:    '#22C55E',
          amber:    '#F59E0B',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif']
      },
      boxShadow: {
        card: '0 1px 3px 0 rgba(0,32,96,0.06), 0 1px 2px -1px rgba(0,32,96,0.04)'
      }
    }
  },
  plugins: []
}
