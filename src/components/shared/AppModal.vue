<template>
  <teleport to="body">
    <transition name="modal">
      <div v-if="show" class="modal-overlay" @click.self="$emit('close')">
        <div class="modal-content" :class="maxWidthClass">
          <!-- Header -->
          <div class="card-header">
            <div>
              <h3 class="text-base font-semibold text-gray-900">{{ title }}</h3>
              <p v-if="subtitle" class="text-xs text-gray-500 mt-0.5">{{ subtitle }}</p>
            </div>
            <button @click="$emit('close')" class="text-gray-400 hover:text-gray-600 transition-colors p-1 hover:bg-gray-100 rounded-lg">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <!-- Body -->
          <div class="card-body">
            <slot />
          </div>
          <!-- Footer -->
          <div v-if="$slots.footer" class="px-6 pb-6 flex items-center justify-end gap-3 -mt-2">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  show: Boolean,
  title: String,
  subtitle: String,
  size: { type: String, default: 'md' }
})

defineEmits(['close'])

const maxWidthClass = computed(() => ({
  sm: 'max-w-sm',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
  xl: 'max-w-4xl',
}[props.size] || 'max-w-lg'))
</script>
