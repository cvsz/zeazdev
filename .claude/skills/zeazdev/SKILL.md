```markdown
# zeazdev Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill teaches the core development patterns and conventions used in the `zeazdev` TypeScript repository. It covers file organization, import/export styles, commit message habits, and testing patterns. By following these guidelines, contributors can maintain consistency and readability across the codebase.

## Coding Conventions

### File Naming
- Use **kebab-case** for all file names.
  - **Example:**  
    `user-service.ts`  
    `api-client.test.ts`

### Import Style
- Use **relative imports** for referencing modules within the project.
  - **Example:**
    ```typescript
    import { fetchData } from './utils/fetch-data';
    ```

### Export Style
- Use **named exports** for all modules.
  - **Example:**
    ```typescript
    // In utils/math.ts
    export function add(a: number, b: number): number {
      return a + b;
    }

    // In another file
    import { add } from './utils/math';
    ```

### Commit Messages
- Commit messages are **freeform** and do not follow a strict prefix.
- Average commit message length is about 63 characters.

## Workflows

_No automated workflows detected in this repository._

## Testing Patterns

- **Test Framework:** Not explicitly detected; framework is unknown.
- **Test File Naming:** Test files follow the `*.test.*` pattern.
  - **Example:**  
    `user-service.test.ts`
- **Test Location:** Tests are typically placed alongside the files they test or in a dedicated test directory.

### Example Test File
```typescript
// user-service.test.ts
import { getUser } from './user-service';

describe('getUser', () => {
  it('returns user data for a valid ID', () => {
    // test implementation
  });
});
```

## Commands
| Command | Purpose |
|---------|---------|
| /conventions | Show coding conventions for zeazdev |
| /testing    | Show testing patterns and examples    |
```
