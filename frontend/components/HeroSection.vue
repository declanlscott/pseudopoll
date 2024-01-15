<script lang="ts" setup>
const { signIn } = useAuth();
</script>

<template>
  <div class="relative">
    <div class="absolute -z-10 h-full w-full">
      <div
        class="relative h-full w-full overflow-hidden rounded-full shadow-[inset_0_0_5rem_3rem] shadow-white dark:shadow-[#121212]"
      >
        <div
          class="moving-grid-background absolute -z-10 h-[200%] w-full"
        ></div>
      </div>
    </div>

    <div class="flex flex-col items-center gap-16 rounded-full py-32">
      <h1
        class="text-center text-5xl font-bold sm:text-6xl md:text-7xl lg:text-8xl"
      >
        <span class="dark:text-primary-50 text-primary-950">
          The Internet's
        </span>
        <br />
        <span class="text-primary-500 dark:text-primary-400">
          Polling Place
        </span>
      </h1>

      <UButton
        size="xl"
        variant="solid"
        color="gray"
        icon="i-lucide-sparkle"
        :ui="{ rounded: 'rounded-full' }"
        class="transition-colors duration-75 dark:hover:bg-black"
        @click="signIn('google')"
      >
        Get Started
      </UButton>
    </div>
  </div>
</template>

<style scoped>
.moving-grid-background {
  will-change: transform;
  background-size: 3rem 3rem;
  background-image: linear-gradient(to right, #8882 1px, transparent 1px),
    linear-gradient(to bottom, #8882 1px, transparent 1px);
  animation: moving-background 60s linear infinite;
}

@keyframes moving-background {
  0% {
    transform: translate(0, 0);
  }
  100% {
    transform: translate(0, -50%);
  }
}
</style>
