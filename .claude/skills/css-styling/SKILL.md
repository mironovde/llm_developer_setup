---
name: css-style
description: Modern CSS styling with Tailwind, design systems, and responsive design. Covers design tokens, component styling, animations, and CSS best practices. Use for any styling work.
user-invocable: true
argument-hint: "[styling task or component]"
---

# CSS Styling Skill

You are an expert in modern CSS and design systems. Your role is to create beautiful, consistent, and maintainable styles following current best practices.

## Design Token System

### Token Architecture (Three Tiers)

```css
/* 1. Primitive Tokens - Raw values */
:root {
  /* Colors */
  --color-blue-50: #eff6ff;
  --color-blue-100: #dbeafe;
  --color-blue-500: #3b82f6;
  --color-blue-600: #2563eb;
  --color-blue-700: #1d4ed8;

  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-200: #e5e7eb;
  --color-gray-500: #6b7280;
  --color-gray-700: #374151;
  --color-gray-900: #111827;

  /* Spacing */
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-6: 1.5rem;   /* 24px */
  --space-8: 2rem;     /* 32px */
  --space-12: 3rem;    /* 48px */

  /* Typography */
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 1.875rem;

  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  /* Border Radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
}

/* 2. Semantic Tokens - Contextual meaning */
:root {
  /* Text */
  --text-primary: var(--color-gray-900);
  --text-secondary: var(--color-gray-500);
  --text-muted: var(--color-gray-400);
  --text-inverse: white;

  /* Background */
  --bg-primary: white;
  --bg-secondary: var(--color-gray-50);
  --bg-tertiary: var(--color-gray-100);

  /* Border */
  --border-default: var(--color-gray-200);
  --border-focus: var(--color-blue-500);
  --border-error: var(--color-red-500);

  /* Interactive */
  --interactive-primary: var(--color-blue-600);
  --interactive-primary-hover: var(--color-blue-700);
  --interactive-secondary: var(--color-gray-100);

  /* Status */
  --status-success: var(--color-green-500);
  --status-warning: var(--color-amber-500);
  --status-error: var(--color-red-500);
  --status-info: var(--color-blue-500);
}

/* Dark mode */
[data-theme="dark"] {
  --text-primary: var(--color-gray-50);
  --text-secondary: var(--color-gray-400);
  --bg-primary: var(--color-gray-900);
  --bg-secondary: var(--color-gray-800);
  --border-default: var(--color-gray-700);
}

/* 3. Component Tokens - Specific to components */
:root {
  /* Button */
  --button-height-sm: 2rem;
  --button-height-md: 2.5rem;
  --button-height-lg: 3rem;
  --button-padding-x: var(--space-4);
  --button-radius: var(--radius-lg);

  /* Input */
  --input-height: 2.5rem;
  --input-padding-x: var(--space-3);
  --input-radius: var(--radius-md);
  --input-border-width: 1px;

  /* Card */
  --card-padding: var(--space-6);
  --card-radius: var(--radius-xl);
  --card-shadow: var(--shadow-md);
}
```

## Tailwind CSS Patterns

### Tailwind Config
```js
// tailwind.config.ts
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};

export default config;
```

### Component Styling with cn()
```tsx
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Usage
function Button({ variant, size, className, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        // Base styles
        'inline-flex items-center justify-center rounded-lg font-medium',
        'transition-colors focus-visible:outline-none focus-visible:ring-2',
        // Variants
        variant === 'primary' && 'bg-primary text-primary-foreground hover:bg-primary/90',
        variant === 'secondary' && 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        variant === 'ghost' && 'hover:bg-accent hover:text-accent-foreground',
        // Sizes
        size === 'sm' && 'h-8 px-3 text-sm',
        size === 'md' && 'h-10 px-4',
        size === 'lg' && 'h-12 px-6 text-lg',
        // Custom classes
        className
      )}
      {...props}
    />
  );
}
```

### Class Variance Authority (CVA)
```tsx
import { cva, type VariantProps } from 'class-variance-authority';

const buttonVariants = cva(
  // Base styles
  'inline-flex items-center justify-center rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50',
  {
    variants: {
      variant: {
        primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
        secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4',
        lg: 'h-12 px-6 text-lg',
        icon: 'h-10 w-10',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

function Button({ variant, size, className, ...props }: ButtonProps) {
  return (
    <button className={cn(buttonVariants({ variant, size, className }))} {...props} />
  );
}
```

## Responsive Design

### Mobile-First Breakpoints
```css
/* Base styles (mobile) */
.container {
  padding: var(--space-4);
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

/* Tablet (640px+) */
@media (min-width: 640px) {
  .container {
    padding: var(--space-6);
    flex-direction: row;
  }
}

/* Desktop (1024px+) */
@media (min-width: 1024px) {
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: var(--space-8);
  }
}
```

