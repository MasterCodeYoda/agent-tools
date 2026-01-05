---
name: typescript-patterns
description: TypeScript and React patterns for building robust web applications with type-first development, React hooks, state management, testing patterns, and Clean Architecture implementation in TypeScript
---

# TypeScript/React Patterns and Standards

This skill provides TypeScript and React-specific coding standards, patterns, and best practices for building robust web applications.

## Environment and Tooling

- **Node Version**: 20+ LTS
- **Package Manager**: npm (preferred) or yarn
- **TypeScript**: 5.3+ with strict mode
- **React**: 18+ with functional components
- **Build Tool**: Vite or Next.js
- **Testing**: Vitest + React Testing Library
- **Linting**: ESLint with TypeScript parser
- **Formatting**: Prettier

## TypeScript Configuration

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "allowSyntheticDefaultImports": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx"
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

## Type-First Development

### Type Everything Explicitly

```typescript
// WRONG - Implicit any
function processData(data) {
  return data.map(item => item.value);
}

// WRONG - Implicit return type
function calculateTotal(items: Item[]) {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// RIGHT - Fully typed
function processData(data: DataItem[]): number[] {
  return data.map((item) => item.value);
}

function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

### Domain Types

Create specific types for your domain:

```typescript
// WRONG - Primitive obsession
function transferMoney(
  fromAccount: string,
  toAccount: string,
  amount: number,
  currency: string
): void {
  // ...
}

// RIGHT - Domain types
type AccountId = string & { readonly brand: unique symbol };
type Currency = 'USD' | 'EUR' | 'GBP';

interface Money {
  readonly amount: number;
  readonly currency: Currency;
}

function transferMoney(
  fromAccount: AccountId,
  toAccount: AccountId,
  money: Money
): void {
  // ...
}

// Type branding for compile-time safety
const accountId = '12345' as AccountId;
```

## React Patterns

### Component Structure

```typescript
// UserProfile.tsx
import { FC, memo, useCallback, useMemo } from 'react';

interface UserProfileProps {
  userId: string;
  onEdit?: (userId: string) => void;
  className?: string;
}

export const UserProfile: FC<UserProfileProps> = memo(({
  userId,
  onEdit,
  className
}) => {
  // Hooks at the top
  const { data: user, isLoading, error } = useUser(userId);
  const theme = useTheme();

  // Memoized values
  const fullName = useMemo(
    () => user ? `${user.firstName} ${user.lastName}` : '',
    [user]
  );

  // Callbacks
  const handleEdit = useCallback(() => {
    onEdit?.(userId);
  }, [onEdit, userId]);

  // Early returns for edge cases
  if (isLoading) return <ProfileSkeleton />;
  if (error) return <ErrorMessage error={error} />;
  if (!user) return null;

  // Main render
  return (
    <div className={className}>
      <h2>{fullName}</h2>
      <button onClick={handleEdit}>Edit</button>
    </div>
  );
});

UserProfile.displayName = 'UserProfile';
```

### Custom Hooks

```typescript
// hooks/useApi.ts
import { useState, useEffect, useCallback } from 'react';

interface UseApiState<T> {
  data: T | null;
  isLoading: boolean;
  error: Error | null;
}

interface UseApiOptions {
  immediate?: boolean;
  onSuccess?: <T>(data: T) => void;
  onError?: (error: Error) => void;
}

export function useApi<T>(
  fetcher: () => Promise<T>,
  options: UseApiOptions = {}
): UseApiState<T> & { refetch: () => Promise<void> } {
  const [state, setState] = useState<UseApiState<T>>({
    data: null,
    isLoading: options.immediate ?? true,
    error: null,
  });

  const execute = useCallback(async () => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const data = await fetcher();
      setState({ data, isLoading: false, error: null });
      options.onSuccess?.(data);
    } catch (error) {
      const errorObj = error instanceof Error ? error : new Error(String(error));
      setState({ data: null, isLoading: false, error: errorObj });
      options.onError?.(errorObj);
    }
  }, [fetcher, options.onSuccess, options.onError]);

  useEffect(() => {
    if (options.immediate ?? true) {
      execute();
    }
  }, [execute, options.immediate]);

  return { ...state, refetch: execute };
}
```

### Context Pattern

```typescript
// contexts/AuthContext.tsx
import { createContext, useContext, FC, ReactNode } from 'react';

interface User {
  id: string;
  email: string;
  role: 'admin' | 'user';
}

