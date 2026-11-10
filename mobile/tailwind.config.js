/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        page: "#FFFCF3",
        card: "#FFFFFF",
        ink: {
          DEFAULT: "#4A3428",
          secondary: "#5E4636",
          muted: "#7A6255",
          accent: "#6E4B00",
        },
        btn: {
          DEFAULT: "#FFE89A",
          border: "#E6C24F",
        },
        soft: "#FFF6D6",
        line: {
          DEFAULT: "#F1E6C6",
          strong: "#E8D7A4",
        },
        navtile: "#FFF1C9",
        unchecked: "#D4C4B8",
        danger: "#C0392B",
      },
      borderRadius: {
        card: "12px",
        "card-lg": "16px",
      },
    },
  },
  plugins: [],
};
