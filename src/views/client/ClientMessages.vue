<template>
  <div>
    <div class="page-header mb-4">
      <div>
        <h2 class="page-title">Messages</h2>
        <p class="page-subtitle">Chat with admin and your project team</p>
      </div>
    </div>
    <MessagingPanel :contacts="contacts" :loading-contacts="loading" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import MessagingPanel from '@/components/shared/MessagingPanel.vue'

const authStore = useAuthStore()
const contacts = ref([])
const loading = ref(true)

onMounted(async () => {
  // Client can message: admin + employees assigned to their projects
  const [adminRes, projectsRes] = await Promise.all([
    supabase.from('profiles').select('id, full_name, email, role').eq('role', 'ADMIN'),
    supabase
      .from('projects')
      .select(`
        assignments:project_assignments(
          employee:profiles!project_assignments_employee_id_fkey(id, full_name, email, role)
        )
      `)
      .eq('client_id', authStore.user.id)
  ])

  const admins = adminRes.data || []
  const employeeIds = new Set()
  const employees = []

  projectsRes.data?.forEach(p => {
    p.assignments?.forEach(a => {
      if (a.employee && !employeeIds.has(a.employee.id)) {
        employeeIds.add(a.employee.id)
        employees.push(a.employee)
      }
    })
  })

  contacts.value = [...admins, ...employees]
  loading.value = false
})
</script>
