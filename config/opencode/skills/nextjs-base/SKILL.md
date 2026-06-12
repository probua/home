---
name: nextjs-base
description: Use when building or maintaining a Next.js App Router project. Covers architecture patterns, component conventions, hooks, styling, configuration, and anti-patterns. Trigger on Next.js related tasks, new project scaffolding, or code review.
---

# Next.js Base Project Patterns

## Directory Structure

```
src/
  app/           # Routes (App Router) - keep pages thin
  components/    # All UI components
    icons/       # Shared SVG icon components
  hooks/         # Custom React hooks
  lib/           # Data fetching, utilities, constants
  types/         # TypeScript interfaces and types
  fonts/         # Local font files
```

## Component Conventions

### Server vs Client Components
- **Default to server components** (no "use client")
- Add "use client" ONLY when the component needs:
  - Event handlers (onClick, onChange, etc.)
  - React hooks (useState, useEffect, useRef, etc.)
  - Browser-only APIs (window, document)
- If a server component is imported inside a client component, it becomes a client component automatically

### Component Naming
- PascalCase for files and exports: `ProductCard.tsx`, `ContactSection.tsx`
- One component per file
- Section suffix for page sections: `HeroSection`, `BrandsSection`
- Icon suffix for SVG components: `WhatsAppIcon`, `ChevronIcon`

### Props
- Always define a typed `interface ComponentNameProps`
- Pass data down from server components via props
- Never access `process.env` directly in client components — pass as prop from server

## Data Fetching Patterns

### Generic Fetch Client
Create a single `src/lib/api-client.ts` that centralizes:
- Base URL validation (one place, not repeated in every file)
- Common headers
- Error handling
- Response parsing

Example pattern:
```ts
const BASE_URL = process.env.NEXT_PUBLIC_API_URL;
if (!BASE_URL) throw new Error('API URL is not defined');

interface FetchOptions {
  revalidate?: number;
  tags?: string[];
}

export async function apiFetch<T>(endpoint: string, options: FetchOptions): Promise<T> {
  const response = await fetch(`${BASE_URL}${endpoint}`, {
    next: { revalidate: options.revalidate ?? 3600, tags: options.tags },
    headers: { 'Content-Type': 'application/json' },
  });
  if (!response.ok) throw new Error(`Fetch failed: ${response.status}`);
  const result = await response.json();
  return result.data;
}
```

### React.cache() for Deduplication
Wrap ALL fetch functions with `React.cache()`:
```ts
import { cache } from 'react';
export const fetchData = cache(async () => { ... });
```
This prevents duplicate HTTP requests when the same function is called in `generateMetadata()` and the page component.

### ISR with Tags
Use Next.js ISR with revalidation tags for cache invalidation:
```ts
next: { revalidate: 3600, tags: ['resource-name'] }
```

## Custom Hooks

### When to Extract a Hook
- Same state + effect logic in 2+ components
- Logic that manages a specific concern (scroll, media query, etc.)

### Hook Patterns
- Name with `use` prefix: `useScrollButtons`, `useMediaQuery`
- Accept a RefObject for DOM-related hooks
- Return plain objects (not arrays) for readability: `{ canScrollLeft, canScrollRight }`
- Include resize handling for DOM-measurement hooks
- Use `{ passive: true }` for scroll event listeners

### Example: useScrollButtons
```ts
export function useScrollButtons(scrollRef: RefObject<HTMLElement | null>, options?: { tolerance?: number }) {
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);
  const tolerance = options?.tolerance ?? 4;

  const update = useCallback(() => {
    const el = scrollRef.current;
    if (!el) return;
    setCanScrollLeft(el.scrollLeft > tolerance);
    setCanScrollRight(el.scrollLeft < el.scrollWidth - el.clientWidth - tolerance);
  }, [scrollRef, tolerance]);

  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    update();
    el.addEventListener("scroll", update, { passive: true });
    window.addEventListener("resize", update);
    return () => {
      el.removeEventListener("scroll", update);
      window.removeEventListener("resize", update);
    };
  }, [update]);

  return { canScrollLeft, canScrollRight, update };
}
```

