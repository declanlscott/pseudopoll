<script setup lang="ts">
const route = useRoute()

const { data } = useFetch('/api/polls/nsg7hn0s66s4')

const { signOut, status, session } = useAuth()
</script>

<template>
  <div>
    <h1>Nuxt Routing set up successfully!</h1>
    <p>Current route: {{ route.path }}</p>
    <a href="https://nuxt.com/docs/getting-started/routing" target="_blank">Learn more about Nuxt Routing</a>
    <pre>{{ session?.user.id }}</pre>
    <div>
      <a v-if="status === 'unauthenticated'" href="/api/auth/signin" class="buttonPrimary">Sign in</a>
      <button v-if="status === 'authenticated'" @click="signOut()">
        Sign Out
      </button>
    </div>
    <p>{{ data?.prompt }}</p>
    <ul>
      <li v-for="option in data?.options" :key="option.optionId">
        {{ option.text }}
      </li>
    </ul>
  </div>
</template>
