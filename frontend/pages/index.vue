<script setup lang="ts">
const route = useRoute()

const { data } = useFetch('/api/polls/nsg7hn0s66s4')
</script>

<template>
  <div>
    <h1>Nuxt Routing set up successfully!</h1>
    <p>Current route: {{ route.path }}</p>
    <a href="https://nuxt.com/docs/getting-started/routing" target="_blank">Learn more about Nuxt Routing</a>
    <p>{{ data?.prompt }}</p>
    <ul>
      <li v-for="option in data?.options" :key="option.optionId">
        {{ option.text }}
      </li>
    </ul>
  </div>
</template>