interface AuthContextValue {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export const AuthProvider: FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);

  const login = useCallback(async (email: string, password: string) => {
    const response = await api.login(email, password);
    setUser(response.user);
  }, []);

  const logout = useCallback(() => {
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({
      user,
      login,
      logout,
      isAuthenticated: !!user,
    }),
    [user, login, logout]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

## SSR/Hybrid Rendering Patterns

Modern React frameworks support hybrid rendering where some components run on the server (Server Components) and others run in the browser (Client Components). These patterns help you make the right decisions about where code should execute.

### Server vs Client Component Decision

Use this decision tree to determine where a component should render:

```typescript
/*
 * SERVER COMPONENT (default) when:
 * - Fetching data from databases or APIs
 * - Accessing backend resources directly
 * - Keeping sensitive data on the server (API keys, tokens)
 * - Large dependencies that shouldn't ship to client
 * - No interactivity needed (display only)
 *
 * CLIENT COMPONENT when:
 * - Using React hooks (useState, useEffect, useContext, etc.)
 * - Adding event handlers (onClick, onChange, etc.)
 * - Using browser-only APIs (window, document, localStorage)
 * - Using class components with lifecycle methods
 * - Relying on custom hooks with state or effects
 */

// Server Component - fetches data, no interactivity
async function ProductList({ categoryId }: { categoryId: string }) {
  // Can fetch directly - runs on server
  const products = await fetchProducts(categoryId);

  return (
    <ul>
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </ul>
  );
}

// Client Component - has interactivity
'use client'; // Framework-specific directive

import { useState } from 'react';

function AddToCartButton({ productId }: { productId: string }) {
  const [isAdding, setIsAdding] = useState(false);

  const handleClick = async () => {
    setIsAdding(true);
    await addToCart(productId);
    setIsAdding(false);
  };

  return (
    <button onClick={handleClick} disabled={isAdding}>
      {isAdding ? 'Adding...' : 'Add to Cart'}
    </button>
  );
}
```

### Composition Patterns for Hybrid Rendering

The key principle: Server Components can render Client Components, but Client Components cannot import Server Components. Use composition to work around this limitation.

```typescript
// WRONG - Client Component importing Server Component
'use client';
import { ServerDataDisplay } from './ServerDataDisplay'; // Error!

function ClientWrapper() {
  return <ServerDataDisplay />;
}

// RIGHT - Pass Server Component as children (slots pattern)
// layout.tsx (Server Component)
async function Layout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();

  return (
    <div>
      <Header user={user} />
      <InteractiveShell>
        {/* Server-rendered content passed as children */}
        {children}
      </InteractiveShell>
    </div>
  );
}

// InteractiveShell.tsx (Client Component)
'use client';

import { useState } from 'react';

interface InteractiveShellProps {
  children: React.ReactNode;
}

function InteractiveShell({ children }: InteractiveShellProps) {
  const [sidebarOpen, setSidebarOpen] = useState(true);

  return (
    <div className={sidebarOpen ? 'with-sidebar' : 'full-width'}>
      <button onClick={() => setSidebarOpen(!sidebarOpen)}>
        Toggle Sidebar
      </button>
      {/* Server-rendered children passed through */}
      <main>{children}</main>
    </div>
  );
}
```

### Data Fetching Patterns

Fetch data as close to where it's used as possible, leveraging automatic request deduplication:

```typescript
// Pattern: Parallel data fetching
async function Dashboard() {
  // These run in parallel, not sequentially
  const [user, stats, notifications] = await Promise.all([
    fetchUser(),
    fetchStats(),
    fetchNotifications(),
  ]);

  return (
    <div>
      <UserProfile user={user} />
      <StatsPanel stats={stats} />
      <NotificationList notifications={notifications} />
    </div>
  );
}

// Pattern: Colocated data fetching with deduplication
// Both components fetch the same user - framework deduplicates the request
async function UserAvatar() {
  const user = await fetchUser(); // Deduped
  return <Avatar src={user.avatarUrl} />;
}

async function UserGreeting() {
  const user = await fetchUser(); // Same request, deduped
  return <h1>Hello, {user.name}!</h1>;
}

// Pattern: Passing data vs fetching
// WRONG - Prop drilling through many levels
async function Page() {
  const user = await fetchUser();
  return <Layout user={user}><Content user={user} /></Layout>;
}

// RIGHT - Fetch where needed (leveraging deduplication)
async function Page() {
  return <Layout><Content /></Layout>;
}

async function Content() {
  const user = await fetchUser(); // Fetch at point of use
  return <div>{user.name}</div>;
}
```

### Loading State Patterns

Use streaming and suspense boundaries to show loading states without blocking:

```typescript
import { Suspense } from 'react';

// Pattern: Granular loading boundaries
async function Page() {
  return (
    <div>
      {/* User info loads first */}
      <Suspense fallback={<HeaderSkeleton />}>
        <Header />
      </Suspense>

      <div className="content">
        {/* Main content can load independently */}
        <Suspense fallback={<ContentSkeleton />}>
          <MainContent />
        </Suspense>

        {/* Sidebar loads independently */}
        <Suspense fallback={<SidebarSkeleton />}>
          <Sidebar />
        </Suspense>
      </div>
    </div>
  );
}

// Pattern: Nested suspense for progressive loading
async function ProductPage({ id }: { id: string }) {
  return (
    <Suspense fallback={<ProductSkeleton />}>
      <ProductDetails id={id} />
      {/* Reviews can load after product details */}
      <Suspense fallback={<ReviewsSkeleton />}>
        <ProductReviews productId={id} />
      </Suspense>
    </Suspense>
  );
}

// Skeleton component pattern
function ProductSkeleton() {
  return (
    <div className="animate-pulse">
      <div className="h-64 bg-gray-200 rounded" />
      <div className="mt-4 h-8 bg-gray-200 rounded w-3/4" />
      <div className="mt-2 h-4 bg-gray-200 rounded w-1/2" />
    </div>
  );
}
```

### Layout Patterns

Layouts persist across navigations and maintain state. Use them strategically:

```typescript
// Root layout - wraps entire application
interface RootLayoutProps {
  children: React.ReactNode;
}

async function RootLayout({ children }: RootLayoutProps) {
  return (
    <html>
      <body>
        <Providers>
          <Header />
          {children}
          <Footer />
        </Providers>
      </body>
    </html>
  );
}

// Nested layout - wraps a route segment
interface DashboardLayoutProps {
  children: React.ReactNode;
}

async function DashboardLayout({ children }: DashboardLayoutProps) {
  const user = await getCurrentUser();

  // This layout persists when navigating between dashboard routes
  return (
    <div className="dashboard">
      <DashboardNav user={user} />
      <main>{children}</main>
    </div>
  );
}

// Pattern: Parallel routes for independent loading
// Use when different sections of a page have different data needs
interface DashboardPageProps {
  overview: React.ReactNode;  // Slot for overview route
  analytics: React.ReactNode; // Slot for analytics route
}

function DashboardPage({ overview, analytics }: DashboardPageProps) {
  return (
    <div className="grid grid-cols-2">
      <section>{overview}</section>
      <section>{analytics}</section>
    </div>
  );
}
```

### Server Actions Pattern

Server Actions allow client components to call server-side functions directly:

```typescript
// actions.ts - Server-side action
'use server';

import { revalidatePath } from 'next/cache';

interface CreatePostResult {
  success: boolean;
  error?: string;
  postId?: string;
}

export async function createPost(formData: FormData): Promise<CreatePostResult> {
  const title = formData.get('title') as string;
  const content = formData.get('content') as string;

  // Validate
  if (!title || title.length < 3) {
    return { success: false, error: 'Title must be at least 3 characters' };
  }

  try {
    const post = await db.post.create({
      data: { title, content },
    });

    // Revalidate the posts list page
    revalidatePath('/posts');

    return { success: true, postId: post.id };
  } catch (error) {
    return { success: false, error: 'Failed to create post' };
  }
}

// PostForm.tsx - Client component using server action
'use client';

import { useActionState } from 'react';
import { createPost } from './actions';

function PostForm() {
  const [state, formAction, isPending] = useActionState(createPost, null);

  return (
    <form action={formAction}>
      <input name="title" placeholder="Title" required />
      <textarea name="content" placeholder="Content" required />

      {state?.error && <p className="error">{state.error}</p>}

      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

### External API Integration

When integrating with external APIs from server components:

```typescript
// Pattern: API client for server components
async function fetchFromExternalAPI<T>(
  endpoint: string,
  options?: RequestInit
): Promise<T> {
  const response = await fetch(`${process.env.API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${process.env.API_KEY}`,
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    // Configure caching behavior
    next: {
      revalidate: 60, // Revalidate every 60 seconds
      tags: ['api-data'], // Tag for manual revalidation
    },
  });

  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`);
  }

  return response.json();
}

// Server component using external API
async function ExternalDataDisplay() {
  const data = await fetchFromExternalAPI<ExternalData>('/endpoint');

  return <DataVisualization data={data} />;
}

// Pattern: Passing server-fetched data to client components
async function ChartPage() {
  // Fetch on server (keeps API keys secure)
  const chartData = await fetchFromExternalAPI<ChartData[]>('/metrics');

  // Pass data to client component for interactivity
  return <InteractiveChart data={chartData} />;
}

// InteractiveChart.tsx
'use client';

interface InteractiveChartProps {
  data: ChartData[];
}

function InteractiveChart({ data }: InteractiveChartProps) {
  const [selectedRange, setSelectedRange] = useState('7d');

  // Client-side filtering of server-fetched data
  const filteredData = useMemo(
    () => filterByRange(data, selectedRange),
    [data, selectedRange]
  );

  return (
    <div>
      <RangeSelector value={selectedRange} onChange={setSelectedRange} />
      <Chart data={filteredData} />
    </div>
  );
}
```

## State Management

### Zustand Store Pattern

```typescript
// stores/userStore.ts
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface User {
  id: string;
  name: string;
  email: string;
}

interface UserStore {
  users: Map<string, User>;
  currentUserId: string | null;

  // Selectors
  getCurrentUser: () => User | undefined;

  // Actions
  setCurrentUser: (userId: string) => void;
  updateUser: (userId: string, updates: Partial<User>) => void;
  deleteUser: (userId: string) => void;
  reset: () => void;
}

export const useUserStore = create<UserStore>()(
  devtools(
    persist(
      immer((set, get) => ({
        users: new Map(),
        currentUserId: null,

        getCurrentUser: () => {
          const { users, currentUserId } = get();
          return currentUserId ? users.get(currentUserId) : undefined;
        },

        setCurrentUser: (userId) =>
          set((state) => {
            state.currentUserId = userId;
          }),

        updateUser: (userId, updates) =>
          set((state) => {
            const user = state.users.get(userId);
            if (user) {
              state.users.set(userId, { ...user, ...updates });
            }
          }),

        deleteUser: (userId) =>
          set((state) => {
            state.users.delete(userId);
            if (state.currentUserId === userId) {
              state.currentUserId = null;
            }
          }),

        reset: () =>
          set((state) => {
            state.users.clear();
            state.currentUserId = null;
          }),
      })),
      {
        name: 'user-store',
      }
    )
  )
);
```

## Error Handling

### Error Boundaries

```typescript
// components/ErrorBoundary.tsx
import { Component, ErrorInfo, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: (error: Error, resetError: () => void) => ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('ErrorBoundary caught:', error, errorInfo);
    // Log to error reporting service
  }

  resetError = (): void => {
    this.setState({ hasError: false, error: null });
  };

  render(): ReactNode {
    if (this.state.hasError && this.state.error) {
      if (this.props.fallback) {
        return this.props.fallback(this.state.error, this.resetError);
      }

      return (
        <div>
          <h2>Something went wrong</h2>
          <button onClick={this.resetError}>Try again</button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Result Pattern

```typescript
// utils/result.ts
export type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

export const Result = {
  ok<T>(data: T): Result<T, never> {
    return { success: true, data };
  },

  err<E>(error: E): Result<never, E> {
    return { success: false, error };
  },

  map<T, U, E>(
    result: Result<T, E>,
    fn: (data: T) => U
  ): Result<U, E> {
    return result.success
      ? Result.ok(fn(result.data))
      : result;
  },

  mapError<T, E, F>(
    result: Result<T, E>,
    fn: (error: E) => F
  ): Result<T, F> {
    return result.success
      ? result
      : Result.err(fn(result.error));
  },
};

// Usage
async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return Result.err(new Error(`HTTP ${response.status}`));
    }
    const user = await response.json();
    return Result.ok(user);
  } catch (error) {
    return Result.err(error as Error);
  }
}
```

## API Integration

### Type-Safe API Client

```typescript
// api/client.ts
interface ApiConfig {
  baseUrl: string;
  headers?: Record<string, string>;
}

class ApiClient {
  constructor(private config: ApiConfig) {}

  private async request<T>(
    endpoint: string,
    options?: RequestInit
  ): Promise<T> {
    const url = `${this.config.baseUrl}${endpoint}`;
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...this.config.headers,
        ...options?.headers,
      },
    });

    if (!response.ok) {
      throw new ApiError(response.status, response.statusText);
    }

    return response.json();
  }

  get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  post<T>(endpoint: string, data?: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  put<T>(endpoint: string, data: unknown): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }
}