## Styling Conventions

### Tailwind + Custom CSS Classes
- Use Tailwind utilities as primary styling
- For complex or repeated styles, create CSS classes in `globals.css`
- CSS classes are for: gradient backgrounds, button styles with hover states, navigation link effects, component-specific animations

### When to Create a CSS Class
- Same inline `style` appears 2+ times
- Hover/active states that Tailwind can't express cleanly
- Complex gradients or shadows
- Component animations with transitions

### Example CSS Classes
```css
/* Button with hover state */
.btn-primary {
  background: linear-gradient(180deg, #061D44 0%, #54111B 100%);
  color: white;
  transition: all 0.3s ease-in-out;
}
.btn-primary:hover {
  background: white;
  color: #021D49;
}

/* Repeated gradient */
.section-gradient {
  background: linear-gradient(91.66deg, ...);
}
```

### Icon SVGs
- Never inline the same SVG path in multiple components
- Create `src/components/icons/IconName.tsx` for each shared icon
- Accept `className` prop for size/color flexibility
- Accept specific props for variations (e.g., `direction` for chevrons, `stroke` for color override)

### Example Icon Component
```tsx
interface ChevronIconProps {
  direction: "left" | "right";
  className?: string;
  stroke?: string;
}
export default function ChevronIcon({ direction, className = "w-5 h-5", stroke = "currentColor" }: ChevronIconProps) {
  const d = direction === "left" ? "M15 19l-7-7 7-7" : "M9 5l7 7-7 7";
  return (
    <svg className={className} fill="none" stroke={stroke} viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={d} />
    </svg>
  );
}
```

## Navigation

- Always use `<Link>` from `next/link` for internal navigation
- Only use `<a>` for external links (other domains, `target="_blank"`) or file downloads
- Add `pointer-events-none` on overlay/background divs that sit above interactive content
- Add `aria-label` to icon-only buttons and links

## SEO & Metadata

- Export `generateMetadata()` from every page
- Use `title.template` pattern in layout for consistent titles
- Add JSON-LD structured data with `<script type="application/ld+json">`
- Include `sitemap.ts` and `robots.ts`
- Add `data-scroll-behavior="smooth"` to `<html>` element when using `scroll-behavior: smooth` in CSS

## Configuration

### tsconfig.json
```json
{
  "target": "ES2022",
  "strict": true,
  "noUnusedLocals": true,
  "noUnusedParameters": true
}
```

### next.config.ts
- Always set `poweredByHeader: false`
- Configure `images.remotePatterns` for external image domains
- Use `redirects()` for URL migrations

### ESLint
- Use flat config format (`eslint.config.mjs`)
- Include `core-web-vitals` and `typescript` configs at minimum

## Anti-Patterns (Avoid)

### 1. DOM Mutation in React
Never directly mutate `e.target.style`. Use state-driven className or CSS pseudo-classes.

### 2. Inline Styles for Interactions
Never use inline `style` for hover/active states. Create CSS classes in globals.css.

### 3. `<a>` for Internal Links
Never use `<a href>` for pages within the same site. Use `<Link>` from next/link.

### 4. `process.env` in Client Components
Never access environment variables directly in client components. Pass as props from server components.

### 5. Duplicate Fetch Without Cache
Never call the same fetch function multiple times in one page without `React.cache()`.

### 6. Missing `pointer-events-none` on Overlays
Background/overlay divs positioned over interactive content must have `pointer-events-none`.

### 7. Duplicated State Logic
Same useState + useEffect pattern in multiple components should be extracted to a custom hook.

### 8. Inline SVG Duplication
Same SVG path copied across multiple files should be a shared icon component in `components/icons/`.
