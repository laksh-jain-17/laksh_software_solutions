<template>
  <div>
    <div class="page-header mb-4">
      <div>
        <h2 class="page-title">Messages</h2>
        <p class="page-subtitle">Communicate with employees and clients</p>
      </div>
    </div>
    <MessagingPanel :contacts="contacts" :loading-contacts="loading" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import MessagingPanel from '@/components/shared/MessagingPanel.vue'

const contacts = ref([])
const loading = ref(true)

onMounted(async () => {
  const { data } = await supabase
    .from('profiles')
    .select('id, full_name, email, role')
    .in('role', ['EMPLOYEE', 'CLIENT'])
    .order('full_name')
  contacts.value = data || []
  loading.value = false
})
</script>
