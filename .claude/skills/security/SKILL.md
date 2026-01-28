---
name: security
description: Application security including authentication, authorization, OWASP Top 10, and security best practices. Covers input validation, encryption, and secure coding. Use for any security review.
user-invocable: true
argument-hint: "[feature or code to review]"
---

# Security Skill

You are an expert in application security. Your role is to identify vulnerabilities, implement secure coding practices, and ensure applications follow security best practices.

## OWASP Top 10 (2021)

### A01: Broken Access Control

**Problem**: Users can act outside their intended permissions.

**Prevention**:
```typescript
// Bad: Direct object reference without authorization
app.get('/users/:id/data', async (req, res) => {
  const data = await db.getData(req.params.id);
  res.json(data);
});

// Good: Check authorization
app.get('/users/:id/data', authenticate, async (req, res) => {
  // Verify user can access this resource
  if (req.user.id !== req.params.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  const data = await db.getData(req.params.id);
  res.json(data);
});

// Role-based access control
const requireRole = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.role)) {
    return res.status(403).json({ error: 'Insufficient permissions' });
  }
  next();
};

app.delete('/users/:id', authenticate, requireRole('admin'), deleteUser);
```

### A02: Cryptographic Failures

**Problem**: Sensitive data exposed due to weak or missing cryptography.

**Prevention**:
```typescript
import bcrypt from 'bcrypt';
import crypto from 'crypto';

// Password hashing
const SALT_ROUNDS = 12;

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

// Encryption at rest
const ALGORITHM = 'aes-256-gcm';
const KEY = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex');

function encrypt(text: string): { encrypted: string; iv: string; tag: string } {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv);

  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');

  return {
    encrypted,
    iv: iv.toString('hex'),
    tag: cipher.getAuthTag().toString('hex'),
  };
}

function decrypt(encrypted: string, iv: string, tag: string): string {
  const decipher = crypto.createDecipheriv(
    ALGORITHM,
    KEY,
    Buffer.from(iv, 'hex')
  );
  decipher.setAuthTag(Buffer.from(tag, 'hex'));

  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');

  return decrypted;
}

// Secure token generation
function generateSecureToken(): string {
  return crypto.randomBytes(32).toString('hex');
}
```

### A03: Injection

**Problem**: Untrusted data sent to interpreter as command or query.

**Prevention**:
```typescript
// SQL Injection Prevention

// Bad: String concatenation
const query = `SELECT * FROM users WHERE email = '${email}'`;

// Good: Parameterized queries
const result = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);

// Good: ORM with proper escaping
const user = await prisma.user.findUnique({
  where: { email },
});

// NoSQL Injection Prevention
// Bad
const user = await User.findOne({ email: req.body.email });

// Good: Validate and sanitize
import { z } from 'zod';

const schema = z.object({
  email: z.string().email(),
});

const { email } = schema.parse(req.body);
const user = await User.findOne({ email });

// Command Injection Prevention
// Bad
exec(`convert ${filename} output.pdf`);

// Good: Use arrays and avoid shell
execFile('convert', [filename, 'output.pdf']);
```

### A04: Insecure Design

**Problem**: Flaws in design that can't be fixed by implementation.

**Prevention**:
- Threat modeling during design
- Secure design patterns
- Defense in depth
- Principle of least privilege

```typescript
// Example: Secure password reset flow
// 1. Generate time-limited, single-use token
const resetToken = crypto.randomBytes(32).toString('hex');
const tokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
const expiresAt = new Date(Date.now() + 3600000); // 1 hour

await db.passwordReset.create({
  userId,
  tokenHash,
  expiresAt,
});

// 2. Send token via email (not in URL params)
await sendEmail({
  to: user.email,
  subject: 'Password Reset',
  body: `Reset link: ${baseUrl}/reset?token=${resetToken}`,
});

// 3. Validate token securely
const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
const reset = await db.passwordReset.findFirst({
  where: {
    tokenHash,
    expiresAt: { gt: new Date() },
    usedAt: null,
  },
});

if (!reset) {
  throw new Error('Invalid or expired token');
}

// 4. Mark as used (single-use)
await db.passwordReset.update({
  where: { id: reset.id },
  data: { usedAt: new Date() },
});
```

### A05: Security Misconfiguration

**Prevention**:
```typescript
// Helmet for Express
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

// CORS configuration
import cors from 'cors';

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || [],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Environment variables
// Never commit secrets to version control
// Use .env files for development
// Use secrets manager for production
```

### A07: Cross-Site Scripting (XSS)

**Prevention**:
```typescript
// Output encoding
import { escape } from 'html-escaper';

// In templates (React does this automatically)
const SafeComponent = ({ userInput }) => (
  <div>{userInput}</div>  // React escapes by default
);

// For raw HTML (use sparingly)
const sanitized = DOMPurify.sanitize(userHtml);

// Content Security Policy
app.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self'"
  );
  next();
});

// HttpOnly cookies (prevent JS access)
res.cookie('session', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',
});
```

### A08: Cross-Site Request Forgery (CSRF)

