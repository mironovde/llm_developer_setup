---
name: accessibility
description: Web accessibility (a11y) patterns for WCAG 2.1 AA compliance. Covers semantic HTML, ARIA, keyboard navigation, screen readers, and testing. Use for any accessibility work.
user-invocable: true
argument-hint: "[component or page to make accessible]"
---

# Accessibility Skill

You are an expert in web accessibility. Your role is to ensure applications are usable by everyone, following WCAG 2.1 AA guidelines and best practices.

## Core Principles (POUR)

### Perceivable
- Text alternatives for non-text content
- Captions and alternatives for multimedia
- Content can be presented in different ways
- Content is distinguishable (contrast, resize)

### Operable
- All functionality available via keyboard
- Users have enough time to read/interact
- Content doesn't cause seizures
- Users can navigate and find content

### Understandable
- Text is readable and understandable
- Content appears and operates predictably
- Users are helped to avoid and correct mistakes

### Robust
- Content is compatible with assistive technologies
- Works with current and future user agents

## Semantic HTML

### Document Structure
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title - Site Name</title>
</head>
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <header role="banner">
    <nav aria-label="Main navigation">
      <ul>
        <li><a href="/" aria-current="page">Home</a></li>
        <li><a href="/about">About</a></li>
      </ul>
    </nav>
  </header>

  <main id="main-content">
    <h1>Page Title</h1>
    <article>
      <h2>Article Title</h2>
      <p>Content...</p>
    </article>
  </main>

  <aside aria-label="Related content">
    <h2>Related Articles</h2>
  </aside>

  <footer role="contentinfo">
    <p>&copy; 2024 Company Name</p>
  </footer>
</body>
</html>
```

### Skip Link
```css
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  padding: 8px 16px;
  background: #000;
  color: #fff;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
```

### Heading Hierarchy
```html
<!-- Correct: Logical hierarchy -->
<h1>Page Title</h1>
  <h2>Section 1</h2>
    <h3>Subsection 1.1</h3>
    <h3>Subsection 1.2</h3>
  <h2>Section 2</h2>

<!-- Incorrect: Skipping levels -->
<h1>Page Title</h1>
  <h3>Subsection</h3>  <!-- Wrong: skipped h2 -->
```

## ARIA Patterns

### Interactive Components

#### Accessible Button
```tsx
// Bad: div as button
<div onClick={handleClick}>Click me</div>

// Good: native button
<button type="button" onClick={handleClick}>
  Click me
</button>

// Good: custom button with ARIA
<div
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  }}
>
  Click me
