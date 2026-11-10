/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        page: "#FFFBF5",
        card: "#FFFFFF",
        text: {
          DEFAULT: "#4A3428",
          2: "#5E4636",
        },
        muted: "#7A6255",
        ink: "#5A4030",
        btn: {
          DEFAULT: "#FFF1E6",
          border: "#F2CFB4",
        },
        soft: "#F6EFE6",
        line: {
          DEFAULT: "#F0E6DA",
          2: "#E6D9C8",
        },
        tile: "#DCEBFF",
        media: "#F3EDE6",
        heart: "#E2557A",
        unchecked: "#D4C4B8",
        danger: "#C0392B",
      },
    },
  },
  plugins: [],
};