**Prevention**:
```typescript
import csrf from 'csurf';

// CSRF middleware
const csrfProtection = csrf({ cookie: true });

app.get('/form', csrfProtection, (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() });
});

app.post('/submit', csrfProtection, (req, res) => {
  // Token validated automatically
});

// For SPAs: Use SameSite cookies
res.cookie('session', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',  // Prevents CSRF
});

// Double submit cookie pattern
app.post('/api/action', (req, res) => {
  const cookieToken = req.cookies['csrf-token'];
  const headerToken = req.headers['x-csrf-token'];

  if (cookieToken !== headerToken) {
    return res.status(403).json({ error: 'CSRF validation failed' });
  }
  // Process request
});
```

## Authentication

### JWT Implementation
```typescript
import jwt from 'jsonwebtoken';

interface TokenPayload {
  userId: string;
  role: string;
}

const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

function generateTokens(user: User) {
  const accessToken = jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET!,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );

  const refreshToken = jwt.sign(
    { userId: user.id, tokenVersion: user.tokenVersion },
    process.env.JWT_REFRESH_SECRET!,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );

  return { accessToken, refreshToken };
}

function verifyAccessToken(token: string): TokenPayload {
  return jwt.verify(token, process.env.JWT_SECRET!) as TokenPayload;
}

// Middleware
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing token' });
  }

  try {
    const token = authHeader.split(' ')[1];
    const payload = verifyAccessToken(token);
    req.user = payload;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};
```

### Password Policy
```typescript
import { z } from 'zod';

const passwordSchema = z.string()
  .min(8, 'Password must be at least 8 characters')
  .max(128, 'Password must be at most 128 characters')
  .regex(/[A-Z]/, 'Password must contain uppercase letter')
  .regex(/[a-z]/, 'Password must contain lowercase letter')
  .regex(/[0-9]/, 'Password must contain number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain special character');

// Check against common passwords
import commonPasswords from 'common-password-list';

function validatePassword(password: string): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  try {
    passwordSchema.parse(password);
  } catch (e) {
    if (e instanceof z.ZodError) {
      errors.push(...e.errors.map(err => err.message));
    }
  }

  if (commonPasswords.includes(password.toLowerCase())) {
    errors.push('Password is too common');
  }

  return { valid: errors.length === 0, errors };
}
```

## Input Validation

```typescript
import { z } from 'zod';

// Define schemas
const createUserSchema = z.object({
  email: z.string().email().toLowerCase(),
  name: z.string().min(1).max(100).trim(),
  age: z.number().int().min(18).max(120).optional(),
  role: z.enum(['user', 'admin']).default('user'),
});

// Validation middleware
const validate = (schema: z.ZodSchema) => (req, res, next) => {
  try {
    req.body = schema.parse(req.body);
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(422).json({
        error: {
          code: 'VALIDATION_ERROR',
          details: error.errors,
        },
      });
    }
    next(error);
  }
};

app.post('/users', validate(createUserSchema), createUser);
```

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

// General rate limit
const generalLimiter = rateLimit({
  store: new RedisStore({ sendCommand: (...args) => redis.call(...args) }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: { error: 'Too many requests' },
});

// Strict limit for auth endpoints
const authLimiter = rateLimit({
  store: new RedisStore({ sendCommand: (...args) => redis.call(...args) }),
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  message: { error: 'Too many login attempts' },
});

app.use('/api/', generalLimiter);
app.use('/api/auth/login', authLimiter);
```

## Logging & Monitoring

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  redact: ['req.headers.authorization', 'password', 'token'],
});

// Security event logging
function logSecurityEvent(event: string, details: object) {
  logger.warn({
    type: 'security',
    event,
    ...details,
    timestamp: new Date().toISOString(),
  });
}

// Usage
logSecurityEvent('failed_login', {
  email: req.body.email,
  ip: req.ip,
  userAgent: req.headers['user-agent'],
});

logSecurityEvent('permission_denied', {
  userId: req.user?.id,
  resource: req.path,
  method: req.method,
});
```

## Security Checklist

### Authentication
- [ ] Strong password policy
- [ ] Secure password storage (bcrypt)
- [ ] MFA available
- [ ] Account lockout after failures
- [ ] Secure password reset flow

### Authorization
- [ ] Principle of least privilege
- [ ] Role-based access control
- [ ] Resource-level permissions
- [ ] Authorization on every request

### Data Protection
- [ ] HTTPS everywhere
- [ ] Sensitive data encrypted at rest
- [ ] Secure session management
- [ ] HttpOnly, Secure, SameSite cookies

### Input/Output
- [ ] Input validation on all endpoints
- [ ] Output encoding
- [ ] Parameterized queries
- [ ] Content Security Policy

### Infrastructure
- [ ] Security headers (Helmet)
- [ ] CORS properly configured
- [ ] Rate limiting
- [ ] Security logging and monitoring
- [ ] Dependency scanning

## Remember

- Security is not a feature, it's a requirement
- Defense in depth
- Never trust user input
- Fail securely
- Keep dependencies updated
- Regular security audits
