---
name: nextjs-strapi
description: Use ONLY when building a Next.js project that uses Strapi as a headless CMS. Extends nextjs-base skill with Strapi-specific patterns for API client, dual type system, data transformers, ISR revalidation, and webhook handling. Trigger when the project has Strapi, uses populate query params, or needs CMS integration.
---

# Next.js + Strapi CMS Patterns

**Requires**: `nextjs-base` skill for foundational Next.js patterns.

## Architecture Overview

```
Strapi CMS → REST API → Next.js (ISR) → Static Pages
                ↑
          Revalidation Webhook
```

Data flow:
1. Strapi serves content via REST API with `populate` query params
2. Next.js fetches at build/request time with ISR (Incremental Static Regeneration)
3. Strapi webhook triggers on-demand revalidation via `/api/revalidate`

## API Client Pattern

### Base Client (`src/lib/strapi-client.ts`)

Single file that handles ALL Strapi communication. Do NOT repeat URL validation, headers, or error handling in other files.

```ts
const STRAPI_URL = process.env.NEXT_PUBLIC_STRAPI_URL;
if (!STRAPI_URL) throw new Error('NEXT_PUBLIC_STRAPI_URL is not defined');

interface StrapiFetchOptions {
  tags: string[];
  revalidate?: number;
}

export async function strapiFetch<T>(endpoint: string, options: StrapiFetchOptions): Promise<T> {
  const response = await fetch(`${STRAPI_URL}${endpoint}`, {
    next: { revalidate: options.revalidate ?? 3600, tags: options.tags },
    headers: { 'Content-Type': 'application/json' },
  });
  if (!response.ok) {
    throw new Error(`Strapi fetch failed (${endpoint}): ${response.statusText} (${response.status})`);
  }
  const result = await response.json();
  return result.data;
}
```

### One File Per Resource

Each Strapi collection/single-type gets its own file in `src/lib/`:

| File | Strapi Resource | Export |
|------|----------------|--------|
| `src/lib/site.ts` | Global site settings (single type) | `fetchSiteData()` |
| `src/lib/home.ts` | Home page content (single type) | `fetchHomeData()` |
| `src/lib/products.ts` | Products (collection) | `fetchProducts()`, `fetchProductBySlug(slug)` |
| `src/lib/categories.ts` | Categories (collection) | `fetchCategories()` |
| `src/lib/contact.ts` | Contact info (single type) | `fetchContactData()` |

Each file wraps with `React.cache()`:
```ts
import { cache } from 'react';
import { strapiFetch } from '@/lib/strapi-client';

export const fetchProducts = cache(async (): Promise<StrapiProductData[]> => {
  return strapiFetch<StrapiProductData[]>(
    '/api/products?populate[mainImage]=true&populate[category][populate][parent]=true',
    { tags: ['products'] },
  );
});
```

### Strapi Populate Syntax

Strapi requires explicit `populate` query params for nested data. Common patterns:

```
# Simple relation
?populate[image]=true

# Nested relation (category → parent)
?populate[category][populate][parent]=true

# Multiple levels (footer → icons)
?populate[footer][populate][phoneIcon]=true&populate[footer][populate][emailIcon]=true

# Collection with pagination + fields
?pagination[pageSize]=500&fields[0]=name&fields[1]=slug&populate[mainImage]=true
```

## Type System Pattern

### Dual Types Per Resource

Each resource has TWO type definitions in `src/types/`:

1. **Raw Strapi type** (`Strapi*Data`) — matches the API response shape exactly
2. **Clean type** (`*Data`) — simplified, with nested types resolved and nulls handled

```ts
// Raw - matches Strapi v5 response exactly (flat, no { data } wrapper)
export interface StrapiProductData {
  id: number;
  documentId: string;
  name: string;
  slug: string;
  mainImage: StrapiImage;
  category: StrapiCategoryData | null;
}

// Clean - used in components
export interface ProductData {
  name: string;
  slug: string;
  mainImage: ImageData;
  category: CategoryData | null;
}
```