// Type-safe API endpoints with proper model naming
interface CreateUserRequest {
  email: string;
  firstName: string;
  lastName: string;
  role?: 'admin' | 'user';
}

interface UpdateUserRequest {
  firstName?: string;
  lastName?: string;
  role?: 'admin' | 'user';
}

interface UserResponse {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'user';
  createdAt: string;
  updatedAt: string;
}

interface UserApi {
  getUser(id: string): Promise<UserResponse>;
  createUser(data: CreateUserRequest): Promise<UserResponse>;
  updateUser(id: string, data: UpdateUserRequest): Promise<UserResponse>;
  deleteUser(id: string): Promise<void>;
}

class UserApiClient implements UserApi {
  constructor(private client: ApiClient) {}

  getUser(id: string): Promise<UserResponse> {
    return this.client.get<UserResponse>(`/users/${id}`);
  }

  createUser(data: CreateUserRequest): Promise<UserResponse> {
    return this.client.post<UserResponse>('/users', data);
  }

  updateUser(id: string, data: UpdateUserRequest): Promise<UserResponse> {
    return this.client.put<UserResponse>(`/users/${id}`, data);
  }

  deleteUser(id: string): Promise<void> {
    return this.client.delete<void>(`/users/${id}`);
  }
}
```

## Testing Patterns

### Test Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    coverage: {
      reporter: ['text', 'html', 'lcov'],
      exclude: ['**/*.test.ts', '**/*.test.tsx', '**/test/**'],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
  },
});

// test/setup.ts
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});
```

### Domain Layer Testing

Test pure business logic without any external dependencies:

```typescript
// domain/order.test.ts
import { describe, it, expect } from 'vitest';
import { Order, OrderItem, OrderStatus } from './order';
import { Money } from './money';

describe('Order', () => {
  describe('calculateTotal', () => {
    it('calculates total correctly for multiple items', () => {
      const order = new Order('order-1');

      order.addItem(new OrderItem({
        productId: 'prod-1',
        price: Money.fromAmount(10.99, 'USD'),
        quantity: 2,
      }));

      order.addItem(new OrderItem({
        productId: 'prod-2',
        price: Money.fromAmount(5.50, 'USD'),
        quantity: 1,
      }));

      expect(order.total.amount).toBe(27.48);
      expect(order.total.currency).toBe('USD');
    });

    it('applies discount correctly', () => {
      const order = new Order('order-1');
      order.addItem(new OrderItem({
        productId: 'prod-1',
        price: Money.fromAmount(100, 'USD'),
        quantity: 1,
      }));

      order.applyDiscount(0.2); // 20% discount

      expect(order.total.amount).toBe(80);
    });
  });

  describe('status transitions', () => {
    it('cannot modify order after confirmation', () => {
      const order = new Order('order-1');
      order.addItem(new OrderItem({
        productId: 'prod-1',
        price: Money.fromAmount(10, 'USD'),
        quantity: 1,
      }));

      order.confirm();

      expect(() => {
        order.addItem(new OrderItem({
          productId: 'prod-2',
          price: Money.fromAmount(5, 'USD'),
          quantity: 1,
        }));
      }).toThrow('Cannot modify confirmed order');
    });

    it('validates state transitions', () => {
      const order = new Order('order-1');

      // Cannot ship unconfirmed order
      expect(() => order.ship()).toThrow('Cannot ship unconfirmed order');

      order.confirm();
      order.ship();

      expect(order.status).toBe(OrderStatus.Shipped);
    });
  });
});
```

### Application Layer Testing

Test use cases with mocked dependencies:

```typescript
// application/createOrder.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { CreateOrderUseCase } from './createOrder';
import type { OrderRepository } from '../repositories/orderRepository';
import type { ProductRepository } from '../repositories/productRepository';
import type { PaymentService } from '../services/paymentService';

describe('CreateOrderUseCase', () => {
  let useCase: CreateOrderUseCase;
  let orderRepo: OrderRepository;
  let productRepo: ProductRepository;
  let paymentService: PaymentService;

  beforeEach(() => {
    orderRepo = {
      save: vi.fn(),
      findById: vi.fn(),
    } as any;

    productRepo = {
      findById: vi.fn(),
      checkStock: vi.fn(),
    } as any;

    paymentService = {
      processPayment: vi.fn(),
    } as any;

    useCase = new CreateOrderUseCase(orderRepo, productRepo, paymentService);
  });

  it('creates order successfully', async () => {
    // Arrange
    const request = {
      customerId: 'cust-123',
      items: [
        { productId: 'prod-1', quantity: 2 },
        { productId: 'prod-2', quantity: 1 },
      ],
      paymentMethod: 'credit_card' as const,
    };

    vi.mocked(productRepo.findById)
      .mockResolvedValueOnce({ id: 'prod-1', price: 10.99, name: 'Product 1' })
      .mockResolvedValueOnce({ id: 'prod-2', price: 5.50, name: 'Product 2' });

    vi.mocked(productRepo.checkStock).mockResolvedValue(true);
    vi.mocked(paymentService.processPayment).mockResolvedValue({ success: true, transactionId: 'txn-123' });

    // Act
    const result = await useCase.execute(request);

    // Assert
    expect(result.orderId).toBeDefined();
    expect(result.total).toBe(27.48);
    expect(orderRepo.save).toHaveBeenCalledOnce();
    expect(paymentService.processPayment).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: 27.48,
        method: 'credit_card',
      })
    );
  });

  it('rolls back order on payment failure', async () => {
    // Arrange
    const request = {
      customerId: 'cust-123',
      items: [{ productId: 'prod-1', quantity: 1 }],
      paymentMethod: 'credit_card' as const,
    };

    vi.mocked(productRepo.findById).mockResolvedValue({ id: 'prod-1', price: 10.99, name: 'Product 1' });
    vi.mocked(productRepo.checkStock).mockResolvedValue(true);
    vi.mocked(paymentService.processPayment).mockRejectedValue(new Error('Payment declined'));

    // Act & Assert
    await expect(useCase.execute(request)).rejects.toThrow('Payment declined');
    expect(orderRepo.save).not.toHaveBeenCalled();
  });
});
```

### React Component Testing

```typescript
// components/UserProfile.test.tsx
import { render, screen, fireEvent, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { vi } from 'vitest';
import { UserProfile } from './UserProfile';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Test utilities
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  });

  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

describe('UserProfile', () => {
  it('renders user information correctly', async () => {
    const mockUser = {
      id: '123',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      role: 'user' as const,
    };

    // Mock API call
    vi.mocked(api.getUser).mockResolvedValue(mockUser);

    render(<UserProfile userId="123" />, { wrapper: createWrapper() });

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument();
    });

    expect(screen.getByText('john@example.com')).toBeInTheDocument();
  });

  it('handles edit flow correctly', async () => {
    const user = userEvent.setup();
    const onEdit = vi.fn();

    render(
      <UserProfile userId="123" onEdit={onEdit} />,
      { wrapper: createWrapper() }
    );

    const editButton = await screen.findByRole('button', { name: /edit/i });
    await user.click(editButton);

    expect(onEdit).toHaveBeenCalledWith('123');
  });

  it('displays error state appropriately', async () => {
    vi.mocked(api.getUser).mockRejectedValue(new Error('User not found'));

    render(<UserProfile userId="invalid" />, { wrapper: createWrapper() });

    await waitFor(() => {
      expect(screen.getByText(/user not found/i)).toBeInTheDocument();
    });

    // Should show retry button
    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument();
  });
});
```

### Hook Testing

```typescript
// hooks/useAuth.test.tsx
import { renderHook, act, waitFor } from '@testing-library/react';
import { vi } from 'vitest';
import { useAuth } from './useAuth';
import { AuthProvider } from '../contexts/AuthContext';

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <AuthProvider>{children}</AuthProvider>
);

describe('useAuth', () => {
  it('handles login flow', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.isAuthenticated).toBe(false);

    await act(async () => {
      await result.current.login('user@example.com', 'password');
    });

    await waitFor(() => {
      expect(result.current.isAuthenticated).toBe(true);
      expect(result.current.user).toEqual(
        expect.objectContaining({
          email: 'user@example.com',
        })
      );
    });
  });

  it('handles logout', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper });

    // Login first
    await act(async () => {
      await result.current.login('user@example.com', 'password');
    });

    expect(result.current.isAuthenticated).toBe(true);

    // Then logout
    act(() => {
      result.current.logout();
    });

    expect(result.current.isAuthenticated).toBe(false);
    expect(result.current.user).toBeNull();
  });
});
```

### Integration Testing

