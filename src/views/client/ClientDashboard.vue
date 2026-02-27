<template>
  <div>
    <!-- Welcome banner -->
    <div class="bg-gradient-to-r from-purple-600 to-purple-700 rounded-2xl p-6 mb-6 text-white">
      <p class="text-purple-200 text-sm mb-1">Welcome back,</p>
      <h2 class="text-2xl font-bold mb-1">{{ authStore.profile?.full_name }} 👋</h2>
      <p class="text-purple-200 text-sm">Track your projects and stay connected with your team</p>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
      <div class="stat-card">
        <div class="stat-icon bg-blue-100">📁</div>
        <div>
          <p class="text-2xl font-bold">{{ stats.total }}</p>
          <p class="text-sm text-gray-500">Total Projects</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon bg-amber-100">⏳</div>
        <div>
          <p class="text-2xl font-bold">{{ stats.active }}</p>
          <p class="text-sm text-gray-500">Active</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon bg-emerald-100">✅</div>
        <div>
          <p class="text-2xl font-bold">{{ stats.completed }}</p>
          <p class="text-sm text-gray-500">Completed</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon bg-orange-100">📋</div>
        <div>
          <p class="text-2xl font-bold">{{ stats.pendingRequests }}</p>
          <p class="text-sm text-gray-500">Pending Requests</p>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
      <!-- My Projects -->
      <div class="card">
        <div class="card-header">
          <h3 class="font-semibold text-gray-900">My Projects</h3>
          <router-link to="/client/projects" class="text-sm text-primary-600 font-medium">View all →</router-link>
        </div>
        <LoadingSpinner v-if="loading" size="sm" />
        <div v-else-if="!projects.length" class="p-8 text-center">
          <p class="text-gray-400 text-sm">No projects yet. Request a service to get started!</p>
          <router-link to="/client/services" class="btn-primary btn-sm mt-3 inline-flex">Request Service</router-link>
        </div>
        <div v-else class="divide-y divide-gray-50">
          <div v-for="project in projects.slice(0,4)" :key="project.id" class="p-4 flex items-center justify-between hover:bg-gray-50">
            <div>
              <p class="font-medium text-gray-900 text-sm">{{ project.name }}</p>
              <p class="text-xs text-gray-400 mt-0.5">{{ formatDate(project.created_at) }}</p>
            </div>
            <StatusBadge :status="project.status" />
          </div>
        </div>
      </div>

      <!-- Recent requests -->
      <div class="card">
        <div class="card-header">
          <h3 class="font-semibold text-gray-900">Service Requests</h3>
          <router-link to="/client/services" class="text-sm text-primary-600 font-medium">New request →</router-link>
        </div>
        <LoadingSpinner v-if="loading" size="sm" />
        <div v-else-if="!requests.length" class="p-8 text-center">
          <p class="text-gray-400 text-sm">No service requests yet</p>
        </div>
        <div v-else class="divide-y divide-gray-50">
          <div v-for="req in requests.slice(0,4)" :key="req.id" class="p-4 flex items-center justify-between hover:bg-gray-50">
            <div>
              <p class="font-medium text-gray-900 text-sm">{{ req.service?.name }}</p>
              <p class="text-xs text-gray-400 mt-0.5">{{ formatDate(req.created_at) }}</p>
            </div>
            <StatusBadge :status="req.status" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'
import StatusBadge from '@/components/shared/StatusBadge.vue'

const authStore = useAuthStore()
const loading = ref(true)
const projects = ref([])
const requests = ref([])

const stats = computed(() => ({
  total: projects.value.length,
  active: projects.value.filter(p => p.status !== 'Completed' && p.status !== 'Cancelled').length,
  completed: projects.value.filter(p => p.status === 'Completed').length,
  pendingRequests: requests.value.filter(r => r.status === 'Pending').length,
}))

onMounted(async () => {
  const [projRes, reqRes] = await Promise.all([
    supabase.from('projects').select('*').eq('client_id', authStore.user.id).order('created_at', { ascending: false }),
    supabase.from('service_requests').select('*, service:services(name)').eq('client_id', authStore.user.id).order('created_at', { ascending: false }),
  ])
  projects.value = projRes.data || []
  requests.value = reqRes.data || []
  loading.value = false
})

function formatDate(ts) {
  return new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>
