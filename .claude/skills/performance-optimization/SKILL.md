---
name: performance
description: Frontend performance optimization for Core Web Vitals. Covers bundle optimization, lazy loading, caching, rendering performance, and monitoring. Use for any performance work.
user-invocable: true
argument-hint: "[area to optimize]"
---

# Performance Optimization Skill

You are an expert in frontend performance. Your role is to ensure applications are fast, efficient, and provide excellent user experience through optimization of Core Web Vitals and other metrics.

## Core Web Vitals

### LCP (Largest Contentful Paint)
**Target: < 2.5s**

Measures loading performance - when the largest content element becomes visible.

**Optimization Strategies:**
```tsx
// 1. Preload critical resources
<link rel="preload" href="/hero-image.jpg" as="image" />
<link rel="preload" href="/fonts/inter.woff2" as="font" crossOrigin="" />

// 2. Optimize images
<Image
  src="/hero.jpg"
  alt="Hero"
  priority // Disables lazy loading for LCP image
  sizes="(max-width: 768px) 100vw, 50vw"
/>

// 3. Use Next.js font optimization
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'] });

// 4. Server-side rendering for critical content
export default async function Page() {
  const data = await fetchCriticalData();
  return <HeroSection data={data} />;
}
```

### FID/INP (First Input Delay / Interaction to Next Paint)
**Target: FID < 100ms, INP < 200ms**

Measures interactivity - how quickly the page responds to user input.

**Optimization Strategies:**
```tsx
// 1. Code splitting - don't block main thread
const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  ssr: false,
});

// 2. Use Web Workers for heavy computation
const worker = new Worker('/worker.js');
worker.postMessage({ type: 'PROCESS', data: largeData });

// 3. Debounce/throttle event handlers
const handleSearch = useDebouncedCallback((query: string) => {
  search(query);
}, 300);

// 4. Use transitions for non-urgent updates
const [isPending, startTransition] = useTransition();

function handleClick() {
  startTransition(() => {
    setExpensiveState(newValue);
  });
}

// 5. Virtualize long lists
import { FixedSizeList } from 'react-window';

<FixedSizeList
  height={400}
  itemCount={10000}
  itemSize={50}
  width="100%"
>
  {({ index, style }) => (
    <div style={style}>{items[index].name}</div>
  )}
</FixedSizeList>
```

### CLS (Cumulative Layout Shift)
**Target: < 0.1**

Measures visual stability - unexpected layout shifts during page load.

**Optimization Strategies:**
```tsx
// 1. Always set dimensions for images/videos
<Image
  src="/photo.jpg"
  alt="Photo"
  width={800}
  height={600}
  // Or use fill with aspect ratio
/>

// 2. Reserve space for dynamic content
<div className="min-h-[200px]">
  {isLoading ? <Skeleton /> : <Content />}
</div>

// 3. Avoid inserting content above existing content
// Bad: Banner at top that loads late
// Good: Reserve space or load before paint

// 4. Use transform for animations (not width/height)
.animate {
  transform: scale(1.1); /* Good */
  /* width: 110%; Bad - causes layout shift */
}

// 5. Font loading strategy
const font = Inter({
  subsets: ['latin'],
  display: 'swap', // Shows fallback immediately
});
```

## Bundle Optimization

### Code Splitting
```tsx
// Route-based splitting (automatic in Next.js)
// pages/about.tsx -> separate chunk

// Component-based splitting
const DashboardChart = dynamic(() => import('./DashboardChart'), {
  loading: () => <ChartSkeleton />,
});

// Library splitting
const DatePicker = dynamic(
  () => import('react-datepicker').then(mod => mod.default),
  { ssr: false }
);
```

### Tree Shaking
```tsx
// Bad: imports entire library
import _ from 'lodash';
_.debounce(fn, 300);

// Good: imports only what's needed
import debounce from 'lodash/debounce';
debounce(fn, 300);

// Even better: use native or lighter alternatives
import { debounce } from './utils/debounce';
```

### Bundle Analysis
```bash
# Next.js
ANALYZE=true npm run build

# Vite
npx vite-bundle-visualizer
```

## Image Optimization

### Next.js Image
```tsx
import Image from 'next/image';

// Responsive image
<Image
  src="/photo.jpg"
  alt="Description"
  fill
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
  className="object-cover"
/>

// Priority for above-the-fold
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority
  quality={85}
/>

// Blur placeholder
<Image
  src="/photo.jpg"
  alt="Photo"
  width={800}
  height={600}
  placeholder="blur"
  blurDataURL="data:image/jpeg;base64,..."
/>
```

### Modern Formats
```tsx
// Next.js automatically serves WebP/AVIF when supported
// For manual control:
<picture>
  <source srcSet="/image.avif" type="image/avif" />
  <source srcSet="/image.webp" type="image/webp" />
  <img src="/image.jpg" alt="Description" />
</picture>
```