```typescript
// integration/userFlow.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { App } from '../App';
import { setupServer } from 'msw/node';
import { rest } from 'msw';

// Setup MSW for API mocking
const server = setupServer(
  rest.post('/api/login', (req, res, ctx) => {
    return res(
      ctx.json({
        user: { id: '1', email: 'test@example.com' },
        token: 'mock-token',
      })
    );
  }),
  rest.get('/api/users/:id', (req, res, ctx) => {
    return res(
      ctx.json({
        id: req.params.id,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
      })
    );
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('User Flow Integration', () => {
  it('completes full authentication and profile viewing flow', async () => {
    const user = userEvent.setup();

    render(<App />);

    // Login
    const emailInput = screen.getByLabelText(/email/i);
    const passwordInput = screen.getByLabelText(/password/i);
    const loginButton = screen.getByRole('button', { name: /login/i });

    await user.type(emailInput, 'test@example.com');
    await user.type(passwordInput, 'password123');
    await user.click(loginButton);

    // Wait for redirect to dashboard
    await waitFor(() => {
      expect(screen.getByText(/welcome test user/i)).toBeInTheDocument();
    });

    // Navigate to profile
    const profileLink = screen.getByRole('link', { name: /profile/i });
    await user.click(profileLink);

    // Verify profile loads
    await waitFor(() => {
      expect(screen.getByText('test@example.com')).toBeInTheDocument();
    });
  });
});
```

### Store Testing (Zustand)

```typescript
// stores/userStore.test.ts
import { renderHook, act } from '@testing-library/react';
import { useUserStore } from './userStore';

describe('UserStore', () => {
  beforeEach(() => {
    // Reset store before each test
    useUserStore.setState({
      users: new Map(),
      currentUserId: null,
    });
  });

  it('manages users correctly', () => {
    const { result } = renderHook(() => useUserStore());

    // Add user
    act(() => {
      result.current.users.set('user-1', {
        id: 'user-1',
        name: 'John Doe',
        email: 'john@example.com',
      });
    });

    // Set current user
    act(() => {
      result.current.setCurrentUser('user-1');
    });

    expect(result.current.getCurrentUser()).toEqual({
      id: 'user-1',
      name: 'John Doe',
      email: 'john@example.com',
    });

    // Update user
    act(() => {
      result.current.updateUser('user-1', { name: 'Jane Doe' });
    });

    expect(result.current.getCurrentUser()?.name).toBe('Jane Doe');

    // Delete user
    act(() => {
      result.current.deleteUser('user-1');
    });

    expect(result.current.getCurrentUser()).toBeUndefined();
    expect(result.current.currentUserId).toBeNull();
  });
});
```

### Testing Utilities

```typescript
// test/utils.tsx
import { ReactElement, ReactNode } from 'react';
import { render as rtlRender, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';

// Create a custom render function that includes providers
export function renderWithProviders(
  ui: ReactElement,
  {
    route = '/',
    ...renderOptions
  }: RenderOptions & { route?: string } = {}
) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false, staleTime: 0 },
      mutations: { retry: false },
    },
  });

  function Wrapper({ children }: { children: ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={[route]}>
          {children}
        </MemoryRouter>
      </QueryClientProvider>
    );
  }

  return {
    ...rtlRender(ui, { wrapper: Wrapper, ...renderOptions }),
    queryClient,
  };
}

// Mock timers utility
export function useFakeTimers() {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.runOnlyPendingTimers();
    vi.useRealTimers();
  });

  return {
    advance: (ms: number) => vi.advanceTimersByTime(ms),
    runAll: () => vi.runAllTimers(),
  };
}

// Create mock context values
export function createMockAuthContext(overrides = {}) {
  return {
    user: null,
    login: vi.fn(),
    logout: vi.fn(),
    isAuthenticated: false,
    ...overrides,
  };
}
```

### Snapshot Testing

```typescript
// components/Card.test.tsx
import { render } from '@testing-library/react';
import { Card } from './Card';

describe('Card', () => {
  it('matches snapshot with default props', () => {
    const { container } = render(
      <Card title="Test Card">
        <p>Card content</p>
      </Card>
    );

    expect(container.firstChild).toMatchSnapshot();
  });

  it('matches snapshot with all props', () => {
    const { container } = render(
      <Card
        title="Complete Card"
        subtitle="With subtitle"
        footer={<button>Action</button>}
        variant="elevated"
      >
        <p>Full content</p>
      </Card>
    );

    expect(container.firstChild).toMatchSnapshot();
  });
});
```

### Performance Testing

```typescript
// components/LargeList.test.tsx
import { render, screen } from '@testing-library/react';
import { measurePerformance } from '../test/utils';
import { LargeList } from './LargeList';

describe('LargeList Performance', () => {
  it('renders 1000 items within acceptable time', async () => {
    const items = Array.from({ length: 1000 }, (_, i) => ({
      id: `item-${i}`,
      name: `Item ${i}`,
    }));

    const { duration } = await measurePerformance(() => {
      render(<LargeList items={items} />);
    });

    // Should render within 100ms
    expect(duration).toBeLessThan(100);

    // Verify items rendered
    expect(screen.getByText('Item 0')).toBeInTheDocument();
    expect(screen.getByText('Item 999')).toBeInTheDocument();
  });

  it('handles updates efficiently', async () => {
    const { rerender } = render(<LargeList items={[]} />);

    const items = Array.from({ length: 100 }, (_, i) => ({
      id: `item-${i}`,
      name: `Item ${i}`,
    }));

    const { duration } = await measurePerformance(() => {
      rerender(<LargeList items={items} />);
    });

    expect(duration).toBeLessThan(50);
  });
});
```

### Accessibility Testing

```typescript
// components/Form.test.tsx
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
import { Form } from './Form';

expect.extend(toHaveNoViolations);

describe('Form Accessibility', () => {
  it('has no accessibility violations', async () => {
    const { container } = render(
      <Form onSubmit={vi.fn()}>
        <label htmlFor="email">Email</label>
        <input id="email" type="email" required />
        <button type="submit">Submit</button>
      </Form>
    );

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('supports keyboard navigation', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();

    render(
      <Form onSubmit={onSubmit}>
        <input name="field1" />
        <input name="field2" />
        <button type="submit">Submit</button>
      </Form>
    );

    // Tab through form
    await user.tab();
    expect(screen.getByName('field1')).toHaveFocus();

    await user.tab();
    expect(screen.getByName('field2')).toHaveFocus();

    await user.tab();
    expect(screen.getByRole('button')).toHaveFocus();
  });
});
```

## Performance Optimization

### Memoization

```typescript
// WRONG - Creates new object every render
function UserList({ users }: { users: User[] }) {
  return (
    <List
      data={users}
      config={{ showAvatar: true, showEmail: false }} // New object!
    />
  );
}

// RIGHT - Memoized config
const LIST_CONFIG = { showAvatar: true, showEmail: false } as const;

function UserList({ users }: { users: User[] }) {
  return <List data={users} config={LIST_CONFIG} />;
}

// Or with useMemo for dynamic values
function UserList({ users, showEmail }: Props) {
  const config = useMemo(
    () => ({ showAvatar: true, showEmail }),
    [showEmail]
  );

  return <List data={users} config={config} />;
}
```

### Code Splitting

```typescript
// routes/index.tsx
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

// Lazy load route components
const Dashboard = lazy(() => import('./Dashboard'));
const UserProfile = lazy(() => import('./UserProfile'));
const Settings = lazy(() => import('./Settings'));

export function AppRoutes() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/profile/:id" element={<UserProfile />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

## Form Handling

### React Hook Form with Zod

```typescript
// schemas/user.ts
import { z } from 'zod';

export const userFormSchema = z.object({
  email: z.string().email('Invalid email'),
  firstName: z.string().min(1, 'First name required'),
  lastName: z.string().min(1, 'Last name required'),
  age: z.number().min(18, 'Must be 18+').max(120),
  role: z.enum(['admin', 'user']),
});

export type UserFormData = z.infer<typeof userFormSchema>;

// components/UserForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

