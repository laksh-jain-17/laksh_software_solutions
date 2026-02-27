<template>
  <span class="badge" :class="badgeClass">{{ status }}</span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({ status: String })

const badgeClass = computed(() => {
  const map = {
    'Pending': 'badge-yellow',
    'In Progress': 'badge-blue',
    'Completed': 'badge-green',
    'On Hold': 'badge-gray',
    'Cancelled': 'badge-red',
    'Approved': 'badge-green',
    'Rejected': 'badge-red',
  }
  return map[props.status] || 'badge-gray'
})
</script>
