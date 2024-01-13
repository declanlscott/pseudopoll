<script lang="ts" setup>
const { status, session, signOut, signIn } = useAuth();
</script>

<template>
  <UContainer class="mb-32">
    <div class="flex w-full items-center justify-between pb-6 pt-3 sm:pb-12">
      <NuxtLink to="/" class="text-2xl">
        <span class="font-light text-gray-400">Pseudo</span>
        <span class="dark:text-primary-400 text-primary-500 font-bold"
          >Poll</span
        >
      </NuxtLink>

      <div v-if="status === 'authenticated'">
        <UPopover overlay class="h-8 w-8">
          <UAvatar
            :src="session?.user.image ?? undefined"
            :alt="session?.user.name ?? undefined"
          ></UAvatar>

          <template #panel>
            <div class="flex w-72 flex-col gap-3 p-3">
              <span class="text-center text-sm text-gray-500">
                {{ session?.user.email }}
              </span>

              <div class="flex w-full justify-center">
                <UAvatar
                  :src="session?.user.image ?? undefined"
                  :alt="session?.user.name ?? undefined"
                  size="3xl"
                ></UAvatar>
              </div>

              <span class="text-center text-2xl font-semibold">
                {{ session?.user.name }}
              </span>

              <UButton
                color="gray"
                icon="i-heroicons-arrow-left"
                class="w-fit self-center"
                @click="signOut()"
              >
                Sign out
              </UButton>
            </div>
          </template>
        </UPopover>
      </div>

      <UButton
        v-if="status !== 'authenticated'"
        icon="i-heroicons-arrow-right"
        trailing
        :loading="status === 'loading'"
        @click="signIn('google')"
      >
        Sign in
      </UButton>
    </div>

    <main class="mx-auto max-w-xl gap-12 md:max-w-2xl lg:max-w-3xl">
      <slot></slot>
    </main>
  </UContainer>
</template>
