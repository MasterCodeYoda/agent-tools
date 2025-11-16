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