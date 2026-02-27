<template>
  <header class="bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between sticky top-0 z-30">
    <!-- Left: mobile menu + page title -->
    <div class="flex items-center gap-4">
      <button
        @click="$emit('toggle-sidebar')"
        class="lg:hidden p-2 rounded-lg text-gray-500 hover:bg-gray-100 transition-colors"
      >
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>
      <div>
        <h1 class="text-lg font-semibold text-gray-900">{{ title }}</h1>
        <p v-if="subtitle" class="text-xs text-gray-400">{{ subtitle }}</p>
      </div>
    </div>

    <!-- Right: actions -->
    <div class="flex items-center gap-3">
      <!-- Role badge -->
      <span
        class="badge text-xs hidden sm:inline-flex"
        :class="{
          'badge-blue': role === 'ADMIN',
          'badge-green': role === 'EMPLOYEE',
          'badge-purple': role === 'CLIENT'
        }"
      >
        {{ role }}
      </span>

      <!-- Profile link -->
      <router-link :to="profileLink" class="flex items-center gap-2 p-1.5 rounded-lg hover:bg-gray-100 transition-colors">
        <div class="avatar w-8 h-8 text-sm">{{ initials }}</div>
      </router-link>
    </div>
  </header>
</template>

<script setup>
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

defineProps({ title: String, subtitle: String })
defineEmits(['toggle-sidebar'])

const authStore = useAuthStore()
const role = computed(() => authStore.role)

const initials = computed(() => {
  const name = authStore.profile?.full_name || ''
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) || 'U'
})

const profileLink = computed(() => {
  const map = { ADMIN: '/admin/profile', EMPLOYEE: '/employee/profile', CLIENT: '/client/profile' }
  return map[role.value] || '/login'
})
</script>
