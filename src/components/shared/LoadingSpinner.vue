<template>
  <div class="flex items-center justify-center" :class="fullPage ? 'min-h-screen' : 'py-12'">
    <div class="flex flex-col items-center gap-3">
      <div class="spinner" :class="sizeClass"></div>
      <p v-if="text" class="text-sm text-gray-500">{{ text }}</p>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  size: { type: String, default: 'md' },
  text: String,
  fullPage: Boolean
})

const sizeClass = computed(() => ({
  sm: 'w-5 h-5',
  md: 'w-8 h-8',
  lg: 'w-12 h-12',
}[props.size]))
</script>
