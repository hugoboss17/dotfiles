# TypeScript & Vue 3 Patterns

## tsconfig.json (strict)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true,
    "jsx": "preserve",
    "lib": ["ES2022", "DOM"]
  }
}
```

---

## Vue 3 Component Pattern

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import type { User } from '@/types/user'

interface Props {
  user: User
  readonly?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  readonly: false,
})

const emit = defineEmits<{
  update: [user: User]
  delete: [id: number]
}>()

const isEditing = ref(false)

const displayName = computed(() =>
  `${props.user.firstName} ${props.user.lastName}`
)

function handleSave(updated: User) {
  emit('update', updated)
  isEditing.value = false
}
</script>
```

---

## Composable Pattern (useX.ts)

```typescript
// composables/useUsers.ts
import { ref, readonly } from 'vue'
import type { User } from '@/types/user'

export function useUsers() {
  const users = ref<User[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchUsers(): Promise<void> {
    loading.value = true
    error.value = null
    try {
      const response = await api.get<{ data: User[] }>('/users')
      users.value = response.data.data
    } catch (e) {
      error.value = 'Failed to load users'
    } finally {
      loading.value = false
    }
  }

  return {
    users: readonly(users),
    loading: readonly(loading),
    error: readonly(error),
    fetchUsers,
  }
}
```

---

## API Client Pattern

```typescript
// lib/api.ts
import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: { Accept: 'application/json' },
  withCredentials: true,
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
```

---

## Common Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `any` type | Use proper type, generic, or `unknown` |
| `// @ts-ignore` | Fix the type error |
| Options API in new components | Use `<script setup>` with Composition API |
| Inline styles for dynamic values | Use CSS custom properties or computed classes |
| `v-if` + `v-for` on same element | Add wrapper `<template>` |
| Direct mutation of props | Emit events to parent, never mutate props |
| Composable with no return type | Always annotate composable return type |
