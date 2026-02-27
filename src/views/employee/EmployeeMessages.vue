<template>
  <div>
    <div class="page-header mb-4">
      <div>
        <h2 class="page-title">Messages</h2>
        <p class="page-subtitle">Chat with admin and your clients</p>
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
  // Employee can message: admin + clients of assigned projects
  const [adminRes, projectsRes] = await Promise.all([
    supabase.from('profiles').select('id, full_name, email, role').eq('role', 'ADMIN'),
    supabase
      .from('project_assignments')
      .select('project:projects(client_id, client:profiles!projects_client_id_fkey(id, full_name, email, role))')
      .eq('employee_id', authStore.user.id)
  ])

  const admins = adminRes.data || []
  const clientIds = new Set()
  const clients = []

  projectsRes.data?.forEach(a => {
    const client = a.project?.client
    if (client && !clientIds.has(client.id)) {
      clientIds.add(client.id)
      clients.push(client)
    }
  })

  contacts.value = [...admins, ...clients]
  loading.value = false
})
</script>