export function UserForm({ onSubmit }: { onSubmit: (data: UserFormData) => void }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<UserFormData>({
    resolver: zodResolver(userFormSchema),
    defaultValues: {
      role: 'user',
    },
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input
        {...register('email')}
        placeholder="Email"
        aria-invalid={!!errors.email}
      />
      {errors.email && <span>{errors.email.message}</span>}

      <input
        {...register('firstName')}
        placeholder="First Name"
        aria-invalid={!!errors.firstName}
      />
      {errors.firstName && <span>{errors.firstName.message}</span>}

      <select {...register('role')}>
        <option value="user">User</option>
        <option value="admin">Admin</option>
      </select>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Saving...' : 'Save'}
      </button>
    </form>
  );
}
```

## Multi-Step Form (Wizard) Patterns

Multi-step forms (wizards) collect data across multiple screens. These patterns handle step navigation, state management, validation, and persistence.

### Wizard State Machine

Use a state machine pattern to manage wizard flow with type safety:

```typescript
// types/wizard.ts
interface WizardStep<TData> {
  id: string;
  title: string;
  validate?: (data: Partial<TData>) => string[] | null;
  isComplete: (data: Partial<TData>) => boolean;
}

interface WizardState<TData> {
  currentStepIndex: number;
  data: Partial<TData>;
  completedSteps: Set<string>;
  errors: Map<string, string[]>;
  isDirty: boolean;
}

type WizardAction<TData> =
  | { type: 'NEXT' }
  | { type: 'BACK' }
  | { type: 'GO_TO_STEP'; stepIndex: number }
  | { type: 'UPDATE_DATA'; payload: Partial<TData> }
  | { type: 'SET_ERRORS'; stepId: string; errors: string[] }
  | { type: 'CLEAR_ERRORS'; stepId: string }
  | { type: 'RESET' };

function createWizardReducer<TData>(
  steps: WizardStep<TData>[]
) {
  return function wizardReducer(
    state: WizardState<TData>,
    action: WizardAction<TData>
  ): WizardState<TData> {
    switch (action.type) {
      case 'NEXT': {
        const currentStep = steps[state.currentStepIndex];
        const errors = currentStep.validate?.(state.data);

        if (errors && errors.length > 0) {
          return {
            ...state,
            errors: new Map(state.errors).set(currentStep.id, errors),
          };
        }

        const nextIndex = Math.min(state.currentStepIndex + 1, steps.length - 1);
        const completedSteps = new Set(state.completedSteps);
        completedSteps.add(currentStep.id);

        return {
          ...state,
          currentStepIndex: nextIndex,
          completedSteps,
          errors: new Map(state.errors),
        };
      }

      case 'BACK':
        return {
          ...state,
          currentStepIndex: Math.max(state.currentStepIndex - 1, 0),
        };

      case 'GO_TO_STEP': {
        // Only allow jumping to completed steps or current step
        const canNavigate =
          action.stepIndex <= state.currentStepIndex ||
          steps
            .slice(0, action.stepIndex)
            .every((step) => state.completedSteps.has(step.id));

        if (!canNavigate) return state;

        return {
          ...state,
          currentStepIndex: action.stepIndex,
        };
      }

      case 'UPDATE_DATA':
        return {
          ...state,
          data: { ...state.data, ...action.payload },
          isDirty: true,
        };

      case 'SET_ERRORS': {
        const errors = new Map(state.errors);
        errors.set(action.stepId, action.errors);
        return { ...state, errors };
      }

      case 'CLEAR_ERRORS': {
        const errors = new Map(state.errors);
        errors.delete(action.stepId);
        return { ...state, errors };
      }

      case 'RESET':
        return createInitialState<TData>();

      default:
        return state;
    }
  };
}

function createInitialState<TData>(): WizardState<TData> {
  return {
    currentStepIndex: 0,
    data: {},
    completedSteps: new Set(),
    errors: new Map(),
    isDirty: false,
  };
}
```

### useWizard Hook

A reusable hook that encapsulates wizard logic:

```typescript
// hooks/useWizard.ts
import { useReducer, useCallback, useMemo } from 'react';

interface UseWizardOptions<TData> {
  steps: WizardStep<TData>[];
  initialData?: Partial<TData>;
  onComplete?: (data: TData) => void | Promise<void>;
}

interface UseWizardReturn<TData> {
  // State
  currentStep: WizardStep<TData>;
  currentStepIndex: number;
  data: Partial<TData>;
  errors: string[];
  isFirstStep: boolean;
  isLastStep: boolean;
  completedSteps: string[];
  progress: number;

  // Actions
  next: () => void;
  back: () => void;
  goToStep: (index: number) => void;
  updateData: (data: Partial<TData>) => void;
  reset: () => void;
  submit: () => Promise<void>;
}

export function useWizard<TData>({
  steps,
  initialData = {},
  onComplete,
}: UseWizardOptions<TData>): UseWizardReturn<TData> {
  const reducer = useMemo(() => createWizardReducer(steps), [steps]);

  const [state, dispatch] = useReducer(reducer, {
    ...createInitialState<TData>(),
    data: initialData,
  });

  const currentStep = steps[state.currentStepIndex];

  const next = useCallback(() => {
    dispatch({ type: 'NEXT' });
  }, []);

  const back = useCallback(() => {
    dispatch({ type: 'BACK' });
  }, []);

  const goToStep = useCallback((index: number) => {
    dispatch({ type: 'GO_TO_STEP', stepIndex: index });
  }, []);

  const updateData = useCallback((data: Partial<TData>) => {
    dispatch({ type: 'UPDATE_DATA', payload: data });
  }, []);

  const reset = useCallback(() => {
    dispatch({ type: 'RESET' });
  }, []);

  const submit = useCallback(async () => {
    // Validate final step
    const errors = currentStep.validate?.(state.data);
    if (errors && errors.length > 0) {
      dispatch({ type: 'SET_ERRORS', stepId: currentStep.id, errors });
      return;
    }

    // Call completion handler
    await onComplete?.(state.data as TData);
  }, [currentStep, state.data, onComplete]);

  return {
    currentStep,
    currentStepIndex: state.currentStepIndex,
    data: state.data,
    errors: state.errors.get(currentStep.id) ?? [],
    isFirstStep: state.currentStepIndex === 0,
    isLastStep: state.currentStepIndex === steps.length - 1,
    completedSteps: Array.from(state.completedSteps),
    progress: ((state.currentStepIndex + 1) / steps.length) * 100,
    next,
    back,
    goToStep,
    updateData,
    reset,
    submit,
  };
}
```

### Conditional Step Flow

Handle dynamic wizard paths based on user input:

```typescript
// Pattern: Conditional step inclusion
interface ConditionalStep<TData> extends WizardStep<TData> {
  condition?: (data: Partial<TData>) => boolean;
}

function useConditionalWizard<TData>(
  allSteps: ConditionalStep<TData>[],
  data: Partial<TData>
) {
  // Filter steps based on conditions
  const activeSteps = useMemo(
    () => allSteps.filter((step) => !step.condition || step.condition(data)),
    [allSteps, data]
  );

  return useWizard({ steps: activeSteps, initialData: data });
}

// Usage example: Insurance quote wizard
interface QuoteData {
  insuranceType: 'auto' | 'home' | 'life';
  vehicleInfo?: VehicleInfo;
  propertyInfo?: PropertyInfo;
  healthInfo?: HealthInfo;
}

const quoteSteps: ConditionalStep<QuoteData>[] = [
  {
    id: 'type',
    title: 'Insurance Type',
    isComplete: (data) => !!data.insuranceType,
  },
  {
    id: 'vehicle',
    title: 'Vehicle Information',
    condition: (data) => data.insuranceType === 'auto',
    isComplete: (data) => !!data.vehicleInfo,
  },
  {
    id: 'property',
    title: 'Property Information',
    condition: (data) => data.insuranceType === 'home',
    isComplete: (data) => !!data.propertyInfo,
  },
  {
    id: 'health',
    title: 'Health Information',
    condition: (data) => data.insuranceType === 'life',
    isComplete: (data) => !!data.healthInfo,
  },
  {
    id: 'review',
    title: 'Review & Submit',
    isComplete: () => false, // Final step
  },
];
```

### Step-Level Validation

Validate each step independently with schema composition:

```typescript
// schemas/wizardSchemas.ts
import { z } from 'zod';

// Individual step schemas
const personalInfoSchema = z.object({
  firstName: z.string().min(1, 'First name required'),
  lastName: z.string().min(1, 'Last name required'),
  email: z.string().email('Invalid email'),
});

const addressSchema = z.object({
  street: z.string().min(1, 'Street required'),
  city: z.string().min(1, 'City required'),
  state: z.string().length(2, 'Use 2-letter state code'),
  zip: z.string().regex(/^\d{5}(-\d{4})?$/, 'Invalid ZIP code'),
});

const preferencesSchema = z.object({
  notifications: z.boolean(),
  newsletter: z.boolean(),
  theme: z.enum(['light', 'dark', 'system']),
});

// Combined schema for final submission
const fullFormSchema = personalInfoSchema
  .merge(addressSchema)
  .merge(preferencesSchema);

type FullFormData = z.infer<typeof fullFormSchema>;

// Step definitions with validation
const steps: WizardStep<FullFormData>[] = [
  {
    id: 'personal',
    title: 'Personal Information',
    validate: (data) => {
      const result = personalInfoSchema.safeParse(data);
      return result.success ? null : result.error.errors.map((e) => e.message);
    },
    isComplete: (data) => personalInfoSchema.safeParse(data).success,
  },
  {
    id: 'address',
    title: 'Address',
    validate: (data) => {
      const result = addressSchema.safeParse(data);
      return result.success ? null : result.error.errors.map((e) => e.message);
    },
    isComplete: (data) => addressSchema.safeParse(data).success,
  },
  {
    id: 'preferences',
    title: 'Preferences',
    validate: (data) => {
      const result = preferencesSchema.safeParse(data);
      return result.success ? null : result.error.errors.map((e) => e.message);
    },
    isComplete: (data) => preferencesSchema.safeParse(data).success,
  },
];
```

### Progress Persistence

Save wizard progress to prevent data loss:

```typescript
// hooks/useWizardPersistence.ts
import { useEffect, useCallback } from 'react';

interface PersistenceOptions<TData> {
  key: string;
  data: Partial<TData>;
  currentStepIndex: number;
  debounceMs?: number;
}

export function useWizardPersistence<TData>({
  key,
  data,
  currentStepIndex,
  debounceMs = 1000,
}: PersistenceOptions<TData>) {
  // Save to storage with debounce
  useEffect(() => {
    const timeout = setTimeout(() => {
      const state = {
        data,
        currentStepIndex,
        savedAt: new Date().toISOString(),
      };
      localStorage.setItem(key, JSON.stringify(state));
    }, debounceMs);

    return () => clearTimeout(timeout);
  }, [key, data, currentStepIndex, debounceMs]);

  // Load from storage
  const loadSavedState = useCallback(() => {
    const saved = localStorage.getItem(key);
    if (!saved) return null;

    try {
      return JSON.parse(saved) as {
        data: Partial<TData>;
        currentStepIndex: number;
        savedAt: string;
      };
    } catch {
      return null;
    }
  }, [key]);

  // Clear saved state
  const clearSavedState = useCallback(() => {
    localStorage.removeItem(key);
  }, [key]);

  return { loadSavedState, clearSavedState };
}

// Pattern: API-based draft persistence
interface DraftPersistenceOptions<TData> {
  draftId?: string;
  data: Partial<TData>;
  onSave: (data: Partial<TData>) => Promise<{ draftId: string }>;
  debounceMs?: number;
}

export function useApiDraftPersistence<TData>({
  draftId,
  data,
  onSave,
  debounceMs = 2000,
}: DraftPersistenceOptions<TData>) {
  const [isSaving, setIsSaving] = useState(false);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);
  const [currentDraftId, setCurrentDraftId] = useState(draftId);

  useEffect(() => {
    const timeout = setTimeout(async () => {
      setIsSaving(true);
      try {
        const result = await onSave(data);
        setCurrentDraftId(result.draftId);
        setLastSaved(new Date());
      } finally {
        setIsSaving(false);
      }
    }, debounceMs);

    return () => clearTimeout(timeout);
  }, [data, onSave, debounceMs]);

  return { isSaving, lastSaved, draftId: currentDraftId };
}
```

### Wizard UI Components

Accessible, reusable wizard UI components:

```typescript
// components/Wizard.tsx
interface WizardProps<TData> {
  steps: WizardStep<TData>[];
  wizard: UseWizardReturn<TData>;
  renderStep: (step: WizardStep<TData>, wizard: UseWizardReturn<TData>) => React.ReactNode;
}

