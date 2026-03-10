# VetStation UI Unification & Polish Guide

> A practical, drop-in guide for achieving visual harmony across the entire Angular app.
> Every code block below is written for **your** project structure (Angular 17, Tailwind 3, Bootstrap offcanvas, standalone components).

---

## Table of Contents

1. [Audit Summary — What Needs Fixing](#1-audit-summary)
2. [Design Tokens — Global Theme File](#2-design-tokens)
3. [Typography System](#3-typography-system)
4. [Spacing & Layout Rules](#4-spacing-layout)
5. [Unified Button System](#5-button-system)
6. [Card Components](#6-card-components)
7. [Angular Animations — Page Transitions](#7-page-transitions)
8. [Angular Animations — Component Animations](#8-component-animations)
9. [Interactive Micro-Interactions](#9-micro-interactions)
10. [Responsive Polish](#10-responsive-polish)
11. [Refactoring Checklist](#11-refactoring-checklist)

---

## 1. Audit Summary — What Needs Fixing {#1-audit-summary}

### Current Issues Found

**Mixed styling approaches:**
- Tailwind utilities, vanilla CSS, Bootstrap classes, and inline styles all used simultaneously
- Example: `login.component.css` has full vanilla CSS while `my-appointments.component.html` is pure Tailwind

**No design tokens:**
- Colors hardcoded everywhere: `#3FCA93`, `#33b3ae`, `#FAF9F6`, `#44b689`, `emerald-400`, `emerald-500`, `emerald-600`
- At least 4 different greens used for primary actions

**Inconsistent typography:**
- Three font families: `Italiana`, `Inter`, `Roboto`
- `header-title` uses `font-['Roboto']`, navbar uses `Italiana`, login uses `Inter`
- No heading hierarchy — `h1` through `h4` used arbitrarily

**No animation system:**
- Only the toaster has `@angular/animations`
- No page transitions, no list stagger, no entrance effects

**Inconsistent spacing:**
- Login box: `padding: 1rem`, Cards: `p-4` / `p-5` / `p-6`, Tables: `padding: 18px 22px`
- Margins: `m-1`, `m-3`, `mx-14 my-4` — no rhythm

---

## 2. Design Tokens — Global Theme File {#2-design-tokens}

### Step 1: Create `src/styles/theme.css`

Create a CSS custom properties file that becomes the single source of truth. This works alongside Tailwind without conflict.

**File: `src/styles/theme.css`**

```css
/* ═══════════════════════════════════════════════════════════
   VetStation Design Tokens
   Single source of truth for the entire application.
   ═══════════════════════════════════════════════════════════ */

:root {
  /* ─── Brand Colors ─────────────────────────────────────── */
  --color-primary:        #33b3ae;   /* Turquoise — main brand */
  --color-primary-light:  #5cccc7;
  --color-primary-dark:   #28918d;
  --color-primary-50:     rgba(51, 179, 174, 0.08);
  --color-primary-100:    rgba(51, 179, 174, 0.15);

  --color-accent:         #3FCA93;   /* Green — CTAs, success */
  --color-accent-hover:   #35b882;
  --color-accent-active:  #2ea574;
  --color-accent-50:      rgba(63, 202, 147, 0.08);

  /* ─── Neutrals ─────────────────────────────────────────── */
  --color-bg:             #FFFFFF;
  --color-bg-soft:        #FAF9F6;   /* Beige — your existing bg */
  --color-bg-muted:       #F3F4F6;
  --color-surface:        #FFFFFF;
  --color-surface-hover:  #F9FAFB;

  --color-border:         #E5E7EB;
  --color-border-light:   #F0F0F0;

  --color-text:           #111827;
  --color-text-secondary: #6B7280;
  --color-text-muted:     #9CA3AF;
  --color-text-inverse:   #FFFFFF;

  /* ─── Semantic Colors ──────────────────────────────────── */
  --color-danger:         #EF4444;
  --color-danger-hover:   #DC2626;
  --color-danger-50:      #FEF2F2;
  --color-warning:        #F59E0B;
  --color-warning-50:     #FFFBEB;
  --color-info:           #3B82F6;
  --color-success:        #10B981;
  --color-success-50:     #ECFDF5;

  /* ─── Typography ───────────────────────────────────────── */
  --font-display:         'Italiana', serif;         /* Logo, page titles */
  --font-body:            'Inter', system-ui, sans-serif; /* Everything else */

  --text-xs:    0.75rem;   /* 12px */
  --text-sm:    0.875rem;  /* 14px */
  --text-base:  1rem;      /* 16px */
  --text-lg:    1.125rem;  /* 18px */
  --text-xl:    1.25rem;   /* 20px */
  --text-2xl:   1.5rem;    /* 24px */
  --text-3xl:   2rem;      /* 32px */
  --text-4xl:   2.5rem;    /* 40px — page titles */

  --leading-tight:  1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  /* ─── Spacing Scale (8px base) ─────────────────────────── */
  --space-1:   0.25rem;   /* 4px */
  --space-2:   0.5rem;    /* 8px */
  --space-3:   0.75rem;   /* 12px */
  --space-4:   1rem;      /* 16px */
  --space-5:   1.25rem;   /* 20px */
  --space-6:   1.5rem;    /* 24px */
  --space-8:   2rem;      /* 32px */
  --space-10:  2.5rem;    /* 40px */
  --space-12:  3rem;      /* 48px */
  --space-16:  4rem;      /* 64px */
  --space-20:  5rem;      /* 80px — page top offset for fixed navbar */

  /* ─── Border Radius ────────────────────────────────────── */
  --radius-sm:   0.375rem;  /* 6px — inputs, small buttons */
  --radius-md:   0.5rem;    /* 8px — buttons, badges */
  --radius-lg:   0.75rem;   /* 12px — cards, dropdowns */
  --radius-xl:   1rem;      /* 16px — large cards, modals */
  --radius-2xl:  1.25rem;   /* 20px — hero cards */
  --radius-full: 9999px;    /* pills, avatars */

  /* ─── Shadows ──────────────────────────────────────────── */
  --shadow-sm:   0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md:   0 4px 6px -1px rgba(0, 0, 0, 0.07), 0 2px 4px -2px rgba(0, 0, 0, 0.05);
  --shadow-lg:   0 10px 25px rgba(0, 0, 0, 0.08), 0 4px 10px rgba(0, 0, 0, 0.04);
  --shadow-xl:   0 20px 40px rgba(0, 0, 0, 0.1), 0 8px 16px rgba(0, 0, 0, 0.06);
  --shadow-card: 0 1px 6px rgba(0, 0, 0, 0.07);
  --shadow-none: 0 0 0 transparent;

  /* ─── Transitions ──────────────────────────────────────── */
  --ease-default:  cubic-bezier(0.4, 0, 0.2, 1);
  --ease-in:       cubic-bezier(0.4, 0, 1, 1);
  --ease-out:      cubic-bezier(0, 0, 0.2, 1);
  --ease-spring:   cubic-bezier(0.34, 1.56, 0.64, 1);

  --duration-fast:    150ms;
  --duration-normal:  250ms;
  --duration-slow:    400ms;

  /* ─── Layout ───────────────────────────────────────────── */
  --navbar-height:    4rem;     /* 64px */
  --sidebar-width:    280px;
  --content-max-width: 72rem;   /* 1152px */
  --page-padding:     1.5rem;
}

/* ─── Dark mode prep (optional, for future) ──────────────── */
@media (prefers-color-scheme: dark) {
  :root {
    /* Override tokens here when ready */
  }
}
```

### Step 2: Register in `angular.json`

```json
"styles": [
  "node_modules/leaflet/dist/leaflet.css",
  "src/styles/theme.css",
  "src/styles.css"
]
```

### Step 3: Extend Tailwind to use your tokens

**Update `tailwind.config.js`:**

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,ts}"],
  theme: {
    extend: {
      colors: {
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
        card: "var(--shadow-card)",
        soft: "var(--shadow-md)",
        elevated: "var(--shadow-lg)",
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
```

Now you can write `bg-brand`, `text-accent`, `shadow-card`, `rounded-card` etc. in Tailwind and everything pulls from one source.

---

## 3. Typography System {#3-typography-system}

### The Rule: Two Fonts, Clear Hierarchy

| Element | Font | Size | Weight | When to use |
|---------|------|------|--------|-------------|
| Logo ("VetNow") | `--font-display` (Italiana) | `--text-4xl` | 400 | Only the brand mark |
| Page Title | `--font-body` (Inter) | `--text-3xl` | 700 | Top of each page |
| Section Heading | `--font-body` | `--text-xl` | 600 | Card titles, section headers |
| Subtitle / Label | `--font-body` | `--text-sm` | 500 | Field labels, categories |
| Body | `--font-body` | `--text-base` | 400 | Paragraphs, descriptions |
| Caption | `--font-body` | `--text-xs` | 400 | Timestamps, metadata |

**Kill `Roboto`** — it's only used in `header-title.component.html`. Replace:

```html
<!-- BEFORE (header-title) -->
<div class="h-11 text-black md:text-4xl text-2xl font-normal font-['Roboto']">

<!-- AFTER -->
<div class="text-black md:text-4xl text-2xl font-bold font-body tracking-tight">
```

### Add global base typography in `src/styles.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    font-family: var(--font-body);
    color: var(--color-text);
    background-color: var(--color-bg-soft);
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }

  h1, h2, h3, h4, h5, h6 {
    font-family: var(--font-body);
    color: var(--color-text);
    line-height: var(--leading-tight);
  }
}
```

---

## 4. Spacing & Layout Rules {#4-spacing-layout}

### The 8px Grid

All spacing should be multiples of 8px. This creates visual rhythm.

| Context | Spacing |
|---------|---------|
| Icon to text | `--space-2` (8px) |
| Inside cards (padding) | `--space-5` (20px) or `--space-6` (24px) |
| Between form fields | `--space-4` (16px) |
| Between cards | `--space-6` (24px) |
| Between sections | `--space-10` (40px) or `--space-12` (48px) |
| Page top (below navbar) | `--space-20` (80px) → `mt-20` |
| Page horizontal padding | `--space-6` (24px) → `px-6` |

### Standard Page Layout Wrapper

Create a utility class or use this pattern consistently:

```html
<!-- Every page should start with this wrapper -->
<div class="max-w-content mx-auto px-4 md:px-6 pt-6 pb-12">
  <!-- page content -->
</div>
```

**Fix the home-page**: Currently uses `m-1` and `mx-14 my-4` (non-standard). Replace:

```html
<!-- BEFORE (home-page) -->
<div class="m-1">
  ...
  <div class="flex flex-col justify-center items-center w-1/6 mx-14 my-4">

<!-- AFTER -->
<div class="max-w-content mx-auto px-4 md:px-6 pt-6 pb-12">
  ...
  <div class="w-full sm:w-1/2 md:w-1/3 lg:w-1/4 p-3">
```

---

## 5. Unified Button System {#5-button-system}

Your current `button.component` builds class strings imperatively in TS. Here's a cleaner approach using CSS custom properties + Tailwind:

### Global button styles — add to `src/styles.css`:

```css
@layer components {
  /* ─── Base Button ────────────────────────────────────────── */
  .btn-base {
    @apply inline-flex items-center justify-center gap-2
           font-semibold font-body
           rounded-btn
           transition-all duration-200
           focus:outline-none focus:ring-2 focus:ring-offset-2
           disabled:opacity-50 disabled:cursor-not-allowed
           active:scale-[0.97]
           select-none whitespace-nowrap;
  }

  /* ─── Sizes ──────────────────────────────────────────────── */
  .btn-sm {
    @apply px-3 py-1.5 text-sm;
  }
  .btn-md {
    @apply px-5 py-2.5 text-sm;
  }
  .btn-lg {
    @apply px-6 py-3 text-base;
  }

  /* ─── Variants ───────────────────────────────────────────── */
  .btn-primary {
    @apply btn-base btn-md
           bg-accent text-white
           hover:bg-accent-hover
           focus:ring-accent/40;
    box-shadow: var(--shadow-sm);
  }
  .btn-primary:hover {
    box-shadow: var(--shadow-md);
  }

  .btn-secondary {
    @apply btn-base btn-md
           bg-white text-gray-700
           border border-gray-200
           hover:bg-gray-50 hover:border-gray-300
           focus:ring-gray-200;
  }

  .btn-danger {
    @apply btn-base btn-md
           bg-red-500 text-white
           hover:bg-red-600
           focus:ring-red-300;
  }

  .btn-ghost {
    @apply btn-base btn-md
           bg-transparent text-gray-600
           hover:bg-gray-100
           focus:ring-gray-200;
  }

  .btn-brand {
    @apply btn-base btn-md
           text-white
           focus:ring-brand/40;
    background-color: var(--color-primary);
  }
  .btn-brand:hover {
    background-color: var(--color-primary-dark);
  }
}
```

### Usage everywhere:

```html
<!-- Primary action -->
<button class="btn-primary">Confirm Appointment</button>

<!-- Secondary / cancel -->
<button class="btn-secondary">No, keep it</button>

<!-- Danger -->
<button class="btn-danger">Cancel Appointment</button>

<!-- Large variant -->
<button class="btn-primary btn-lg">Sign In</button>

<!-- Full width -->
<button class="btn-primary w-full">✔ Confirm Appointment</button>
```

### Refactor your `ButtonComponent`:

```typescript
// button.component.ts — simplified
@Component({
  selector: 'app-button',
  standalone: true,
  template: `
    <button
      [class]="'btn-' + variant + ' ' + (size ? 'btn-' + size : '') + ' ' + extraClass"
      [disabled]="disabled"
      (click)="event.emit()">
      <ng-content></ng-content>
      {{ text }}
    </button>
  `,
})
export class ButtonComponent {
  @Output() event = new EventEmitter<void>();
  @Input() text = '';
  @Input() variant: 'primary' | 'secondary' | 'danger' | 'ghost' | 'brand' = 'primary';
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() disabled = false;
  @Input() extraClass = '';
}
```

---

## 6. Card Components {#6-card-components}

### Unified Card Base — add to `src/styles.css`:

```css
@layer components {
  .card {
    @apply bg-white rounded-card overflow-hidden;
    border: 1px solid var(--color-border-light);
    box-shadow: var(--shadow-card);
    transition: box-shadow var(--duration-normal) var(--ease-default),
                transform var(--duration-normal) var(--ease-default);
  }

  .card-interactive {
    @apply card cursor-pointer;
  }
  .card-interactive:hover {
    box-shadow: var(--shadow-lg);
    transform: translateY(-2px);
  }
  .card-interactive:active {
    transform: translateY(0);
    box-shadow: var(--shadow-md);
  }

  .card-body {
    @apply p-5;
  }

  .card-header {
    @apply px-5 py-4 border-b border-gray-100;
  }
}
```

### Apply to vet-card:

```html
<!-- BEFORE -->
<div class="w-80 h-96 bg-zinc-300 rounded-2xl card-container transition-all duration-150">

<!-- AFTER -->
<div class="card-interactive w-80">
  <div class="h-36 bg-emerald-800 overflow-hidden">
    <img *ngIf="vetStation?.stationImage"
         class="w-full h-full object-cover transition-transform duration-500 hover:scale-105"
         [src]="vetStation?.stationImage" />
  </div>
  <div class="card-body">
    <!-- ...content... -->
  </div>
</div>
```

---

## 7. Angular Animations — Page Transitions {#7-page-transitions}

### Step 1: Create the animation file

**File: `src/app/animations/route.animations.ts`**

```typescript
import {
  trigger,
  transition,
  style,
  animate,
  query,
  group,
} from '@angular/animations';

// ─── Fade + subtle slide for route changes ───────────────────
export const routeFadeAnimation = trigger('routeAnimation', [
  transition('* <=> *', [
    // Set up: position both views
    query(':enter, :leave', [
      style({
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
      }),
    ], { optional: true }),

    // Animate
    group([
      // Old page fades out and slides up slightly
      query(':leave', [
        style({ opacity: 1, transform: 'translateY(0)' }),
        animate('250ms cubic-bezier(0.4, 0, 0.2, 1)',
          style({ opacity: 0, transform: 'translateY(-12px)' })
        ),
      ], { optional: true }),

      // New page fades in and slides up from below
      query(':enter', [
        style({ opacity: 0, transform: 'translateY(16px)' }),
        animate('350ms 100ms cubic-bezier(0.0, 0.0, 0.2, 1)',
          style({ opacity: 1, transform: 'translateY(0)' })
        ),
      ], { optional: true }),
    ]),
  ]),
]);
```

### Step 2: Apply to app.component

```typescript
// app.component.ts
import { routeFadeAnimation } from './animations/route.animations';

@Component({
  selector: 'app-root',
  standalone: true,
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
  animations: [routeFadeAnimation],
  imports: [/* ... */],
})
export class AppComponent {
  // ...existing code...

  prepareRoute(outlet: RouterOutlet) {
    return outlet?.activatedRouteData?.['animation']
      ?? outlet?.activatedRoute?.snapshot?.url?.toString();
  }
}
```

```html
<!-- app.component.html -->
<app-navbar></app-navbar>
<main class="relative mt-navbar" [@routeAnimation]="prepareRoute(outlet)">
  <router-outlet #outlet="outlet"></router-outlet>
</main>
<app-toaster></app-toaster>
```

### Step 3: Ensure BrowserAnimationsModule is imported

Your `app.module.ts` already has `BrowserAnimationsModule`. If you're using standalone bootstrap, add to `app.config.ts`:

```typescript
import { provideAnimations } from '@angular/platform-browser/animations';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideAnimations(),
    // ...
  ],
};
```

---

## 8. Angular Animations — Component Animations {#8-component-animations}

### Create a shared animations library

**File: `src/app/animations/shared.animations.ts`**

```typescript
import {
  trigger,
  transition,
  style,
  animate,
  query,
  stagger,
  state,
  keyframes,
} from '@angular/animations';

// ─── Fade In (for any component entering the DOM) ───────────
export const fadeIn = trigger('fadeIn', [
  transition(':enter', [
    style({ opacity: 0, transform: 'translateY(8px)' }),
    animate('300ms cubic-bezier(0.0, 0.0, 0.2, 1)',
      style({ opacity: 1, transform: 'translateY(0)' })
    ),
  ]),
]);

// ─── Scale In (for modals, popovers) ────────────────────────
export const scaleIn = trigger('scaleIn', [
  transition(':enter', [
    style({ opacity: 0, transform: 'scale(0.92)' }),
    animate('250ms cubic-bezier(0.34, 1.56, 0.64, 1)',
      style({ opacity: 1, transform: 'scale(1)' })
    ),
  ]),
  transition(':leave', [
    animate('200ms cubic-bezier(0.4, 0, 1, 1)',
      style({ opacity: 0, transform: 'scale(0.95)' })
    ),
  ]),
]);

// ─── List Stagger (items appear one by one) ─────────────────
export const listStagger = trigger('listStagger', [
  transition('* => *', [
    query(':enter', [
      style({ opacity: 0, transform: 'translateY(15px)' }),
      stagger('60ms', [
        animate('350ms cubic-bezier(0.0, 0.0, 0.2, 1)',
          style({ opacity: 1, transform: 'translateY(0)' })
        ),
      ]),
    ], { optional: true }),
  ]),
]);

// ─── Slide Down (for dropdown menus, expandable sections) ───
export const slideDown = trigger('slideDown', [
  transition(':enter', [
    style({ height: 0, opacity: 0, overflow: 'hidden' }),
    animate('250ms cubic-bezier(0.0, 0.0, 0.2, 1)',
      style({ height: '*', opacity: 1 })
    ),
  ]),
  transition(':leave', [
    style({ overflow: 'hidden' }),
    animate('200ms cubic-bezier(0.4, 0, 1, 1)',
      style({ height: 0, opacity: 0 })
    ),
  ]),
]);

// ─── Expand / Collapse (for accordion panels) ───────────────
export const expandCollapse = trigger('expandCollapse', [
  state('collapsed', style({ height: '0', opacity: 0, overflow: 'hidden' })),
  state('expanded', style({ height: '*', opacity: 1 })),
  transition('collapsed <=> expanded', [
    animate('300ms cubic-bezier(0.4, 0, 0.2, 1)'),
  ]),
]);

// ─── Pulse (attention-grab for new items) ────────────────────
export const pulse = trigger('pulse', [
  transition(':enter', [
    animate('600ms', keyframes([
      style({ transform: 'scale(1)', offset: 0 }),
      style({ transform: 'scale(1.04)', offset: 0.5 }),
      style({ transform: 'scale(1)', offset: 1 }),
    ])),
  ]),
]);

// ─── Shake (for form validation errors) ─────────────────────
export const shake = trigger('shake', [
  transition('false => true', [
    animate('400ms', keyframes([
      style({ transform: 'translateX(0)', offset: 0 }),
      style({ transform: 'translateX(-6px)', offset: 0.15 }),
      style({ transform: 'translateX(5px)', offset: 0.3 }),
      style({ transform: 'translateX(-4px)', offset: 0.5 }),
      style({ transform: 'translateX(3px)', offset: 0.65 }),
      style({ transform: 'translateX(-2px)', offset: 0.8 }),
      style({ transform: 'translateX(0)', offset: 1 }),
    ])),
  ]),
]);
```

### Apply: Home Page — Vet Station Cards with Stagger

```typescript
// home-page.component.ts
import { listStagger } from '../../animations/shared.animations';

@Component({
  // ...
  animations: [listStagger],
})
export class HomePageComponent {
  // ...
}
```

```html
<!-- home-page.component.html -->
<div [@listStagger]="vetStationService.vetStations?.vetStations?.length"
     class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
  <app-vet-card
    *ngFor="let station of vetStationService.vetStations?.vetStations"
    [vetStation]="station"
    [routerLink]="'vet-station-home/' + station?.id"
    @fadeIn>
  </app-vet-card>
</div>
```

### Apply: Login Page — Form Shake on Error

```typescript
// login.component.ts
import { shake, fadeIn } from '../../animations/shared.animations';

@Component({
  // ...
  animations: [shake, fadeIn],
})
export class LoginComponent {
  // ...
}
```

```html
<!-- Wrap the login box -->
<div class="login-register-box" [@shake]="isError" @fadeIn>
  <!-- ...existing form... -->
</div>
```

### Apply: Modal Entrance

```html
<!-- Cancel confirmation modal body -->
<div *ngIf="showCancelModal"
     class="modal-content"
     @scaleIn>
  <!-- ...modal content... -->
</div>
```

### Apply: My Appointments — Card List Stagger

```typescript
// my-appointments.component.ts
import { listStagger, fadeIn, scaleIn } from '../../animations/shared.animations';

@Component({
  // ...
  animations: [listStagger, fadeIn, scaleIn],
})
```

```html
<!-- Appointment cards -->
<div [@listStagger]="filteredByDate.length" class="flex flex-col gap-3">
  <div *ngFor="let appt of filteredByDate"
       @fadeIn
       class="bg-white rounded-xl ...">
    <!-- ...card content... -->
  </div>
</div>

<!-- Detail panel -->
<div *ngIf="selectedAppointment" @scaleIn
     class="bg-white rounded-2xl shadow-custom ...">
  <!-- ...detail content... -->
</div>
```

---

## 9. Interactive Micro-Interactions {#9-micro-interactions}

### CSS-based Hover Effects — add to `src/styles.css`:

```css
@layer components {
  /* ─── Hover Lift — for any clickable card ──────────────── */
  .hover-lift {
    transition: transform var(--duration-normal) var(--ease-default),
                box-shadow var(--duration-normal) var(--ease-default);
  }
  .hover-lift:hover {
    transform: translateY(-3px);
    box-shadow: var(--shadow-lg);
  }
  .hover-lift:active {
    transform: translateY(-1px);
    box-shadow: var(--shadow-md);
  }

  /* ─── Hover Glow — for primary CTAs ────────────────────── */
  .hover-glow {
    transition: all var(--duration-normal) var(--ease-default);
  }
  .hover-glow:hover {
    box-shadow: 0 0 20px var(--color-accent-50),
                0 4px 12px rgba(63, 202, 147, 0.25);
  }

  /* ─── Focus Ring — accessible, beautiful ───────────────── */
  .focus-ring {
    @apply focus:outline-none focus:ring-2 focus:ring-offset-2;
    --tw-ring-color: var(--color-primary-100);
  }

  /* ─── Image Zoom on Hover ──────────────────────────────── */
  .img-zoom {
    overflow: hidden;
  }
  .img-zoom img {
    transition: transform 0.5s var(--ease-default);
  }
  .img-zoom:hover img {
    transform: scale(1.08);
  }

  /* ─── Skeleton Loading ─────────────────────────────────── */
  .skeleton {
    @apply bg-gray-100 rounded-lg animate-pulse;
  }

  /* ─── Smooth border highlight on selection ─────────────── */
  .selectable {
    @apply border-2 border-transparent transition-all duration-200;
  }
  .selectable.selected {
    border-color: var(--color-primary);
    box-shadow: 0 0 0 3px var(--color-primary-50);
  }
}
```

### Loading States — Skeleton Components

Create a reusable skeleton pattern:

```html
<!-- Card skeleton (use while loading vet stations) -->
<div class="card animate-pulse">
  <div class="h-36 bg-gray-200 rounded-t-card"></div>
  <div class="card-body space-y-3">
    <div class="h-5 bg-gray-200 rounded w-3/4"></div>
    <div class="h-4 bg-gray-200 rounded w-1/2"></div>
    <div class="h-3 bg-gray-200 rounded w-full"></div>
    <div class="h-3 bg-gray-200 rounded w-5/6"></div>
  </div>
</div>
```

### Button Loading State

```html
<button class="btn-primary" [disabled]="isLoading">
  <svg *ngIf="isLoading" class="animate-spin h-4 w-4" viewBox="0 0 24 24">
    <circle class="opacity-25" cx="12" cy="12" r="10"
            stroke="currentColor" stroke-width="4" fill="none"/>
    <path class="opacity-75" fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
  </svg>
  {{ isLoading ? 'Booking...' : 'Confirm Appointment' }}
</button>
```

### State Transitions for Time Slots

Your time slot buttons already have selection states. Enhance with micro-interactions:

```css
/* In appointment-page styles or global */
.time-slot-btn {
  @apply flex flex-col items-center justify-center gap-1
         py-3 px-2 rounded-xl border-2
         font-medium text-sm
         transition-all duration-200;
}

.time-slot-btn:not(.selected) {
  @apply border-gray-200 text-gray-500
         hover:border-brand hover:bg-brand/5 hover:text-brand;
}

.time-slot-btn.selected {
  @apply border-accent bg-accent-50 text-green-700 font-bold;
  box-shadow: 0 0 0 3px var(--color-accent-50);
  animation: selectPop 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes selectPop {
  0%   { transform: scale(1); }
  50%  { transform: scale(1.06); }
  100% { transform: scale(1); }
}
```

---

## 10. Responsive Polish {#10-responsive-polish}

### Problem: Current Breakpoint Strategy

Your home page uses `w-1/6 mx-14` which creates awkward layouts on tablets. The appointment page uses `md:grid-cols-2` which works but needs fine-tuning.

### Mobile-First Grid Utility Pattern

```html
<!-- ─── Vet Station Cards Grid (home page) ──────────────── -->
<!-- Replace the current w-1/6 mx-14 approach -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 px-4 md:px-6">
  <app-vet-card *ngFor="let s of stations" [vetStation]="s"></app-vet-card>
</div>

<!-- ─── Two Column Layout (appointment, my-appointments) ──── -->
<div class="grid grid-cols-1 md:grid-cols-5 gap-6 items-start">
  <div class="md:col-span-3"><!-- main content --></div>
  <div class="md:col-span-2"><!-- sidebar --></div>
</div>
```

### Responsive Navbar — Fix the Logo + Sidebar

```css
/* navbar.component.css — add responsive tweaks */
.LogoMark {
  font-family: var(--font-display);
  font-size: clamp(1.75rem, 4vw, 2.625rem);  /* Fluid scaling */
  color: var(--color-text);
  line-height: 1;
}

@media (max-width: 640px) {
  .contentOfSidebar {
    margin: 0 12px;
  }
}
```

### Responsive Login Box

```css
/* login.component.css — make it fluid */
.login-register-box {
  width: min(22.938rem, 92vw);   /* Never wider than viewport */
  padding: var(--space-6) var(--space-4);
}
```

### Responsive Cards

```css
/* vet-card — fluid width instead of fixed w-80 */
:host {
  display: block;
  width: 100%;
}
.card-container {
  width: 100%;  /* Fill grid cell, grid controls width */
  /* Remove the fixed w-80 from the template */
}
```

### Container Queries (CSS-native, Angular 17+ supports them):

```css
/* For the appointment booking summary card */
@container (max-width: 400px) {
  .booking-summary {
    font-size: var(--text-sm);
  }
  .booking-summary .btn-primary {
    padding: var(--space-2) var(--space-4);
  }
}
```

---

## 11. Refactoring Checklist {#11-refactoring-checklist}

### Phase 1: Foundation (do first)

- [ ] Create `src/styles/theme.css` with all design tokens
- [ ] Register `theme.css` in `angular.json`
- [ ] Update `tailwind.config.js` to use CSS variable aliases
- [ ] Add base typography to `src/styles.css` (`@layer base`)
- [ ] Add button system to `src/styles.css` (`@layer components`)
- [ ] Add card system to `src/styles.css` (`@layer components`)

### Phase 2: Animations (high visual impact)

- [ ] Create `src/app/animations/route.animations.ts`
- [ ] Create `src/app/animations/shared.animations.ts`
- [ ] Add route animation to `app.component.ts`
- [ ] Add `listStagger` to home page
- [ ] Add `fadeIn` + `scaleIn` to my-appointments page
- [ ] Add `shake` to login error state
- [ ] Add `scaleIn` to all modals

### Phase 3: Component Refactoring (page by page)

- [ ] **Navbar**: Replace hardcoded colors with `var(--color-*)`, fix `LogoMark` font-size
- [ ] **header-title**: Kill `Roboto`, use `font-body`, add `tracking-tight`
- [ ] **button.component**: Refactor to use `btn-primary` / `btn-secondary` classes
- [ ] **vet-card**: Use `card-interactive`, `img-zoom`, remove fixed `w-80`
- [ ] **login**: Replace hardcoded button styles, use `btn-primary btn-lg`
- [ ] **settings-card**: Unify with `.card` base
- [ ] **table.component**: Already well-styled — just swap hardcoded colors for variables
- [ ] **appointment-page**: Time slots → use `.time-slot-btn` class

### Phase 4: Responsive & Polish

- [ ] Home page: Replace `w-1/6 mx-14` with responsive grid
- [ ] Login: Use `min()` for fluid width
- [ ] Vet card: Remove fixed widths, let grid control size
- [ ] Add loading skeletons to all pages that fetch data
- [ ] Add `hover-lift` to all clickable cards
- [ ] Add `hover-glow` to primary CTA buttons

### Phase 5: Cleanup

- [ ] Remove all `font-['Roboto']` and `font-['Inter']` inline declarations
- [ ] Remove redundant `box-shadow: 0px 4px 4px 0px rgba(0,0,0,0.25)` (appears in 5+ places)
- [ ] Remove dead CSS (`.bar1`, `.bar2`, `.bar3`, `.hamburger` in navbar)
- [ ] Audit and remove unused Bootstrap classes (you only use offcanvas + modal)
- [ ] Consolidate the 3 different `.flex-center-container` definitions

---

## Quick Wins (30 minutes to visible improvement)

1. **Add `theme.css`** → instant consistency via tokens
2. **Add route animation** → every navigation feels polished
3. **Add `listStagger` to home page** → the card grid comes alive
4. **Replace the `#signInButton` styles with `.btn-primary.btn-lg`** → login page levels up
5. **Add `.hover-lift` to vet cards** → cards feel interactive

These five changes alone will make the app feel significantly more professional with minimal risk.
