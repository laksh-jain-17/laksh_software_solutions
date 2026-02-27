<template>
  <div>
    <div class="page-header">
      <div>
        <h2 class="page-title">My Projects</h2>
        <p class="page-subtitle">Track the progress of your projects</p>
      </div>
    </div>

    <LoadingSpinner v-if="loading" text="Loading your projects..." />

    <div v-else-if="!projects.length" class="empty-state">
      <div class="empty-state-icon">📁</div>
      <p class="font-medium text-gray-700">No projects yet</p>
      <p class="text-sm text-gray-400 mt-1 mb-4">Request a service and the admin will create a project for you</p>
      <router-link to="/client/services" class="btn-primary">Request a Service</router-link>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div
        v-for="project in projects"
        :key="project.id"
        class="card card-body hover:shadow-md transition-shadow"
      >
        <div class="flex items-start justify-between mb-3">
          <div class="w-10 h-10 bg-purple-100 rounded-xl flex items-center justify-center text-xl">📁</div>
          <StatusBadge :status="project.status" />
        </div>

        <h3 class="font-semibold text-gray-900 mb-1">{{ project.name }}</h3>
        <p class="text-sm text-gray-500 mb-4 line-clamp-2">{{ project.description || 'No description provided' }}</p>

        <!-- Assigned employees -->
        <div class="mb-4">
          <p class="text-xs font-medium text-gray-500 mb-2">ASSIGNED TEAM</p>
          <div v-if="!project.assignments?.length" class="text-xs text-gray-400 italic">No employees assigned yet</div>
          <div class="flex flex-wrap gap-2">
            <div
              v-for="a in project.assignments"
              :key="a.employee_id"
              class="flex items-center gap-1.5 bg-gray-100 rounded-full px-2 py-1"
            >
              <div class="avatar w-5 h-5 text-xs bg-primary-100 text-primary-700">
                {{ a.employee?.full_name?.[0]?.toUpperCase() || 'U' }}
              </div>
              <span class="text-xs text-gray-700">{{ a.employee?.full_name?.split(' ')[0] }}</span>
            </div>
          </div>
        </div>

        <!-- Progress indicator -->
        <div class="pt-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-400">
          <span>📅 Created {{ formatDate(project.created_at) }}</span>
          <span
            class="font-medium"
            :class="{
              'text-amber-600': project.status === 'Pending',
              'text-blue-600': project.status === 'In Progress',
              'text-emerald-600': project.status === 'Completed',
            }"
          >{{ project.status }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import LoadingSpinner from '@/components/shared/LoadingSpinner.vue'
import StatusBadge from '@/components/shared/StatusBadge.vue'

const authStore = useAuthStore()
const loading = ref(true)
const projects = ref([])

onMounted(async () => {
  const { data } = await supabase
    .from('projects')
    .select(`
      *,
      assignments:project_assignments(
        employee_id,
        employee:profiles!project_assignments_employee_id_fkey(id, full_name)
      )
    `)
    .eq('client_id', authStore.user.id)
    .order('created_at', { ascending: false })

  projects.value = data || []
  loading.value = false
})

function formatDate(ts) {
  return new Date(ts).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>
