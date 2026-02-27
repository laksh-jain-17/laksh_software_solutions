<template>
  <div>
    <!-- Welcome -->
    <div class="bg-gradient-to-r from-primary-600 to-primary-700 rounded-2xl p-6 mb-6 text-white">
      <p class="text-primary-200 text-sm mb-1">Welcome back,</p>
      <h2 class="text-2xl font-bold mb-1">{{ authStore.profile?.full_name }} 👋</h2>
      <p class="text-primary-200 text-sm">You have {{ activeProjects }} active project{{ activeProjects !== 1 ? 's' : '' }} to work on</p>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-3 gap-4 mb-6">
      <div class="stat-card">
        <div class="stat-icon bg-blue-100">📁</div>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ stats.total }}</p>
          <p class="text-sm text-gray-500">Total Projects</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon bg-amber-100">⏳</div>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ stats.inProgress }}</p>
          <p class="text-sm text-gray-500">In Progress</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon bg-emerald-100">✅</div>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ stats.completed }}</p>
          <p class="text-sm text-gray-500">Completed</p>
        </div>
      </div>
    </div>

    <!-- Projects -->
    <div class="card">
      <div class="card-header">
        <h3 class="font-semibold text-gray-900">My Assigned Projects</h3>
        <router-link to="/employee/projects" class="text-sm text-primary-600 hover:text-primary-700 font-medium">View all</router-link>
      </div>
      <LoadingSpinner v-if="loading" text="Loading projects..." />
      <div v-else-if="!projects.length" class="empty-state">
        <div class="empty-state-icon">📁</div>
        <p class="text-gray-500 font-medium">No projects assigned yet</p>
        <p class="text-sm text-gray-400 mt-1">The admin will assign you to projects</p>
      </div>
      <div v-else class="divide-y divide-gray-50">
        <div v-for="project in projects.slice(0,5)" :key="project.id" class="p-4 hover:bg-gray-50 transition-colors">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="font-medium text-gray-900">{{ project.name }}</p>
              <p class="text-xs text-gray-400 mt-0.5">Client: {{ project.client?.full_name }}</p>
            </div>
            <StatusBadge :status="project.status" />
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

const activeProjects = computed(() => projects.value.filter(p => p.status === 'In Progress').length)
const stats = computed(() => ({
  total: projects.value.length,
  inProgress: projects.value.filter(p => p.status === 'In Progress').length,
  completed: projects.value.filter(p => p.status === 'Completed').length,
}))

onMounted(async () => {
  const { data } = await supabase
    .from('project_assignments')
    .select(`
      project:projects(
        id, name, description, status, created_at,
        client:profiles!projects_client_id_fkey(full_name)
      )
    `)
    .eq('employee_id', authStore.user.id)

  projects.value = data?.map(d => d.project).filter(Boolean) || []
  loading.value = false
})
</script>
