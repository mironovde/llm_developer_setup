---
name: backend-testing
description: Backend testing strategies including unit tests, integration tests, API tests, and load testing. Covers testing frameworks and best practices. Use for any backend testing.
user-invocable: true
argument-hint: "[service or endpoint to test]"
---

# Backend Testing Skill

You are an expert in backend testing. Your role is to ensure backend services are reliable, correct, and performant through comprehensive testing strategies.

## Testing Strategy

### Test Pyramid for Backend
```
         /\
        /E2E\        <- Contract tests, full integration
       /-----\
      /API    \      <- HTTP endpoint tests
     /---------\
    /Integration\    <- Database, external services
   /-------------\
  /    Unit       \  <- Pure business logic
 /-----------------\
```

## Unit Testing

### Jest (Node.js)
```typescript
// userService.test.ts
import { UserService } from './userService';
import { MockUserRepository } from './__mocks__/userRepository';

describe('UserService', () => {
  let service: UserService;
  let mockRepo: MockUserRepository;

  beforeEach(() => {
    mockRepo = new MockUserRepository();
    service = new UserService(mockRepo);
  });

  describe('createUser', () => {
    it('should create user with hashed password', async () => {
      const input = {
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      };

      const user = await service.createUser(input);

      expect(user.email).toBe(input.email);
      expect(user.name).toBe(input.name);
      expect(user.password).toBeUndefined();
      expect(mockRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: input.email,
          passwordHash: expect.any(String),
        })
      );
    });

    it('should throw if email already exists', async () => {
      mockRepo.findByEmail.mockResolvedValue({ id: '1', email: 'test@example.com' });

      await expect(
        service.createUser({
          email: 'test@example.com',
          password: 'password123',
          name: 'Test',
        })
      ).rejects.toThrow('Email already exists');
    });
  });

  describe('validatePassword', () => {
    it('should return true for correct password', async () => {
      const user = await service.createUser({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test',
      });

      const isValid = await service.validatePassword(user.id, 'password123');

      expect(isValid).toBe(true);
    });

    it('should return false for incorrect password', async () => {
      const user = await service.createUser({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test',
      });

      const isValid = await service.validatePassword(user.id, 'wrongpassword');

      expect(isValid).toBe(false);
    });
  });
});
```

### Pytest (Python)
```python
# test_user_service.py
import pytest
from unittest.mock import Mock, AsyncMock
from user_service import UserService

@pytest.fixture
def mock_repo():
    repo = Mock()
    repo.find_by_email = AsyncMock(return_value=None)
    repo.create = AsyncMock()
    return repo

@pytest.fixture
def service(mock_repo):
    return UserService(mock_repo)

class TestUserService:
    @pytest.mark.asyncio
    async def test_create_user_success(self, service, mock_repo):
        user_data = {
            "email": "test@example.com",
            "password": "password123",
            "name": "Test User"
        }

        user = await service.create_user(**user_data)

        assert user.email == user_data["email"]
        assert user.name == user_data["name"]
        mock_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_create_user_email_exists(self, service, mock_repo):
        mock_repo.find_by_email.return_value = {"id": "1", "email": "test@example.com"}

        with pytest.raises(ValueError, match="Email already exists"):
            await service.create_user(
                email="test@example.com",
                password="password123",
                name="Test"
            )

    @pytest.mark.parametrize("password,expected", [
        ("short", False),
        ("validpassword123", True),
        ("", False),
    ])
    def test_validate_password_format(self, service, password, expected):
        result = service.validate_password_format(password)
        assert result == expected
```

## Integration Testing

### Database Tests
```typescript
// userRepository.integration.test.ts
import { PrismaClient } from '@prisma/client';
import { UserRepository } from './userRepository';

describe('UserRepository Integration', () => {
  let prisma: PrismaClient;
  let repo: UserRepository;

  beforeAll(async () => {
    prisma = new PrismaClient({
      datasources: {
        db: { url: process.env.TEST_DATABASE_URL },
      },
    });
    repo = new UserRepository(prisma);
  });

  beforeEach(async () => {
    // Clean database before each test
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should create and retrieve user', async () => {
    const created = await repo.create({
      email: 'test@example.com',
      name: 'Test User',
      passwordHash: 'hash',
    });

    const found = await repo.findById(created.id);

    expect(found).toMatchObject({
      id: created.id,
      email: 'test@example.com',
      name: 'Test User',
    });
  });

  it('should find user by email', async () => {
    await repo.create({
      email: 'test@example.com',
      name: 'Test User',
      passwordHash: 'hash',
    });

    const found = await repo.findByEmail('test@example.com');

    expect(found).not.toBeNull();
    expect(found?.email).toBe('test@example.com');
  });

  it('should return null for non-existent email', async () => {
    const found = await repo.findByEmail('nonexistent@example.com');
    expect(found).toBeNull();
  });
});
```

### External Service Mocks
```typescript
// With MSW (Mock Service Worker)
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('https://api.stripe.com/v1/customers/:id', (req, res, ctx) => {
    return res(
      ctx.json({
        id: req.params.id,
        email: 'customer@example.com',
        name: 'Test Customer',
      })
    );
  }),

  rest.post('https://api.stripe.com/v1/charges', async (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({
        id: 'ch_test',
        amount: 1000,
        status: 'succeeded',
      })
    );
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe('PaymentService', () => {
  it('should process payment successfully', async () => {
    const service = new PaymentService();
    const result = await service.charge('cus_123', 1000);
    expect(result.status).toBe('succeeded');
  });

  it('should handle payment failure', async () => {
    server.use(
      rest.post('https://api.stripe.com/v1/charges', (req, res, ctx) => {
        return res(
          ctx.status(402),
          ctx.json({ error: { message: 'Card declined' } })
        );
      })
    );

    const service = new PaymentService();
    await expect(service.charge('cus_123', 1000)).rejects.toThrow('Card declined');
  });
});
```