### Transformer Functions

Each types file exports `to*Data()` functions that convert raw to clean:

```ts
export function toProductData(raw: StrapiProductData): ProductData {
  return {
    name: raw.name,
    slug: raw.slug,
    mainImage: toImageData(raw.mainImage),
    category: raw.category ? toCategoryData(raw.category) : null,
  };
}
```

For collections, also export bulk transformers:
```ts
export function toProducts(raw: StrapiProductData[]): ProductData[] {
  return raw.map(toProductData);
}
```

### Shared Base Types (`src/types/strapi-base.ts`)

Define types shared across all resources:

- `StrapiImage` — raw Strapi image with formats (thumbnail, small, medium, large)
- `ImageData` — clean image type (url, alt, width, height, formats)
- `StrapiHeroSlide` / `HeroSlideData` — hero banner with headline positioning
- `toImageData()` — universal image transformer
- `toHeroSlide()` — universal hero slide transformer

## ISR & Revalidation

### Tag Strategy

| Tag Pattern | Use Case |
|-------------|----------|
| `['resource']` | All entries of a collection |
| `['resource', 'resource-{id}']` | Specific entry in a collection |
| `['resource', 'home']` | Single type resource |

### Revalidation Webhook

Create `src/app/api/revalidate/route.ts`:

- Accepts POST requests from Strapi webhook
- Validates secret token from `REVALIDATION_SECRET_TOKEN` env var
- Reads `model` and `entry` from the Strapi payload
- Maps model names to revalidation tags
- Calls `revalidateTag()` for each affected tag
- Returns `{ revalidated: true/false }`

### Environment Variables

```env
# Strapi CMS
NEXT_PUBLIC_STRAPI_URL=https://cms.example.com
STRAPI_PAGE_SIZE=500

# Site
NEXT_PUBLIC_SITE_URL=https://example.com

# Revalidation Webhook
REVALIDATION_SECRET_TOKEN=your-secret-token

# Email (if using contact forms with Resend)
RESEND_API_KEY=your-resend-key
EMAIL_FROM=Site Name <noreply@example.com>
```

## Page Pattern

Every page follows this structure:

```tsx
import { fetchResource } from '@/lib/resource';
import { toResourceData } from '@/types/resource';

export async function generateMetadata(): Promise<Metadata> {
  const data = toResourceData(await fetchResource()); // cached
  return {
    title: data.seoTitle,
    description: data.seoDescription,
    alternates: { canonical: '/path' },
    openGraph: { title: data.seoTitle, description: data.seoDescription, ... },
  };
}

export default async function Page() {
  const data = toResourceData(await fetchResource()); // cache hit, no extra request
  return <SectionComponent data={data} />;
}
```

Key points:
- `generateMetadata` and page body both call the same cached fetch function
- Transform from Strapi types to clean types immediately after fetch
- Pages are thin — delegate rendering to section components

## Dynamic Routes (Collection Entries)

For pages like `/product/[slug]`:

```tsx
export async function generateStaticParams() {
  const products = await fetchProducts(); // returns StrapiProductData[]
  return products
    .filter((p) => p.slug)
    .map((p) => ({ slug: p.slug }));
}

export default async function ProductPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  try {
    const product = toProductDetailData(await fetchProductBySlug(slug));
    return <ProductView product={product} />;
  } catch {
    notFound();
  }
}
```

## Common Pitfalls

- **Missing `populate` params**: Strapi returns empty objects for relations without explicit populate
- **No `React.cache()`**: `generateMetadata` and page body are separate render passes — duplicate requests without it
- **Passing raw types to components**: Always transform `Strapi*Data` to `*Data` before passing to UI components
- **Nullable relations**: Strapi nullable fields must be typed as `| null`, check before accessing
- **Missing error handling**: Always wrap dynamic route fetches in try/catch with `notFound()` fallback
