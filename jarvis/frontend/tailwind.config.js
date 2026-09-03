/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{js,ts,jsx,tsx}", "./components/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        bg: "#0B0E14",
        surface: "#131722",
        surface2: "#1A2030",
        border: "#232A3B",
        textPrimary: "#E8EAED",
        textSecondary: "#9AA4B2",
        accent: "#6C5CE7",
        accentSoft: "#241F45",
        toolAccent: "#22D3A8",
      },
      fontFamily: {
        display: ["var(--font-space-grotesk)", "sans-serif"],
        body: ["var(--font-inter)", "sans-serif"],
      },
    },
  },
  plugins: [],
};
