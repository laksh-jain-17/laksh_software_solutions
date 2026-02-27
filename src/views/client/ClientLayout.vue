<template>
  <div class="flex h-screen bg-gray-50 overflow-hidden">
    <div v-if="sidebarOpen" @click="sidebarOpen = false" class="fixed inset-0 bg-black/50 z-30 lg:hidden"></div>

    <AppSidebar
      :nav-items="navItems"
      :collapsed="sidebarCollapsed"
      @toggle="sidebarCollapsed = !sidebarCollapsed"
      :class="['transition-transform duration-300 lg:translate-x-0', sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0']"
    />

    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <AppHeader :title="currentPageTitle" subtitle="Client Portal" @toggle-sidebar="sidebarOpen = !sidebarOpen" />
      <main class="flex-1 overflow-y-auto p-6">
        <transition name="fade" mode="out-in">
          <router-view :key="$route.path" />
        </transition>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import AppSidebar from '@/components/shared/AppSidebar.vue'
import AppHeader from '@/components/shared/AppHeader.vue'

const route = useRoute()
const sidebarCollapsed = ref(false)
const sidebarOpen = ref(false)

const navItems = [
  { to: '/client/dashboard', icon: '📊', label: 'Dashboard' },
  { divider: 'My Work' },
  { to: '/client/projects', icon: '📁', label: 'My Projects' },
  { to: '/client/services', icon: '⚙️', label: 'Request Service' },
  { divider: 'Communication' },
  { to: '/client/messages', icon: '💬', label: 'Messages' },
  { divider: 'Account' },
  { to: '/client/profile', icon: '👤', label: 'My Profile' },
]

const pageTitles = {
  '/client/dashboard': 'Dashboard',
  '/client/projects': 'My Projects',
  '/client/services': 'Request Service',
  '/client/messages': 'Messages',
  '/client/profile': 'My Profile',
}

const currentPageTitle = computed(() => pageTitles[route.path] || 'Client Portal')
</script>
