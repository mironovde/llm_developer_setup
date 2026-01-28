---
name: fullstack-integration
description: Frontend-backend integration patterns including API contracts, authentication flows, error handling, and data fetching. Use when connecting frontend and backend systems.
user-invocable: true
argument-hint: "[integration task or flow]"
---

# Fullstack Integration Skill

You are an expert in fullstack integration. Your role is to connect frontend and backend systems with type-safe APIs, proper authentication, and robust error handling.

## API Contract Design

### Shared Types
```typescript
// packages/shared/types/index.ts

// Base response wrapper
export interface ApiResponse<T> {
  data: T;
  meta?: {
    page?: number;
    perPage?: number;
    total?: number;
    totalPages?: number;
  };
}

// Error response
export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Array<{
      field: string;
      message: string;
    }>;
  };
}

// Domain types
export interface User {
  id: string;
  email: string;
  name: string;
  role: 'user' | 'admin';
  createdAt: string;
}

export interface Post {
  id: string;
  title: string;
  content: string;
  authorId: string;
  author?: User;
  createdAt: string;
  updatedAt: string;
}

// Request types
export interface CreatePostRequest {
  title: string;
  content: string;
}

export interface UpdatePostRequest {
  title?: string;
  content?: string;
}

// Auth types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  user: User;
  accessToken: string;
  refreshToken: string;
}
```

### Zod Schemas (Shared Validation)
```typescript
// packages/shared/schemas/index.ts
import { z } from 'zod';

export const createPostSchema = z.object({
  title: z.string().min(1).max(255),
  content: z.string().min(1).max(10000),
});

export const updatePostSchema = z.object({
  title: z.string().min(1).max(255).optional(),
  content: z.string().min(1).max(10000).optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

// Type inference
export type CreatePostInput = z.infer<typeof createPostSchema>;
export type UpdatePostInput = z.infer<typeof updatePostSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
```

## API Client

### Type-Safe Fetch Wrapper
```typescript
// apps/web/lib/api-client.ts
import { ApiResponse, ApiError } from '@project/shared';

class FetchError extends Error {
  constructor(
    public status: number,
    public error: ApiError['error'],
  ) {
    super(error.message);
    this.name = 'FetchError';
  }
}

async function fetchApi<T>(
  url: string,
  options?: RequestInit,
): Promise<T> {
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const error: ApiError = await response.json();
    throw new FetchError(response.status, error.error);
  }

  return response.json();
}

// API methods
export const api = {
  // Auth
  async login(data: LoginInput): Promise<AuthResponse> {
    return fetchApi('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async logout(): Promise<void> {
    await fetchApi('/api/auth/logout', { method: 'POST' });
  },

  // Posts
  async getPosts(page = 1): Promise<ApiResponse<Post[]>> {
    return fetchApi(`/api/posts?page=${page}`);
  },

  async getPost(id: string): Promise<ApiResponse<Post>> {
    return fetchApi(`/api/posts/${id}`);
  },

  async createPost(data: CreatePostInput): Promise<ApiResponse<Post>> {
    return fetchApi('/api/posts', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async updatePost(id: string, data: UpdatePostInput): Promise<ApiResponse<Post>> {
    return fetchApi(`/api/posts/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  },

  async deletePost(id: string): Promise<void> {
    await fetchApi(`/api/posts/${id}`, { method: 'DELETE' });
  },
};
```

## React Query Integration

### Query Hooks
```typescript
// apps/web/hooks/use-posts.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api-client';
import { CreatePostInput, UpdatePostInput } from '@project/shared';

// Query keys
export const postKeys = {
  all: ['posts'] as const,
  lists: () => [...postKeys.all, 'list'] as const,
  list: (page: number) => [...postKeys.lists(), page] as const,
  details: () => [...postKeys.all, 'detail'] as const,
  detail: (id: string) => [...postKeys.details(), id] as const,
};

// Queries
export function usePosts(page = 1) {
  return useQuery({
    queryKey: postKeys.list(page),
    queryFn: () => api.getPosts(page),
  });
}

export function usePost(id: string) {
  return useQuery({
    queryKey: postKeys.detail(id),
    queryFn: () => api.getPost(id),
    enabled: !!id,
  });
}

// Mutations
export function useCreatePost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreatePostInput) => api.createPost(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: postKeys.lists() });
    },
  });
}

export function useUpdatePost(id: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdatePostInput) => api.updatePost(id, data),
    onSuccess: (response) => {
      queryClient.setQueryData(postKeys.detail(id), response);
      queryClient.invalidateQueries({ queryKey: postKeys.lists() });
    },
  });
}

