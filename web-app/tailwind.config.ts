import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#ff8c00',
          light: '#ffa500',
          dark: '#ff7700',
        },
        secondary: {
          DEFAULT: '#ffb300',
          light: '#ffc933',
          dark: '#ff9900',
        },
        dark: {
          DEFAULT: '#000000',
          lighter: '#1a1a1a',
          light: '#2a2a2a',
        },
      },
    },
  },
  plugins: [],
}
export default config
