<template>
  <div class="flex h-screen bg-gray-50 overflow-hidden">
    <!-- Overlay for mobile -->
    <div
      v-if="sidebarOpen && isMobile"
      @click="sidebarOpen = false"
      class="fixed inset-0 bg-black/50 z-30 lg:hidden"
    ></div>

    <!-- Sidebar -->
    <AppSidebar
      :nav-items="navItems"
      :collapsed="sidebarCollapsed"
      @toggle="sidebarCollapsed = !sidebarCollapsed"
      :class="[
        'transition-transform duration-300 lg:translate-x-0',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
      ]"
    />

    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <AppHeader
        :title="currentPageTitle"
        subtitle="Admin Portal"
        @toggle-sidebar="sidebarOpen = !sidebarOpen"
      />
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
const isMobile = computed(() => window.innerWidth < 1024)

const navItems = [
  { to: '/admin/dashboard', icon: '📊', label: 'Dashboard' },
  { divider: 'Management' },
  { to: '/admin/employees', icon: '👥', label: 'Employees' },
  { to: '/admin/clients', icon: '🏢', label: 'Clients' },
  { to: '/admin/projects', icon: '📁', label: 'Projects' },
  { to: '/admin/services', icon: '⚙️', label: 'Services' },
  { to: '/admin/requests', icon: '📋', label: 'Service Requests' },
  { divider: 'Communication' },
  { to: '/admin/messages', icon: '💬', label: 'Messages' },
  { divider: 'Settings' },
  { to: '/admin/users', icon: '🔑', label: 'Manage Users' },
  { to: '/admin/profile', icon: '👤', label: 'My Profile' },
]

const pageTitles = {
  '/admin/dashboard': 'Dashboard',
  '/admin/employees': 'Employees',
  '/admin/clients': 'Client Companies',
  '/admin/projects': 'Projects',
  '/admin/services': 'Services',
  '/admin/requests': 'Service Requests',
  '/admin/messages': 'Messages',
  '/admin/users': 'User Management',
  '/admin/profile': 'My Profile',
}

const currentPageTitle = computed(() => pageTitles[route.path] || 'Admin Portal')
</script>
