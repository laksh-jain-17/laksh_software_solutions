<template>
  <aside
    class="flex flex-col bg-white border-r border-gray-100 transition-all duration-300 z-40"
    :class="[collapsed ? 'w-16' : 'w-64', 'fixed inset-y-0 left-0 lg:relative lg:inset-auto']"
  >
    <!-- Logo -->
    <div class="flex items-center gap-3 px-4 py-5 border-b border-gray-100" :class="collapsed ? 'justify-center' : ''">
      <div class="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center flex-shrink-0">
        <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
        </svg>
      </div>
      <span v-if="!collapsed" class="font-bold text-sm text-gray-900 leading-tight">
        Laksh Software<br/>
        <span class="text-primary-600 font-semibold">Solutions</span>
      </span>
    </div>

    <!-- Navigation -->
    <nav class="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
      <div v-for="item in navItems" :key="item.to">
        <!-- Section header -->
        <div v-if="item.divider && !collapsed" class="px-3 pt-4 pb-1">
          <p class="text-xs font-semibold text-gray-400 uppercase tracking-wider">{{ item.divider }}</p>
        </div>
        <router-link
          v-else
          :to="item.to"
          class="sidebar-link group relative"
          :class="{ 'active': isActive(item.to), 'justify-center': collapsed }"
          :title="collapsed ? item.label : ''"
        >
          <span class="flex-shrink-0 text-lg" :class="isActive(item.to) ? 'opacity-100' : 'opacity-60 group-hover:opacity-80'">
            {{ item.icon }}
          </span>
          <span v-if="!collapsed" class="flex-1">{{ item.label }}</span>
          <!-- Badge -->
          <span v-if="item.badge && !collapsed" class="ml-auto badge badge-red text-xs px-1.5 py-0.5">{{ item.badge }}</span>

          <!-- Tooltip on collapse -->
          <div v-if="collapsed" class="absolute left-full ml-2 px-2 py-1 bg-gray-900 text-white text-xs rounded-md opacity-0 group-hover:opacity-100 whitespace-nowrap pointer-events-none transition-opacity z-50">
            {{ item.label }}
          </div>
        </router-link>
      </div>
    </nav>

    <!-- User info at bottom -->
    <div class="border-t border-gray-100 p-3">
      <div class="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-50 transition-colors" :class="collapsed ? 'justify-center' : ''">
        <div class="avatar w-8 h-8 text-sm flex-shrink-0">
          {{ initials }}
        </div>
        <div v-if="!collapsed" class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 truncate">{{ profile?.full_name || 'User' }}</p>
          <p class="text-xs text-gray-400 capitalize">{{ profile?.role?.toLowerCase() }}</p>
        </div>
        <button v-if="!collapsed" @click="logout" class="text-gray-400 hover:text-red-500 transition-colors flex-shrink-0" title="Sign out">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Collapse toggle -->
    <button
      @click="$emit('toggle')"
      class="hidden lg:flex absolute -right-3 top-20 w-6 h-6 bg-white border border-gray-200 rounded-full items-center justify-center shadow-sm hover:bg-gray-50 transition-colors z-10"
    >
      <svg
        class="w-3 h-3 text-gray-500 transition-transform duration-300"
        :class="collapsed ? 'rotate-180' : ''"
        fill="none" viewBox="0 0 24 24" stroke="currentColor"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
      </svg>
    </button>
  </aside>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'

const props = defineProps({
  navItems: Array,
  collapsed: { type: Boolean, default: false }
})

defineEmits(['toggle'])

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const toast = useToast()

const profile = computed(() => authStore.profile)
const initials = computed(() => {
  const name = profile.value?.full_name || ''
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) || 'U'
})

function isActive(path) {
  return route.path.startsWith(path)
}

async function logout() {
  await authStore.logout()
  toast.success('Signed out successfully')
  router.push('/login')
}
</script>