export function useDeletePost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => api.deletePost(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: postKeys.lists() });
    },
  });
}
```

## Authentication Flow

### Auth Context
```typescript
// apps/web/contexts/auth-context.tsx
'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { User } from '@project/shared';
import { api } from '@/lib/api-client';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing session
    api.getMe()
      .then((response) => setUser(response.data))
      .catch(() => setUser(null))
      .finally(() => setIsLoading(false));
  }, []);

  const login = async (email: string, password: string) => {
    const response = await api.login({ email, password });
    setUser(response.user);
    // Token is stored in httpOnly cookie by backend
  };

  const logout = async () => {
    await api.logout();
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

### Protected Routes
```typescript
// apps/web/components/protected-route.tsx
'use client';

import { useAuth } from '@/contexts/auth-context';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !user) {
      router.push('/login');
    }
  }, [user, isLoading, router]);

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (!user) {
    return null;
  }

  return <>{children}</>;
}
```

## Error Handling

### Global Error Boundary
```typescript
// apps/web/components/error-boundary.tsx
'use client';

import { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? (
        <div className="p-4 text-center">
          <h2>Something went wrong</h2>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### API Error Handling
```typescript
// apps/web/lib/handle-error.ts
import { FetchError } from './api-client';
import { toast } from 'sonner';

export function handleApiError(error: unknown) {
  if (error instanceof FetchError) {
    switch (error.status) {
      case 401:
        // Redirect to login
        window.location.href = '/login';
        break;
      case 403:
        toast.error('You do not have permission to perform this action');
        break;
      case 404:
        toast.error('Resource not found');
        break;
      case 422:
        // Validation errors are handled by forms
        break;
      default:
        toast.error(error.error.message || 'An error occurred');
    }
  } else {
    toast.error('An unexpected error occurred');
    console.error(error);
  }
}
```

## Form Integration

### Type-Safe Form
```typescript
// apps/web/components/create-post-form.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { createPostSchema, CreatePostInput } from '@project/shared';
import { useCreatePost } from '@/hooks/use-posts';
import { handleApiError } from '@/lib/handle-error';

export function CreatePostForm({ onSuccess }: { onSuccess?: () => void }) {
  const createPost = useCreatePost();

  const form = useForm<CreatePostInput>({
    resolver: zodResolver(createPostSchema),
    defaultValues: {
      title: '',
      content: '',
    },
  });

  const onSubmit = async (data: CreatePostInput) => {
    try {
      await createPost.mutateAsync(data);
      form.reset();
      onSuccess?.();
    } catch (error) {
      handleApiError(error);
    }
  };

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <div>
        <label htmlFor="title">Title</label>
        <input
          id="title"
          {...form.register('title')}
          aria-invalid={!!form.formState.errors.title}
        />
        {form.formState.errors.title && (
          <span role="alert">{form.formState.errors.title.message}</span>
        )}
      </div>

      <div>
        <label htmlFor="content">Content</label>
        <textarea
          id="content"
          {...form.register('content')}
          aria-invalid={!!form.formState.errors.content}
        />
        {form.formState.errors.content && (
          <span role="alert">{form.formState.errors.content.message}</span>
        )}
      </div>

      <button type="submit" disabled={createPost.isPending}>
        {createPost.isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

## Environment Configuration

```typescript
// apps/web/lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NEXT_PUBLIC_API_URL: z.string().url(),
  NEXT_PUBLIC_APP_URL: z.string().url(),
});

export const env = envSchema.parse({
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
});
```

## E2E Testing

```typescript
// tests/e2e/posts.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Posts', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await expect(page).toHaveURL('/dashboard');
  });

  test('create post', async ({ page }) => {
    await page.goto('/posts/new');

    await page.fill('[name="title"]', 'Test Post');
    await page.fill('[name="content"]', 'Test content');
    await page.click('button[type="submit"]');

    await expect(page.getByText('Post created')).toBeVisible();
    await expect(page).toHaveURL(/\/posts\/[\w-]+/);
  });

  test('delete post', async ({ page }) => {
    // Create a post first
    await page.goto('/posts/new');
    await page.fill('[name="title"]', 'Post to Delete');
    await page.fill('[name="content"]', 'Content');
    await page.click('button[type="submit"]');

    // Delete it
    await page.click('button[aria-label="Delete post"]');
    await page.click('button:has-text("Confirm")');

    await expect(page.getByText('Post deleted')).toBeVisible();
  });
});
```

## Integration Checklist

- [ ] Shared types between frontend and backend
- [ ] Validation schemas shared
- [ ] Type-safe API client
- [ ] Authentication flow complete
- [ ] Error handling end-to-end
- [ ] Loading states handled
- [ ] Environment configuration
- [ ] E2E tests for critical flows
- [ ] CORS configured correctly
- [ ] API versioning strategy

## Remember

- Type safety end-to-end
- Validate on both client and server
- Handle all error states
- Use optimistic updates wisely
- Test the integration, not just units
- Document API contracts
