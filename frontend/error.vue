<script setup lang="ts">
const props = defineProps({
  // eslint-disable-next-line vue/require-default-prop
  error: Object,
});

const statusCode = computed(() => {
  return props.error?.statusCode ?? 500;
});

const { status, signIn } = useAuth();
</script>

<template>
  <NuxtLayout>
    <div class="flex flex-col items-center gap-6">
      <h1 class="text-9xl font-bold">{{ statusCode }}</h1>

      <UAlert
        v-if="statusCode === 401"
        :actions="[
          {
            variant: 'solid',
            color: 'primary',
            label: 'Login',
            trailingIcon: 'i-lucide-log-in',
            click: async () => {
              await clearError();
              await signIn('google');
            },
          },
        ]"
        :title="`${
          status === 'authenticated' ? 'Session expired' : 'Not signed in'
        }`"
        :description="`${
          status === 'authenticated'
            ? 'Your session has expired. Please login again to continue.'
            : 'You must be signed in to view this page.'
        }`"
        :ui="{
          actions: 'justify-end',
        }"
      ></UAlert>

      <UAlert
        v-else-if="statusCode === 403"
        title="Access denied"
        description="You do not have permission to view this page."
      ></UAlert>

      <UAlert
        v-else-if="statusCode === 404"
        title="Page not found"
        description="The page you were looking for could not be found."
      ></UAlert>

      <UAlert
        v-else
        title="Something went wrong"
        description="An error occurred while trying to load this page. Please try again later."
      ></UAlert>
    </div>
  </NuxtLayout>
</template>
