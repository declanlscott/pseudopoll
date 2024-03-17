<script lang="ts" setup>
const { status, session, signOut, signIn } = useAuth();

const router = useRouter();
const isLandingPage = computed(
  () =>
    router.currentRoute.value.path === "/" && status.value !== "authenticated",
);
</script>

<template>
  <UContainer class="flex min-h-screen flex-col">
    <header class="flex w-full items-center justify-between pb-6 pt-3 sm:pb-12">
      <NuxtLink to="/" class="text-2xl">
        <span class="dark:text-primary-50/75 text-primary-950/75 font-light"
          >Pseudo</span
        >
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
                icon="i-lucide-log-out"
                class="w-fit self-center"
                @click="signOut()"
              >
                Logout
              </UButton>
            </div>
          </template>
        </UPopover>
      </div>

      <UButton
        v-if="status !== 'authenticated'"
        variant="ghost"
        color="gray"
        icon="i-lucide-log-in"
        :loading="status === 'loading'"
        @click="signIn('google')"
      >
        Login
      </UButton>
    </header>

    <main
      :class="
        cn(
          'mx-auto mb-32 w-full max-w-xl flex-grow gap-12 md:max-w-2xl lg:max-w-3xl',
          isLandingPage && 'max-w-full md:max-w-full lg:max-w-full',
        )
      "
    >
      <slot></slot>
    </main>

    <footer class="flex w-full items-center justify-between pb-3 pt-6 sm:pt-12">
      <div class="flex items-center justify-center gap-3">
        <UIcon
          name="i-lucide-code-2"
          class="dark:text-primary-50/75 text-primary-950/75 h-6 w-6"
        ></UIcon>

        <p class="dark:text-primary-50/75 text-primary-950/75 text-sm">
          Developed by
          <NuxtLink
            class="font-bold hover:underline"
            href="https://declanlscott.com"
            target="_blank"
            >Declan L. Scott</NuxtLink
          >
        </p>
      </div>

      <UButton
        to="https://github.com/declanlscott/pseudopoll"
        target="_blank"
        square
        variant="ghost"
        color="gray"
        icon="i-lucide-github"
        size="lg"
        class="dark:text-primary-50/75 text-primary-950/75"
      ></UButton>
    </footer>
  </UContainer>
</template>