export function Wizard<TData>({
  steps,
  wizard,
  renderStep,
}: WizardProps<TData>) {
  return (
    <div className="wizard" role="region" aria-label="Multi-step form">
      <WizardProgress steps={steps} wizard={wizard} />
      <WizardContent>
        {renderStep(wizard.currentStep, wizard)}
      </WizardContent>
      <WizardNavigation wizard={wizard} />
    </div>
  );
}

// Progress indicator with accessibility
interface WizardProgressProps<TData> {
  steps: WizardStep<TData>[];
  wizard: UseWizardReturn<TData>;
}

function WizardProgress<TData>({ steps, wizard }: WizardProgressProps<TData>) {
  return (
    <nav aria-label="Form progress">
      <ol className="wizard-steps" role="list">
        {steps.map((step, index) => {
          const isComplete = wizard.completedSteps.includes(step.id);
          const isCurrent = index === wizard.currentStepIndex;
          const isAccessible = isComplete || isCurrent;

          return (
            <li
              key={step.id}
              className={`wizard-step ${isCurrent ? 'current' : ''} ${isComplete ? 'complete' : ''}`}
              aria-current={isCurrent ? 'step' : undefined}
            >
              <button
                onClick={() => wizard.goToStep(index)}
                disabled={!isAccessible}
                aria-label={`${step.title}${isComplete ? ' (completed)' : ''}`}
              >
                <span className="step-number">{index + 1}</span>
                <span className="step-title">{step.title}</span>
              </button>
            </li>
          );
        })}
      </ol>
      <div
        className="progress-bar"
        role="progressbar"
        aria-valuenow={wizard.progress}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={`Form ${Math.round(wizard.progress)}% complete`}
      >
        <div className="progress-fill" style={{ width: `${wizard.progress}%` }} />
      </div>
    </nav>
  );
}

// Navigation with proper focus management
function WizardNavigation<TData>({ wizard }: { wizard: UseWizardReturn<TData> }) {
  const nextButtonRef = useRef<HTMLButtonElement>(null);

  // Focus management after navigation
  useEffect(() => {
    // Focus the main content area after step change
    const content = document.querySelector('.wizard-content');
    if (content instanceof HTMLElement) {
      content.focus();
    }
  }, [wizard.currentStepIndex]);

  return (
    <div className="wizard-nav" role="group" aria-label="Form navigation">
      <button
        type="button"
        onClick={wizard.back}
        disabled={wizard.isFirstStep}
        className="wizard-btn-back"
      >
        Back
      </button>

      {wizard.isLastStep ? (
        <button
          type="button"
          onClick={wizard.submit}
          className="wizard-btn-submit"
          ref={nextButtonRef}
        >
          Submit
        </button>
      ) : (
        <button
          type="button"
          onClick={wizard.next}
          className="wizard-btn-next"
          ref={nextButtonRef}
        >
          Continue
        </button>
      )}
    </div>
  );
}
```

### Step Form Integration

Pattern for integrating step forms with the wizard:

```typescript
// components/steps/PersonalInfoStep.tsx
interface PersonalInfoStepProps {
  data: Partial<FullFormData>;
  onUpdate: (data: Partial<FullFormData>) => void;
  errors: string[];
}

export function PersonalInfoStep({ data, onUpdate, errors }: PersonalInfoStepProps) {
  // Use form library for the step's fields
  const {
    register,
    formState: { errors: fieldErrors },
    watch,
  } = useForm({
    defaultValues: {
      firstName: data.firstName ?? '',
      lastName: data.lastName ?? '',
      email: data.email ?? '',
    },
  });

  // Sync form changes to wizard state
  const watchedValues = watch();
  useEffect(() => {
    onUpdate(watchedValues);
  }, [watchedValues, onUpdate]);

  return (
    <div
      className="wizard-step-content"
      role="group"
      aria-labelledby="step-title"
      tabIndex={-1}
    >
      <h2 id="step-title">Personal Information</h2>

      {/* Show step-level errors */}
      {errors.length > 0 && (
        <div role="alert" className="step-errors">
          <ul>
            {errors.map((error, i) => (
              <li key={i}>{error}</li>
            ))}
          </ul>
        </div>
      )}

      <div className="form-field">
        <label htmlFor="firstName">First Name</label>
        <input
          id="firstName"
          {...register('firstName')}
          aria-invalid={!!fieldErrors.firstName}
          aria-describedby={fieldErrors.firstName ? 'firstName-error' : undefined}
        />
        {fieldErrors.firstName && (
          <span id="firstName-error" className="error">
            {fieldErrors.firstName.message}
          </span>
        )}
      </div>

      <div className="form-field">
        <label htmlFor="lastName">Last Name</label>
        <input
          id="lastName"
          {...register('lastName')}
          aria-invalid={!!fieldErrors.lastName}
        />
      </div>

      <div className="form-field">
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          {...register('email')}
          aria-invalid={!!fieldErrors.email}
        />
      </div>
    </div>
  );
}
```

## Utility Types

### Common Patterns

```typescript
// Make all properties optional except specified
type PartialExcept<T, K extends keyof T> = Partial<T> & Pick<T, K>;

// Make specified properties optional
type PartialPick<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

// Deep readonly
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};

// Nullable properties
type Nullable<T> = { [P in keyof T]: T[P] | null };

// Non-nullable properties
type NonNullable<T> = { [P in keyof T]: NonNullable<T[P]> };

// Extract promise type
type Awaited<T> = T extends Promise<infer U> ? U : T;

// Function component with children
type FCC<P = {}> = FC<PropsWithChildren<P>>;
```

## CSS-in-JS Patterns

### Styled Components / Emotion

```typescript
// styles/theme.ts
export const theme = {
  colors: {
    primary: '#007bff',
    secondary: '#6c757d',
    success: '#28a745',
    danger: '#dc3545',
  },
  spacing: (factor: number) => `${factor * 8}px`,
  breakpoints: {
    sm: '576px',
    md: '768px',
    lg: '992px',
    xl: '1200px',
  },
} as const;