### Tailwind Responsive
```tsx
<div className="
  flex flex-col gap-4 p-4
  sm:flex-row sm:gap-6 sm:p-6
  lg:max-w-5xl lg:mx-auto lg:p-8
">
  <aside className="
    w-full
    sm:w-64 sm:flex-shrink-0
  ">
    Sidebar
  </aside>
  <main className="flex-1">
    Content
  </main>
</div>
```

### Container Queries
```css
.card-container {
  container-type: inline-size;
}

.card {
  display: flex;
  flex-direction: column;
}

@container (min-width: 400px) {
  .card {
    flex-direction: row;
  }
}
```

## Animations

### CSS Transitions
```css
.button {
  transition: all 150ms ease-in-out;
}

.button:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.button:active {
  transform: translateY(0);
}
```

### Keyframe Animations
```css
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slide-in {
  from {
    transform: translateX(-100%);
  }
  to {
    transform: translateX(0);
  }
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.animate-fade-in {
  animation: fade-in 300ms ease-out;
}

.animate-slide-in {
  animation: slide-in 300ms ease-out;
}

.animate-spin {
  animation: spin 1s linear infinite;
}
```

### Framer Motion
```tsx
import { motion, AnimatePresence } from 'framer-motion';

function Modal({ isOpen, onClose, children }) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="fixed inset-0 bg-black/50"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          <motion.div
            className="fixed inset-x-4 top-1/2 -translate-y-1/2 bg-white rounded-xl p-6"
            initial={{ opacity: 0, scale: 0.95, y: '-45%' }}
            animate={{ opacity: 1, scale: 1, y: '-50%' }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ type: 'spring', duration: 0.3 }}
          >
            {children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
```

## Layout Patterns

### Flexbox
```css
/* Center content */
.center {
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Space between */
.space-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Stack (vertical) */
.stack {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

/* Cluster (horizontal wrap) */
.cluster {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}
```

### Grid
```css
/* Auto-fit grid */
.grid-auto {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: var(--space-6);
}

/* Sidebar layout */
.sidebar-layout {
  display: grid;
  grid-template-columns: 250px 1fr;
  gap: var(--space-8);
}

/* Holy grail */
.holy-grail {
  display: grid;
  grid-template:
    "header header header" auto
    "nav main aside" 1fr
    "footer footer footer" auto
    / 200px 1fr 200px;
  min-height: 100vh;
}
```

## Typography

### Fluid Typography
```css
:root {
  /* Fluid type scale using clamp */
  --font-size-sm: clamp(0.8rem, 0.17vw + 0.76rem, 0.89rem);
  --font-size-base: clamp(1rem, 0.34vw + 0.91rem, 1.19rem);
  --font-size-lg: clamp(1.25rem, 0.61vw + 1.1rem, 1.58rem);
  --font-size-xl: clamp(1.56rem, 1vw + 1.31rem, 2.11rem);
  --font-size-2xl: clamp(1.95rem, 1.56vw + 1.56rem, 2.81rem);
  --font-size-3xl: clamp(2.44rem, 2.38vw + 1.85rem, 3.75rem);
}
```

### Typography System
```css
.heading-1 {
  font-size: var(--font-size-3xl);
  font-weight: var(--font-weight-bold);
  line-height: 1.1;
  letter-spacing: -0.02em;
}

.heading-2 {
  font-size: var(--font-size-2xl);
  font-weight: var(--font-weight-semibold);
  line-height: 1.2;
}

.body {
  font-size: var(--font-size-base);
  line-height: 1.6;
}

.small {
  font-size: var(--font-size-sm);
  line-height: 1.5;
}
```

## Dark Mode

### CSS Variables Approach
```css
:root {
  --bg: white;
  --text: #111;
  --border: #e5e7eb;
}

[data-theme="dark"] {
  --bg: #111;
  --text: #f9fafb;
  --border: #374151;
}

/* Or with media query */
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #111;
    --text: #f9fafb;
  }
}
```

### Tailwind Dark Mode
```tsx
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  <h1 className="text-gray-900 dark:text-white">Title</h1>
  <p className="text-gray-600 dark:text-gray-400">Description</p>
</div>
```

## Best Practices

### DO:
- ✅ Use design tokens consistently
- ✅ Mobile-first responsive
- ✅ Semantic color naming
- ✅ Consistent spacing scale
- ✅ Test in dark mode
- ✅ Check color contrast

### DON'T:
- ❌ Use magic numbers
- ❌ Inline styles (except dynamic)
- ❌ !important (except utilities)
- ❌ Deep nesting (>3 levels)
- ❌ Fixed widths on containers
- ❌ Skip focus styles

## Remember

- Design tokens create consistency
- Mobile-first saves CSS
- Utility classes speed development
- Test on real devices
- Accessibility affects styling
- Performance matters (bundle size)
