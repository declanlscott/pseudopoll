<script setup lang="ts">
const { signOut, status, session } = useAuth();
</script>

<template>
  <div>
    <pre>{{ session }}</pre>
    <div>
      <a
        v-if="status === 'unauthenticated'"
        href="/api/auth/signin"
        class="buttonPrimary"
        >Sign in</a
      >
      <button v-if="status === 'authenticated'" @click="signOut()">
        Sign Out
      </button>
    </div>
  </div>
</template>