// components/Button.tsx
import styled from '@emotion/styled';

interface ButtonProps {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
}

export const Button = styled.button<ButtonProps>`
  padding: ${({ size = 'md', theme }) =>
    size === 'sm' ? theme.spacing(1) :
    size === 'lg' ? theme.spacing(3) :
    theme.spacing(2)};

  background-color: ${({ variant = 'primary', theme }) =>
    theme.colors[variant]};

  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;

  &:hover {
    opacity: 0.9;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;
```

## Data Visualization Patterns

Patterns for building reusable, accessible chart and visualization components. These patterns are library-agnostic and focus on component composition, data transformation, and accessibility.

### Chart Wrapper Component Pattern

Create a composable wrapper that handles common concerns:

```typescript
// components/charts/ChartContainer.tsx
import { useRef, useEffect, useState, ReactNode } from 'react';

interface ChartContainerProps {
  children: (dimensions: { width: number; height: number }) => ReactNode;
  aspectRatio?: number;
  minHeight?: number;
  className?: string;
  'aria-label': string;
  'aria-describedby'?: string;
}

export function ChartContainer({
  children,
  aspectRatio = 16 / 9,
  minHeight = 200,
  className,
  'aria-label': ariaLabel,
  'aria-describedby': ariaDescribedBy,
}: ChartContainerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });

  useEffect(() => {
    if (!containerRef.current) return;

    const resizeObserver = new ResizeObserver((entries) => {
      const { width } = entries[0].contentRect;
      const height = Math.max(width / aspectRatio, minHeight);
      setDimensions({ width, height });
    });

    resizeObserver.observe(containerRef.current);
    return () => resizeObserver.disconnect();
  }, [aspectRatio, minHeight]);

  return (
    <div
      ref={containerRef}
      className={className}
      role="img"
      aria-label={ariaLabel}
      aria-describedby={ariaDescribedBy}
      style={{ width: '100%', height: dimensions.height || 'auto' }}
    >
      {dimensions.width > 0 && children(dimensions)}
    </div>
  );
}

// Usage
function SalesChart({ data }: { data: SalesData[] }) {
  return (
    <>
      <ChartContainer
        aria-label="Monthly sales chart"
        aria-describedby="sales-chart-description"
        aspectRatio={2}
      >
        {({ width, height }) => (
          <LineChart data={data} width={width} height={height} />
        )}
      </ChartContainer>
      <p id="sales-chart-description" className="sr-only">
        Line chart showing sales trends from January to December.
        Highest sales in December at $45,000.
      </p>
    </>
  );
}
```

### Data Transformation Patterns

Transform API data to chart-ready formats:

```typescript
// utils/chartTransformers.ts

interface ApiDataPoint {
  timestamp: string;
  value: number;
  category?: string;
}

interface ChartDataPoint {
  x: number | string;
  y: number;
  label: string;
}

// Pattern: Generic transformer with accessor functions
interface TransformConfig<TInput, TOutput> {
  xAccessor: (item: TInput) => TOutput['x'];
  yAccessor: (item: TInput) => number;
  labelAccessor?: (item: TInput) => string;
}

function createChartTransformer<TInput>(
  config: TransformConfig<TInput, ChartDataPoint>
) {
  return (data: TInput[]): ChartDataPoint[] =>
    data.map((item) => ({
      x: config.xAccessor(item),
      y: config.yAccessor(item),
      label: config.labelAccessor?.(item) ?? String(config.yAccessor(item)),
    }));
}

// Usage: Transform API response to chart data
const transformSalesData = createChartTransformer<ApiDataPoint>({
  xAccessor: (item) => new Date(item.timestamp).getMonth(),
  yAccessor: (item) => item.value,
  labelAccessor: (item) => `$${item.value.toLocaleString()}`,
});

// Pattern: Aggregation transformer for grouped data
interface GroupedChartData {
  category: string;
  data: ChartDataPoint[];
}

function groupByCategory<T>(
  data: T[],
  categoryAccessor: (item: T) => string,
  transformer: (items: T[]) => ChartDataPoint[]
): GroupedChartData[] {
  const grouped = new Map<string, T[]>();

  data.forEach((item) => {
    const category = categoryAccessor(item);
    const existing = grouped.get(category) ?? [];
    grouped.set(category, [...existing, item]);
  });

  return Array.from(grouped.entries()).map(([category, items]) => ({
    category,
    data: transformer(items),
  }));
}

// Pattern: Time-series bucketing
interface TimeBucket {
  start: Date;
  end: Date;
  value: number;
  count: number;
}

function bucketByTime<T>(
  data: T[],
  dateAccessor: (item: T) => Date,
  valueAccessor: (item: T) => number,
  bucketSizeMs: number
): TimeBucket[] {
  if (data.length === 0) return [];

  const sorted = [...data].sort(
    (a, b) => dateAccessor(a).getTime() - dateAccessor(b).getTime()
  );

  const buckets: TimeBucket[] = [];
  let currentBucket: TimeBucket | null = null;

  sorted.forEach((item) => {
    const date = dateAccessor(item);
    const bucketStart = new Date(
      Math.floor(date.getTime() / bucketSizeMs) * bucketSizeMs
    );

    if (!currentBucket || currentBucket.start.getTime() !== bucketStart.getTime()) {
      currentBucket = {
        start: bucketStart,
        end: new Date(bucketStart.getTime() + bucketSizeMs),
        value: 0,
        count: 0,
      };
      buckets.push(currentBucket);
    }

    currentBucket.value += valueAccessor(item);
    currentBucket.count += 1;
  });

  return buckets;
}
```

### Reusable Chart Hook

Encapsulate chart data and interaction logic:

```typescript
// hooks/useChartData.ts
import { useMemo, useState, useCallback } from 'react';

interface UseChartDataOptions<TRaw, TProcessed> {
  rawData: TRaw[];
  transform: (data: TRaw[]) => TProcessed[];
  filterPredicate?: (item: TRaw) => boolean;
}

interface UseChartDataReturn<TProcessed> {
  data: TProcessed[];
  isEmpty: boolean;
  selectedIndex: number | null;
  hoveredIndex: number | null;
  selectPoint: (index: number | null) => void;
  hoverPoint: (index: number | null) => void;
  getPointProps: (index: number) => {
    selected: boolean;
    hovered: boolean;
    onMouseEnter: () => void;
    onMouseLeave: () => void;
    onClick: () => void;
  };
}

export function useChartData<TRaw, TProcessed>({
  rawData,
  transform,
  filterPredicate,
}: UseChartDataOptions<TRaw, TProcessed>): UseChartDataReturn<TProcessed> {
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const data = useMemo(() => {
    const filtered = filterPredicate
      ? rawData.filter(filterPredicate)
      : rawData;
    return transform(filtered);
  }, [rawData, transform, filterPredicate]);

  const selectPoint = useCallback((index: number | null) => {
    setSelectedIndex(index);
  }, []);

  const hoverPoint = useCallback((index: number | null) => {
    setHoveredIndex(index);
  }, []);

  const getPointProps = useCallback(
    (index: number) => ({
      selected: selectedIndex === index,
      hovered: hoveredIndex === index,
      onMouseEnter: () => hoverPoint(index),
      onMouseLeave: () => hoverPoint(null),
      onClick: () => selectPoint(selectedIndex === index ? null : index),
    }),
    [selectedIndex, hoveredIndex, selectPoint, hoverPoint]
  );

  return {
    data,
    isEmpty: data.length === 0,
    selectedIndex,
    hoveredIndex,
    selectPoint,
    hoverPoint,
    getPointProps,
  };
}
```

### Accessible Chart Patterns

Make charts accessible to screen readers and keyboard navigation:

```typescript
// components/charts/AccessibleChart.tsx
interface AccessibleChartProps<T> {
  data: T[];
  renderChart: (data: T[]) => ReactNode;
  getDataDescription: (data: T[]) => string;
  getDataTable: (data: T[]) => { headers: string[]; rows: string[][] };
  title: string;
  summary: string;
}

export function AccessibleChart<T>({
  data,
  renderChart,
  getDataDescription,
  getDataTable,
  title,
  summary,
}: AccessibleChartProps<T>) {
  const chartId = useId();
  const descriptionId = `${chartId}-desc`;
  const tableId = `${chartId}-table`;

  const { headers, rows } = getDataTable(data);

  return (
    <figure aria-labelledby={chartId}>
      <figcaption id={chartId}>{title}</figcaption>

      {/* Visual chart */}
      <div role="img" aria-describedby={descriptionId}>
        {renderChart(data)}
      </div>

      {/* Screen reader description */}
      <p id={descriptionId} className="sr-only">
        {summary} {getDataDescription(data)}
      </p>

      {/* Accessible data table (visually hidden but available to AT) */}
      <table id={tableId} className="sr-only">
        <caption>Data for {title}</caption>
        <thead>
          <tr>
            {headers.map((header, i) => (
              <th key={i} scope="col">{header}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i}>
              {row.map((cell, j) => (
                <td key={j}>{cell}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}

// Usage
function SalesLineChart({ data }: { data: SalesData[] }) {
  return (
    <AccessibleChart
      data={data}
      title="Monthly Sales Performance"
      summary="Line chart displaying monthly sales figures."
      renderChart={(d) => <LineChartVisual data={d} />}
      getDataDescription={(d) =>
        `Sales ranged from ${Math.min(...d.map((x) => x.amount))} to ` +
        `${Math.max(...d.map((x) => x.amount))} over ${d.length} months.`
      }
      getDataTable={(d) => ({
        headers: ['Month', 'Sales Amount'],
        rows: d.map((item) => [item.month, `$${item.amount.toLocaleString()}`]),
      })}
    />
  );
}
```