</div>
```

#### Accessible Modal
```tsx
function Modal({ isOpen, onClose, title, children }) {
  const dialogRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isOpen) {
      dialogRef.current?.focus();
      document.body.style.overflow = 'hidden';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  // Trap focus
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'Tab') {
        // Focus trap logic
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      ref={dialogRef}
      tabIndex={-1}
    >
      <h2 id="modal-title">{title}</h2>
      {children}
      <button onClick={onClose}>Close</button>
    </div>
  );
}
```

#### Accessible Tabs
```tsx
function Tabs({ tabs, activeTab, onChange }) {
  return (
    <div>
      <div role="tablist" aria-label="Content tabs">
        {tabs.map((tab, index) => (
          <button
            key={tab.id}
            role="tab"
            id={`tab-${tab.id}`}
            aria-selected={activeTab === tab.id}
            aria-controls={`panel-${tab.id}`}
            tabIndex={activeTab === tab.id ? 0 : -1}
            onClick={() => onChange(tab.id)}
            onKeyDown={(e) => {
              if (e.key === 'ArrowRight') {
                const next = tabs[(index + 1) % tabs.length];
                onChange(next.id);
              }
              if (e.key === 'ArrowLeft') {
                const prev = tabs[(index - 1 + tabs.length) % tabs.length];
                onChange(prev.id);
              }
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {tabs.map((tab) => (
        <div
          key={tab.id}
          role="tabpanel"
          id={`panel-${tab.id}`}
          aria-labelledby={`tab-${tab.id}`}
          hidden={activeTab !== tab.id}
          tabIndex={0}
        >
          {tab.content}
        </div>
      ))}
    </div>
  );
}
```

#### Accessible Dropdown
```tsx
function Dropdown({ label, options, value, onChange }) {
  const [isOpen, setIsOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const listRef = useRef<HTMLUListElement>(null);

  return (
    <div>
      <button
        aria-haspopup="listbox"
        aria-expanded={isOpen}
        aria-label={label}
        onClick={() => setIsOpen(!isOpen)}
      >
        {value || 'Select...'}
      </button>

      {isOpen && (
        <ul
          role="listbox"
          aria-label={label}
          aria-activedescendant={`option-${activeIndex}`}
          ref={listRef}
          onKeyDown={(e) => {
            if (e.key === 'ArrowDown') {
              setActiveIndex((i) => Math.min(i + 1, options.length - 1));
            }
            if (e.key === 'ArrowUp') {
              setActiveIndex((i) => Math.max(i - 1, 0));
            }
            if (e.key === 'Enter') {
              onChange(options[activeIndex]);
              setIsOpen(false);
            }
            if (e.key === 'Escape') {
              setIsOpen(false);
            }
          }}
        >
          {options.map((option, index) => (
            <li
              key={option.value}
              id={`option-${index}`}
              role="option"
              aria-selected={option.value === value}
              onClick={() => {
                onChange(option);
                setIsOpen(false);
              }}
            >
              {option.label}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

## Forms

### Accessible Form
```tsx
function ContactForm() {
  const [errors, setErrors] = useState<Record<string, string>>({});

  return (
    <form aria-label="Contact form" noValidate>
      <div>
        <label htmlFor="name">
          Name <span aria-hidden="true">*</span>
          <span className="sr-only">(required)</span>
        </label>
        <input
          type="text"
          id="name"
          name="name"
          required
          aria-required="true"
          aria-invalid={!!errors.name}
          aria-describedby={errors.name ? 'name-error' : undefined}
        />
        {errors.name && (
          <span id="name-error" role="alert" className="error">
            {errors.name}
          </span>
        )}
      </div>

      <div>
        <label htmlFor="email">
          Email <span aria-hidden="true">*</span>
        </label>
        <input
          type="email"
          id="email"
          name="email"
          required
          aria-required="true"
          aria-invalid={!!errors.email}
          aria-describedby="email-hint email-error"
        />
        <span id="email-hint" className="hint">
          We'll never share your email
        </span>
        {errors.email && (
          <span id="email-error" role="alert" className="error">
            {errors.email}
          </span>
        )}
      </div>

      <fieldset>
        <legend>Preferred contact method</legend>
        <div>
          <input type="radio" id="contact-email" name="contact" value="email" />
          <label htmlFor="contact-email">Email</label>
        </div>
        <div>
          <input type="radio" id="contact-phone" name="contact" value="phone" />
          <label htmlFor="contact-phone">Phone</label>
        </div>
      </fieldset>

      <button type="submit">Submit</button>
    </form>
  );
}
```

## Images and Media

### Images
```html
<!-- Informative image -->
<img src="chart.png" alt="Sales increased 50% from Q1 to Q2 2024" />

<!-- Decorative image -->
<img src="decoration.png" alt="" role="presentation" />

<!-- Complex image -->
<figure>
  <img src="diagram.png" alt="System architecture overview" aria-describedby="diagram-desc" />
  <figcaption id="diagram-desc">
    The system consists of three main components: the frontend React application,
    the Node.js API server, and the PostgreSQL database.
  </figcaption>
</figure>
```

### Video
```html
<video controls>
  <source src="video.mp4" type="video/mp4" />
  <track kind="captions" src="captions.vtt" srclang="en" label="English" default />
  <track kind="descriptions" src="descriptions.vtt" srclang="en" label="Audio Descriptions" />
  Your browser does not support the video tag.
</video>
```

## Color and Contrast

### Contrast Requirements
```css
/* WCAG AA Requirements:
   - Normal text: 4.5:1 contrast ratio
   - Large text (18px+ bold or 24px+ regular): 3:1
   - UI components and graphics: 3:1
*/

/* Good contrast */
.text-primary {
  color: #1f2937; /* On white: 14.72:1 ✓ */
}

.text-secondary {
  color: #6b7280; /* On white: 4.63:1 ✓ */
}

/* Don't rely on color alone */
.error {
  color: #dc2626;
  /* Also use icon or text indication */
}

.error::before {
  content: '⚠ ';
}
```

### Focus Indicators
```css
/* Never remove focus outlines without replacement */
:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

/* Custom focus for specific elements */
.button:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.5);
}
```

## Screen Reader Only Content

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

/* Allow focus for skip links */
.sr-only:focus {
  position: static;
  width: auto;
  height: auto;
  overflow: visible;
  clip: auto;
  white-space: normal;
}
```

## Live Regions

```tsx
// For dynamic content updates
function Notification({ message }) {
  return (
    <div
      role="status"
      aria-live="polite"
      aria-atomic="true"
    >
      {message}
    </div>
  );
}

// For important alerts
function Alert({ message }) {
  return (
    <div
      role="alert"
      aria-live="assertive"
    >
      {message}
    </div>
  );
}
```

## Testing

### Automated Testing
```tsx
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('component has no accessibility violations', async () => {
  const { container } = render(<MyComponent />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

### Manual Testing Checklist

- [ ] Keyboard navigation works (Tab, Enter, Escape, Arrows)
- [ ] Focus is visible and logical
- [ ] Screen reader announces content correctly
- [ ] Color contrast meets requirements
- [ ] Works at 200% zoom
- [ ] Works with reduced motion
- [ ] Forms have proper labels and errors
- [ ] Images have appropriate alt text

## Tools

- **axe DevTools**: Browser extension for automated testing
- **WAVE**: Web accessibility evaluation tool
- **Lighthouse**: Built into Chrome DevTools
- **VoiceOver**: macOS screen reader
- **NVDA**: Windows screen reader (free)
- **Contrast Checker**: WebAIM contrast tool

## Remember

- Accessibility benefits everyone
- Use semantic HTML first
- Test with real assistive tech
- ARIA is last resort, not first
- Document a11y requirements
- Include in definition of done
