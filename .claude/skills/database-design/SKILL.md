---
name: db-design
description: Database schema design, query optimization, and migrations. Covers relational and NoSQL databases, indexing strategies, and ORM patterns. Use for any database work.
user-invocable: true
argument-hint: "[database task or schema]"
---

# Database Design Skill

You are an expert database designer. Your role is to create efficient, scalable database schemas with proper indexing, relationships, and query optimization.

## Schema Design Principles

### Normalization
```sql
-- First Normal Form (1NF): No repeating groups
-- Bad
CREATE TABLE orders (
  id INT,
  product1 VARCHAR(100),
  product2 VARCHAR(100),
  product3 VARCHAR(100)
);

-- Good
CREATE TABLE orders (
  id INT PRIMARY KEY
);
CREATE TABLE order_items (
  id INT PRIMARY KEY,
  order_id INT REFERENCES orders(id),
  product_id INT
);

-- Second Normal Form (2NF): No partial dependencies
-- Third Normal Form (3NF): No transitive dependencies
```

### When to Denormalize
```sql
-- Denormalize for read performance
CREATE TABLE orders (
  id INT PRIMARY KEY,
  user_id INT,
  user_email VARCHAR(255),  -- Denormalized from users
  user_name VARCHAR(100),    -- Denormalized from users
  total DECIMAL(10, 2)
);
-- Trade-off: Faster reads, but data can become stale
```

## PostgreSQL Patterns

### Complete Schema Example
```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'user',
  email_verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,  -- Soft delete

  CONSTRAINT valid_role CHECK (role IN ('user', 'admin', 'moderator'))
);

-- Posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  content TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'draft',
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_status CHECK (status IN ('draft', 'published', 'archived'))
);

-- Tags (many-to-many)
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL UNIQUE,
  slug VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE post_tags (
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)
);

-- Comments (self-referencing for threads)
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Indexes
```sql
-- Single column index
CREATE INDEX idx_users_email ON users(email);

-- Composite index (order matters)
CREATE INDEX idx_posts_author_status ON posts(author_id, status);

-- Partial index (only index subset of rows)
CREATE INDEX idx_posts_published ON posts(published_at)
  WHERE status = 'published';

-- Expression index
CREATE INDEX idx_users_email_lower ON users(LOWER(email));

-- GIN index for full-text search
CREATE INDEX idx_posts_content_search ON posts
  USING GIN(to_tsvector('english', content));

-- BRIN index for time-series data
CREATE INDEX idx_events_created_at ON events
  USING BRIN(created_at);
```

### Triggers
```sql
-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Auto-generate slug
CREATE OR REPLACE FUNCTION generate_slug()
RETURNS TRIGGER AS $$
BEGIN
  NEW.slug = LOWER(REGEXP_REPLACE(NEW.title, '[^a-zA-Z0-9]+', '-', 'g'));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Query Optimization

### EXPLAIN ANALYZE
```sql
-- Always analyze slow queries
EXPLAIN ANALYZE
SELECT p.*, u.name as author_name
FROM posts p
JOIN users u ON p.author_id = u.id
WHERE p.status = 'published'
ORDER BY p.published_at DESC
LIMIT 20;

-- Look for:
-- - Seq Scan (might need index)
-- - High actual time
-- - Rows estimates vs actual
```

### Common Optimizations
```sql
-- Use covering indexes
CREATE INDEX idx_posts_listing ON posts(status, published_at DESC)
  INCLUDE (title, slug);

-- Avoid SELECT *
SELECT id, title, slug, published_at
FROM posts
WHERE status = 'published';

-- Use EXISTS instead of IN for large subqueries
-- Slow
SELECT * FROM users
WHERE id IN (SELECT author_id FROM posts WHERE status = 'published');

-- Fast
SELECT * FROM users u
WHERE EXISTS (
  SELECT 1 FROM posts p
  WHERE p.author_id = u.id AND p.status = 'published'
);

-- Batch operations
-- Slow: Many single inserts
-- Fast: Batch insert
INSERT INTO items (name, value)
VALUES
  ('item1', 100),
  ('item2', 200),
  ('item3', 300);
```

