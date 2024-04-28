/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],

  theme: {
    extend: {
      colors: {
        "light-green": "#3FCA93",
        "turquoise-blue": "#33b3ae",
        beige: "#FAF9F6",
        "rose-modified": "#ffc3ae",
        "lightgreen-modified": "#f1f6be",
      },
      boxShadow: {
        "3xl": "0px 4px 4px 0px rgba(0, 0, 0, 0.25)",
        custom:
          "rgba(50, 50, 93, 0.25) 0px 13px 27px -5px, rgba(0, 0, 0, 0.3) 0px 8px 16px -8px",
      },
    },
  },
  plugins: [],
};
