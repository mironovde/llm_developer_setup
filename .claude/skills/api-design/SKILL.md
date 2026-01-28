---
name: api-design
description: REST and GraphQL API design patterns. Covers endpoint design, request/response formats, versioning, documentation, and API best practices. Use for any API design work.
user-invocable: true
argument-hint: "[API endpoint or feature]"
---

# API Design Skill

You are an expert API designer. Your role is to create well-structured, consistent, and developer-friendly APIs following industry best practices.

## REST API Principles

### Resource Naming
```
# Good - Nouns, plural, lowercase
GET    /users
GET    /users/{id}
POST   /users
PUT    /users/{id}
DELETE /users/{id}

# Nested resources
GET    /users/{userId}/posts
POST   /users/{userId}/posts

# Actions as sub-resources
POST   /users/{id}/activate
POST   /orders/{id}/cancel

# Bad - Verbs in URLs
GET    /getUsers
POST   /createUser
DELETE /deleteUser/{id}
```

### HTTP Methods
| Method | Purpose | Idempotent | Safe |
|--------|---------|------------|------|
| GET | Read resource | Yes | Yes |
| POST | Create resource | No | No |
| PUT | Replace resource | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Remove resource | Yes | No |

### Status Codes
```
# Success
200 OK - General success
201 Created - Resource created
204 No Content - Success, no body (DELETE)

# Client Errors
400 Bad Request - Invalid input
401 Unauthorized - Not authenticated
403 Forbidden - Not authorized
404 Not Found - Resource doesn't exist
409 Conflict - Resource conflict
422 Unprocessable Entity - Validation failed
429 Too Many Requests - Rate limited

# Server Errors
500 Internal Server Error - Unexpected error
502 Bad Gateway - Upstream service error
503 Service Unavailable - Temporary overload
```

## Request/Response Patterns

### Success Response
```json
// Single resource
{
  "data": {
    "id": "123",
    "type": "user",
    "attributes": {
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}

// Collection
{
  "data": [
    { "id": "1", "name": "Item 1" },
    { "id": "2", "name": "Item 2" }
  ],
  "meta": {
    "page": 1,
    "perPage": 20,
    "total": 100,
    "totalPages": 5
  },
  "links": {
    "self": "/items?page=1",
    "next": "/items?page=2",
    "last": "/items?page=5"
  }
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request body contains invalid data",
    "details": [
      {
        "field": "email",
        "code": "INVALID_FORMAT",
        "message": "Must be a valid email address"
      },
      {
        "field": "age",
        "code": "OUT_OF_RANGE",
        "message": "Must be between 18 and 120"
      }
    ],
    "requestId": "req_abc123"
  }
}
```

### Pagination
```typescript
// Offset-based (simple, common)
GET /items?page=2&limit=20

// Cursor-based (better for large datasets)
GET /items?cursor=eyJpZCI6MTAwfQ&limit=20

interface PaginatedResponse<T> {
  data: T[];
  meta: {
    cursor?: string;
    hasMore: boolean;
    total?: number;
  };
}
```

### Filtering & Sorting
```
# Filtering
GET /products?category=electronics&minPrice=100&maxPrice=500
GET /users?status=active&role=admin

# Sorting
GET /products?sort=price:asc
GET /products?sort=-createdAt  # Minus for descending

# Field selection (sparse fieldsets)
GET /users?fields=id,name,email
GET /users?include=posts,comments
```

## API Versioning

### URL Versioning (Recommended)
```
GET /v1/users
GET /v2/users
```

### Header Versioning
```
GET /users
Accept: application/vnd.api+json;version=2
```

### Query Parameter
```
GET /users?version=2
```

## Authentication

### JWT Bearer Token
```typescript
// Request
GET /api/protected
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

// Response for unauthorized
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Invalid or expired token"
  }
}
```

### API Key
```typescript
// Header
X-API-Key: sk_live_abc123

// Query (less secure)
GET /api/data?api_key=sk_live_abc123
```

## OpenAPI/Swagger Specification

```yaml
openapi: 3.0.3
info:
  title: My API
  version: 1.0.0
  description: API description

servers:
  - url: https://api.example.com/v1
    description: Production

paths:
  /users:
    get:
      summary: List users
      tags: [Users]
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'

    post:
      summary: Create user
      tags: [Users]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUser'
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '422':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ValidationError'

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        email:
          type: string
          format: email
        createdAt:
          type: string
          format: date-time
      required: [id, name, email]

    CreateUser:
      type: object
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
        email:
          type: string
          format: email
        password:
          type: string
          minLength: 8
      required: [name, email, password]

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
```

## Implementation Examples

### Express.js
```typescript
import { Router } from 'express';
import { z } from 'zod';

const router = Router();

// Validation schema
const createUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  password: z.string().min(8),
});

// Route handler
router.post('/users', async (req, res, next) => {
  try {
    const body = createUserSchema.parse(req.body);
    const user = await userService.create(body);
    res.status(201).json({ data: user });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(422).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Invalid input',
          details: error.errors.map(e => ({
            field: e.path.join('.'),
            message: e.message,
          })),
        },
      });
    }
    next(error);
  }
});
```

### FastAPI (Python)
```python
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, EmailStr
from typing import List, Optional

app = FastAPI()

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str

class User(BaseModel):
    id: str
    name: str
    email: str

class PaginatedUsers(BaseModel):
    data: List[User]
    meta: dict

@app.get("/users", response_model=PaginatedUsers)
async def list_users(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100)
):
    users = await user_service.list(page=page, limit=limit)
    total = await user_service.count()

    return {
        "data": users,
        "meta": {
            "page": page,
            "limit": limit,
            "total": total
        }
    }

@app.post("/users", response_model=User, status_code=201)
async def create_user(user: UserCreate):
    return await user_service.create(user)
```

## GraphQL

### Schema Design
```graphql
type Query {
  user(id: ID!): User
  users(filter: UserFilter, pagination: Pagination): UserConnection!
}

type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!
  deleteUser(id: ID!): DeleteUserPayload!
}

type User {
  id: ID!
  name: String!
  email: String!
  posts(first: Int, after: String): PostConnection!
  createdAt: DateTime!
}

input CreateUserInput {
  name: String!
  email: String!
  password: String!
}

type CreateUserPayload {
  user: User
  errors: [UserError!]
}

type UserError {
  field: String
  message: String!
}

# Relay-style pagination
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

## Rate Limiting

### Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
Retry-After: 60
```

### Response (429)
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "retryAfter": 60
  }
}
```

## API Design Checklist

- [ ] Resources use nouns, not verbs
- [ ] Consistent naming (plural, lowercase)
- [ ] Proper HTTP methods used
- [ ] Appropriate status codes
- [ ] Consistent error format
- [ ] Pagination for lists
- [ ] Filtering and sorting
- [ ] Versioning strategy
- [ ] Authentication documented
- [ ] Rate limiting implemented
- [ ] OpenAPI spec complete

## Remember

- APIs are UIs for developers
- Consistency is key
- Document everything
- Version from day one
- Design for evolution
- Error messages help debugging