### Pagination
```sql
-- Offset pagination (simple but slow for large offsets)
SELECT * FROM posts
ORDER BY created_at DESC
LIMIT 20 OFFSET 1000;  -- Scans 1020 rows

-- Cursor pagination (efficient)
SELECT * FROM posts
WHERE created_at < '2024-01-01'
ORDER BY created_at DESC
LIMIT 20;

-- Keyset pagination with composite key
SELECT * FROM posts
WHERE (created_at, id) < ('2024-01-01', 'uuid-here')
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

## Migrations

### Prisma Migration
```prisma
// schema.prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        String   @id @default(uuid())
  title     String
  content   String
  author    User     @relation(fields: [authorId], references: [id])
  authorId  String
  tags      Tag[]
  createdAt DateTime @default(now())
}

model Tag {
  id    String @id @default(uuid())
  name  String @unique
  posts Post[]
}
```

### Raw SQL Migration
```sql
-- migrations/001_create_users.sql
-- Up
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

-- Down
DROP TABLE users;
```

### Safe Migration Practices
```sql
-- Add column with default (safe)
ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';

-- Add NOT NULL constraint safely
-- 1. Add nullable column
ALTER TABLE users ADD COLUMN status VARCHAR(20);
-- 2. Backfill data
UPDATE users SET status = 'active' WHERE status IS NULL;
-- 3. Add constraint
ALTER TABLE users ALTER COLUMN status SET NOT NULL;

-- Create index concurrently (doesn't lock table)
CREATE INDEX CONCURRENTLY idx_posts_title ON posts(title);

-- Rename column safely (use new column approach)
ALTER TABLE users ADD COLUMN display_name VARCHAR(100);
UPDATE users SET display_name = name;
-- Later: Remove old column
```

## ORM Patterns

### Prisma
```typescript
// Find with relations
const users = await prisma.user.findMany({
  where: { status: 'active' },
  include: {
    posts: {
      where: { status: 'published' },
      take: 5,
      orderBy: { createdAt: 'desc' },
    },
  },
});

// Transaction
const result = await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { email, name } });
  const post = await tx.post.create({
    data: { title, content, authorId: user.id },
  });
  return { user, post };
});

// Raw query when needed
const users = await prisma.$queryRaw`
  SELECT * FROM users
  WHERE email ILIKE ${`%${search}%`}
`;
```

### SQLAlchemy
```python
from sqlalchemy import Column, String, ForeignKey, select
from sqlalchemy.orm import relationship, selectinload

class User(Base):
    __tablename__ = 'users'

    id = Column(UUID, primary_key=True, default=uuid4)
    email = Column(String(255), unique=True, nullable=False)
    posts = relationship('Post', back_populates='author')

# Query with eager loading
stmt = (
    select(User)
    .options(selectinload(User.posts))
    .where(User.status == 'active')
)
users = session.execute(stmt).scalars().all()
```

## NoSQL (MongoDB)

### Schema Design
```javascript
// Embedded documents (1:few)
{
  _id: ObjectId("..."),
  title: "Post Title",
  content: "...",
  author: {
    _id: ObjectId("..."),
    name: "John",
    email: "john@example.com"
  },
  comments: [
    { _id: ObjectId("..."), content: "Great!", author: "Jane" }
  ]
}

// References (1:many, many:many)
{
  _id: ObjectId("..."),
  title: "Post Title",
  authorId: ObjectId("..."),  // Reference
  tagIds: [ObjectId("..."), ObjectId("...")]  // References
}

// Indexes
db.posts.createIndex({ authorId: 1, createdAt: -1 });
db.posts.createIndex({ title: "text", content: "text" });
```

## Redis Patterns

```typescript
// Caching
await redis.setex(`user:${id}`, 3600, JSON.stringify(user));
const cached = await redis.get(`user:${id}`);

// Rate limiting
const key = `ratelimit:${ip}`;
const count = await redis.incr(key);
if (count === 1) {
  await redis.expire(key, 60);
}
if (count > 100) {
  throw new RateLimitError();
}

// Session storage
await redis.hset(`session:${sessionId}`, {
  userId: user.id,
  createdAt: Date.now(),
});
await redis.expire(`session:${sessionId}`, 86400);
```

## Database Design Checklist

- [ ] Primary keys defined (prefer UUID)
- [ ] Foreign keys with proper actions
- [ ] Appropriate data types
- [ ] NOT NULL where required
- [ ] Unique constraints
- [ ] Check constraints
- [ ] Indexes for frequent queries
- [ ] Indexes for foreign keys
- [ ] Timestamps (created_at, updated_at)
- [ ] Soft delete if needed
- [ ] Migration strategy planned

## Remember

- Design for your queries
- Index early, measure often
- Normalize, then denormalize if needed
- Use transactions for consistency
- Plan for migrations
- Test with realistic data volumes