### Interactive Tooltip Pattern

Reusable tooltip positioning and content:

```typescript
// hooks/useChartTooltip.ts
import { useState, useCallback, CSSProperties } from 'react';

interface TooltipState<T> {
  isVisible: boolean;
  position: { x: number; y: number };
  data: T | null;
}

interface UseChartTooltipReturn<T> {
  tooltip: TooltipState<T>;
  showTooltip: (data: T, event: React.MouseEvent) => void;
  hideTooltip: () => void;
  getTooltipStyle: () => CSSProperties;
}

export function useChartTooltip<T>(
  offset = { x: 10, y: 10 }
): UseChartTooltipReturn<T> {
  const [tooltip, setTooltip] = useState<TooltipState<T>>({
    isVisible: false,
    position: { x: 0, y: 0 },
    data: null,
  });

  const showTooltip = useCallback(
    (data: T, event: React.MouseEvent) => {
      const rect = event.currentTarget.getBoundingClientRect();
      setTooltip({
        isVisible: true,
        position: {
          x: event.clientX - rect.left + offset.x,
          y: event.clientY - rect.top + offset.y,
        },
        data,
      });
    },
    [offset.x, offset.y]
  );

  const hideTooltip = useCallback(() => {
    setTooltip((prev) => ({ ...prev, isVisible: false }));
  }, []);

  const getTooltipStyle = useCallback((): CSSProperties => ({
    position: 'absolute',
    left: tooltip.position.x,
    top: tooltip.position.y,
    pointerEvents: 'none',
    opacity: tooltip.isVisible ? 1 : 0,
    transition: 'opacity 150ms ease-in-out',
  }), [tooltip.position, tooltip.isVisible]);

  return { tooltip, showTooltip, hideTooltip, getTooltipStyle };
}

// Tooltip component
interface ChartTooltipProps<T> {
  data: T | null;
  isVisible: boolean;
  style: CSSProperties;
  renderContent: (data: T) => ReactNode;
}

export function ChartTooltip<T>({
  data,
  isVisible,
  style,
  renderContent,
}: ChartTooltipProps<T>) {
  if (!isVisible || !data) return null;

  return (
    <div
      role="tooltip"
      style={style}
      className="chart-tooltip"
    >
      {renderContent(data)}
    </div>
  );
}
```

### Loading and Empty States

Consistent loading and empty state patterns for charts:

```typescript
// components/charts/ChartStates.tsx
interface ChartLoadingProps {
  height?: number;
  message?: string;
}

export function ChartLoading({
  height = 300,
  message = 'Loading chart data...',
}: ChartLoadingProps) {
  return (
    <div
      className="chart-loading"
      style={{ height }}
      role="status"
      aria-live="polite"
    >
      <div className="chart-loading-spinner" aria-hidden="true" />
      <span className="sr-only">{message}</span>
    </div>
  );
}

interface ChartEmptyProps {
  height?: number;
  title?: string;
  description?: string;
  action?: ReactNode;
}

export function ChartEmpty({
  height = 300,
  title = 'No data available',
  description = 'There is no data to display for the selected period.',
  action,
}: ChartEmptyProps) {
  return (
    <div
      className="chart-empty"
      style={{ height }}
      role="status"
    >
      <div className="chart-empty-icon" aria-hidden="true">
        {/* Icon SVG */}
      </div>
      <h3 className="chart-empty-title">{title}</h3>
      <p className="chart-empty-description">{description}</p>
      {action && <div className="chart-empty-action">{action}</div>}
    </div>
  );
}

interface ChartErrorProps {
  height?: number;
  error: Error;
  onRetry?: () => void;
}

export function ChartError({
  height = 300,
  error,
  onRetry,
}: ChartErrorProps) {
  return (
    <div
      className="chart-error"
      style={{ height }}
      role="alert"
    >
      <h3 className="chart-error-title">Failed to load chart</h3>
      <p className="chart-error-message">{error.message}</p>
      {onRetry && (
        <button onClick={onRetry} className="chart-error-retry">
          Try again
        </button>
      )}
    </div>
  );
}

// Wrapper component with all states
interface ChartWithStatesProps<T> {
  data: T[] | undefined;
  isLoading: boolean;
  error: Error | null;
  onRetry?: () => void;
  renderChart: (data: T[]) => ReactNode;
  height?: number;
}

export function ChartWithStates<T>({
  data,
  isLoading,
  error,
  onRetry,
  renderChart,
  height = 300,
}: ChartWithStatesProps<T>) {
  if (isLoading) {
    return <ChartLoading height={height} />;
  }

  if (error) {
    return <ChartError height={height} error={error} onRetry={onRetry} />;
  }

  if (!data || data.length === 0) {
    return <ChartEmpty height={height} />;
  }

  return <>{renderChart(data)}</>;
}
```

### Custom SVG Component Pattern

For charts that need custom SVG rendering:

```typescript
// components/charts/SVGChart.tsx
interface SVGChartProps {
  width: number;
  height: number;
  padding?: { top: number; right: number; bottom: number; left: number };
  children: (innerDimensions: {
    width: number;
    height: number;
    padding: { top: number; right: number; bottom: number; left: number };
  }) => ReactNode;
  className?: string;
}

const DEFAULT_PADDING = { top: 20, right: 20, bottom: 40, left: 50 };

export function SVGChart({
  width,
  height,
  padding = DEFAULT_PADDING,
  children,
  className,
}: SVGChartProps) {
  const innerWidth = width - padding.left - padding.right;
  const innerHeight = height - padding.top - padding.bottom;

  return (
    <svg
      width={width}
      height={height}
      className={className}
      role="presentation"
    >
      <g transform={`translate(${padding.left}, ${padding.top})`}>
        {children({ width: innerWidth, height: innerHeight, padding })}
      </g>
    </svg>
  );
}

// Pattern: Scale creators for data-to-pixel mapping
type ScaleFunction = (value: number) => number;

interface CreateScaleOptions {
  domain: [number, number];
  range: [number, number];
}

function createLinearScale({ domain, range }: CreateScaleOptions): ScaleFunction {
  const [d0, d1] = domain;
  const [r0, r1] = range;
  const ratio = (r1 - r0) / (d1 - d0);

  return (value: number) => r0 + (value - d0) * ratio;
}

// Usage in a custom line chart
function CustomLineChart({ data, width, height }: CustomLineChartProps) {
  const xScale = createLinearScale({
    domain: [0, data.length - 1],
    range: [0, width],
  });

  const yScale = createLinearScale({
    domain: [0, Math.max(...data.map((d) => d.value))],
    range: [height, 0], // SVG y-axis is inverted
  });

  const pathData = data
    .map((d, i) => `${i === 0 ? 'M' : 'L'} ${xScale(i)} ${yScale(d.value)}`)
    .join(' ');

  return (
    <SVGChart width={width} height={height}>
      {({ width: innerWidth, height: innerHeight }) => (
        <>
          <path
            d={pathData}
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
          />
          {data.map((d, i) => (
            <circle
              key={i}
              cx={xScale(i)}
              cy={yScale(d.value)}
              r={4}
              fill="currentColor"
            />
          ))}
        </>
      )}
    </SVGChart>
  );
}
```

## File Organization

```
src/
├── components/           # Shared components
│   ├── ui/              # Pure UI components
│   ├── forms/           # Form components
│   └── layout/          # Layout components
├── features/            # Feature-specific code
│   └── user/
│       ├── components/
│       ├── hooks/
│       ├── api/
│       └── types.ts
├── hooks/               # Shared hooks
├── utils/               # Utility functions
├── api/                 # API client and config
├── stores/              # Global state
├── styles/              # Global styles and theme
├── types/               # Shared TypeScript types
└── App.tsx              # Root component
```

Remember: Prioritize type safety, performance, and maintainability. When in doubt, refer to the main AGENTS.md for project standards.