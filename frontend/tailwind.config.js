/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],

  theme: {
    extend: {
      colors: {
        /* ── Brand tokens (from theme.css) ── */
        brand: {
          DEFAULT: "var(--color-primary)",
          light:   "var(--color-primary-light)",
          dark:    "var(--color-primary-dark)",
          50:      "var(--color-primary-50)",
          100:     "var(--color-primary-100)",
        },
        accent: {
          DEFAULT: "var(--color-accent)",
          hover:   "var(--color-accent-hover)",
          active:  "var(--color-accent-active)",
          50:      "var(--color-accent-50)",
        },
        surface: {
          DEFAULT: "var(--color-surface)",
          hover:   "var(--color-surface-hover)",
          soft:    "var(--color-bg-soft)",
          muted:   "var(--color-bg-muted)",
        },

        /* ── Legacy aliases (keep existing classes working) ── */
        "light-green": "#3FCA93",
        "turquoise-blue": "#33b3ae",
        secondary: "#868686",
        beige: "#FAF9F6",
        "rose-modified": "#ffc3ae",
        "lightgreen-modified": "#f1f6be",
      },
      fontFamily: {
        display: ["var(--font-display)"],
        body:    ["var(--font-body)"],
      },
      borderRadius: {
        card:  "var(--radius-xl)",
        btn:   "var(--radius-md)",
      },
      boxShadow: {
        card:     "var(--shadow-card)",
        soft:     "var(--shadow-md)",
        elevated: "var(--shadow-lg)",
        /* Legacy aliases */
        "3xl": "0px 4px 4px 0px rgba(0, 0, 0, 0.25)",
        custom:
          "rgba(50, 50, 93, 0.25) 0px 13px 27px -5px, rgba(0, 0, 0, 0.3) 0px 8px 16px -8px",
      },
      spacing: {
        navbar: "var(--navbar-height)",
      },
      maxWidth: {
        content: "var(--content-max-width)",
      },
    },
  },
  plugins: [],
};