## Caching Strategies

### HTTP Caching
```tsx
// Next.js API route with caching
export async function GET() {
  const data = await fetchData();

  return Response.json(data, {
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
    },
  });
}
```

### React Query Caching
```tsx
// Configure stale time
const { data } = useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
  staleTime: 5 * 60 * 1000, // 5 minutes
  gcTime: 30 * 60 * 1000, // 30 minutes (garbage collection)
});

// Prefetching
const queryClient = useQueryClient();

// Prefetch on hover
<Link
  href={`/user/${user.id}`}
  onMouseEnter={() => {
    queryClient.prefetchQuery({
      queryKey: ['user', user.id],
      queryFn: () => fetchUser(user.id),
    });
  }}
>
  {user.name}
</Link>
```

### Service Worker
```ts
// sw.ts
import { precacheAndRoute } from 'workbox-precaching';
import { registerRoute } from 'workbox-routing';
import { StaleWhileRevalidate, CacheFirst } from 'workbox-strategies';

// Precache static assets
precacheAndRoute(self.__WB_MANIFEST);

// Cache API responses
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new StaleWhileRevalidate({
    cacheName: 'api-cache',
  })
);

// Cache images
registerRoute(
  ({ request }) => request.destination === 'image',
  new CacheFirst({
    cacheName: 'image-cache',
    plugins: [
      new ExpirationPlugin({
        maxEntries: 50,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
      }),
    ],
  })
);
```

## React Performance

### Memoization
```tsx
// Memoize expensive computations
const sortedItems = useMemo(() => {
  return items.sort((a, b) => a.name.localeCompare(b.name));
}, [items]);

// Memoize callbacks passed to children
const handleClick = useCallback((id: string) => {
  setSelectedId(id);
}, []);

// Memoize components
const MemoizedList = memo(function ItemList({ items }: Props) {
  return items.map(item => <Item key={item.id} {...item} />);
});
```

### Avoid Unnecessary Renders
```tsx
// Bad: Creates new object every render
<Component style={{ color: 'red' }} />

// Good: Stable reference
const style = useMemo(() => ({ color: 'red' }), []);
<Component style={style} />

// Or use className instead
<Component className="text-red-500" />
```

### Suspense and Streaming
```tsx
// Streaming with Suspense
export default function Page() {
  return (
    <>
      <Header />
      <Suspense fallback={<SkeletonList />}>
        <SlowDataList />
      </Suspense>
      <Footer />
    </>
  );
}

// Parallel data fetching
async function Dashboard() {
  // These run in parallel, not waterfall
  const [users, posts, stats] = await Promise.all([
    fetchUsers(),
    fetchPosts(),
    fetchStats(),
  ]);

  return <DashboardContent users={users} posts={posts} stats={stats} />;
}
```

## Monitoring

### Web Vitals Reporting
```tsx
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next';
import { Analytics } from '@vercel/analytics/react';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <SpeedInsights />
        <Analytics />
      </body>
    </html>
  );
}

// Custom reporting
import { onCLS, onFID, onLCP, onINP, onTTFB } from 'web-vitals';

function sendToAnalytics({ name, delta, id }) {
  // Send to your analytics
}

onCLS(sendToAnalytics);
onFID(sendToAnalytics);
onLCP(sendToAnalytics);
onINP(sendToAnalytics);
onTTFB(sendToAnalytics);
```

### Performance Budgets
```json
// package.json
{
  "bundlesize": [
    {
      "path": ".next/static/chunks/*.js",
      "maxSize": "200 kB"
    },
    {
      "path": ".next/static/css/*.css",
      "maxSize": "50 kB"
    }
  ]
}
```

## Performance Checklist

### Loading
- [ ] Images optimized and lazy loaded
- [ ] Fonts optimized (subset, preload)
- [ ] Code split at route level
- [ ] Critical CSS inlined
- [ ] Third-party scripts deferred

### Rendering
- [ ] Server-side render critical content
- [ ] Avoid layout shifts
- [ ] Virtualize long lists
- [ ] Memoize expensive computations
- [ ] Use CSS animations over JS

### Caching
- [ ] HTTP cache headers set
- [ ] API responses cached
- [ ] Static assets cached
- [ ] Consider service worker

### Monitoring
- [ ] Web Vitals tracked
- [ ] Bundle size monitored
- [ ] Error tracking enabled
- [ ] Performance budgets set

## Tools

- **Lighthouse**: Built into Chrome DevTools
- **WebPageTest**: Detailed performance analysis
- **Chrome DevTools Performance**: Runtime profiling
- **React DevTools Profiler**: Component rendering
- **Bundlephobia**: Package size checking

## Remember

- Measure before optimizing
- Focus on user-perceived performance
- Core Web Vitals affect SEO
- Mobile performance matters most
- Set and monitor budgets
- Continuous optimization