## API Testing

### Supertest (Express)
```typescript
import request from 'supertest';
import { app } from './app';
import { prisma } from './db';

describe('User API', () => {
  let authToken: string;

  beforeAll(async () => {
    // Create test user and get token
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      });
    authToken = response.body.token;
  });

  afterAll(async () => {
    await prisma.user.deleteMany();
  });

  describe('GET /api/users', () => {
    it('should return 401 without auth', async () => {
      const response = await request(app).get('/api/users');
      expect(response.status).toBe(401);
    });

    it('should return users with auth', async () => {
      const response = await request(app)
        .get('/api/users')
        .set('Authorization', `Bearer ${authToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data).toBeInstanceOf(Array);
    });
  });

  describe('POST /api/users', () => {
    it('should create user with valid data', async () => {
      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: 'new@example.com',
          password: 'password123',
          name: 'New User',
        });

      expect(response.status).toBe(201);
      expect(response.body.data).toMatchObject({
        email: 'new@example.com',
        name: 'New User',
      });
    });

    it('should return 422 for invalid data', async () => {
      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          email: 'invalid-email',
          password: 'short',
        });

      expect(response.status).toBe(422);
      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });
});
```

### FastAPI TestClient
```python
from fastapi.testclient import TestClient
from app.main import app
import pytest

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def auth_headers(client):
    response = client.post("/api/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

class TestUserAPI:
    def test_get_users_unauthorized(self, client):
        response = client.get("/api/users")
        assert response.status_code == 401

    def test_get_users_authorized(self, client, auth_headers):
        response = client.get("/api/users", headers=auth_headers)
        assert response.status_code == 200
        assert isinstance(response.json()["data"], list)

    def test_create_user_valid(self, client, auth_headers):
        response = client.post(
            "/api/users",
            headers=auth_headers,
            json={
                "email": "new@example.com",
                "password": "password123",
                "name": "New User"
            }
        )
        assert response.status_code == 201
        assert response.json()["data"]["email"] == "new@example.com"

    def test_create_user_invalid(self, client, auth_headers):
        response = client.post(
            "/api/users",
            headers=auth_headers,
            json={"email": "invalid"}
        )
        assert response.status_code == 422
```

## Load Testing

### k6 Script
```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // Ramp up to 20 users
    { duration: '1m', target: 20 },    // Stay at 20 users
    { duration: '30s', target: 100 },  // Spike to 100 users
    { duration: '1m', target: 100 },   // Stay at 100 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],    // Less than 1% failure rate
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export function setup() {
  // Login and get token
  const res = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: 'loadtest@example.com',
    password: 'password123',
  }), {
    headers: { 'Content-Type': 'application/json' },
  });
  return { token: res.json('token') };
}

export default function(data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.token}`,
  };

  // Test GET /api/users
  const usersRes = http.get(`${BASE_URL}/api/users`, { headers });
  check(usersRes, {
    'users status is 200': (r) => r.status === 200,
    'users response time < 200ms': (r) => r.timings.duration < 200,
  });

  // Test GET /api/posts
  const postsRes = http.get(`${BASE_URL}/api/posts?limit=20`, { headers });
  check(postsRes, {
    'posts status is 200': (r) => r.status === 200,
    'posts has data': (r) => r.json('data').length > 0,
  });

  sleep(1);
}
```

## Test Utilities

### Factories
```typescript
// factories/user.ts
import { faker } from '@faker-js/faker';

export const createUserData = (overrides = {}) => ({
  email: faker.internet.email(),
  name: faker.person.fullName(),
  password: faker.internet.password({ length: 12 }),
  ...overrides,
});

export const createUser = async (overrides = {}) => {
  const data = createUserData(overrides);
  return prisma.user.create({ data });
};

// Usage in tests
it('should create user', async () => {
  const user = await createUser({ role: 'admin' });
  expect(user.role).toBe('admin');
});
```

### Test Database Setup
```typescript
// setup.ts
import { PrismaClient } from '@prisma/client';
import { execSync } from 'child_process';

const prisma = new PrismaClient();

export async function setupTestDatabase() {
  // Push schema to test database
  execSync('npx prisma db push --skip-generate', {
    env: {
      ...process.env,
      DATABASE_URL: process.env.TEST_DATABASE_URL,
    },
  });
}

export async function cleanDatabase() {
  const tables = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  `;

  for (const { tablename } of tables) {
    if (tablename !== '_prisma_migrations') {
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE "${tablename}" CASCADE`);
    }
  }
}
```

## Testing Checklist

### Unit Tests
- [ ] Business logic tested
- [ ] Edge cases covered
- [ ] Error handling tested
- [ ] Dependencies mocked

### Integration Tests
- [ ] Database operations
- [ ] External service calls
- [ ] Transaction handling

### API Tests
- [ ] All endpoints tested
- [ ] Authentication/authorization
- [ ] Input validation
- [ ] Error responses

### Load Tests
- [ ] Normal load
- [ ] Peak load
- [ ] Spike scenarios
- [ ] Performance thresholds

## Remember

- Test behavior, not implementation
- Keep tests fast and independent
- Use factories for test data
- Clean state between tests
- Mock external dependencies
- Test error paths
