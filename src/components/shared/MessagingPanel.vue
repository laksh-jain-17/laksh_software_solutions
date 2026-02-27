<template>
  <div class="flex h-[calc(100vh-140px)] gap-4">
    <!-- Contacts list -->
    <div class="w-72 flex-shrink-0 card flex flex-col">
      <div class="card-header">
        <h3 class="font-semibold text-gray-900">Messages</h3>
      </div>
      <div class="p-3">
        <input
          v-model="search"
          type="text"
          class="form-input"
          placeholder="Search contacts..."
        />
      </div>
      <div class="flex-1 overflow-y-auto divide-y divide-gray-50">
        <LoadingSpinner v-if="loadingContacts" size="sm" text="Loading..." />
        <div v-else-if="!filteredContacts.length" class="p-6 text-center">
          <p class="text-gray-400 text-sm">No contacts found</p>
        </div>
        <button
          v-for="contact in filteredContacts"
          :key="contact.id"
          @click="selectContact(contact)"
          class="w-full flex items-center gap-3 p-4 hover:bg-gray-50 transition-colors text-left"
          :class="selectedContact?.id === contact.id ? 'bg-primary-50 border-l-2 border-primary-500' : ''"
        >
          <div class="avatar w-10 h-10 flex-shrink-0">
            {{ contact.full_name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0,2) || 'U' }}
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-gray-900 truncate">{{ contact.full_name }}</p>
            <p class="text-xs text-gray-400 capitalize">{{ contact.role?.toLowerCase() }}</p>
          </div>
        </button>
      </div>
    </div>

    <!-- Chat area -->
    <div class="flex-1 card flex flex-col overflow-hidden">
      <!-- No contact selected -->
      <div v-if="!selectedContact" class="flex-1 flex items-center justify-center">
        <div class="text-center">
          <div class="text-6xl mb-3">💬</div>
          <p class="text-gray-500 font-medium">Select a contact to start messaging</p>
          <p class="text-gray-400 text-sm mt-1">Choose from the list on the left</p>
        </div>
      </div>

      <template v-else>
        <!-- Chat header -->
        <div class="card-header flex-shrink-0">
          <div class="flex items-center gap-3">
            <div class="avatar w-9 h-9">
              {{ selectedContact.full_name?.split(' ').map(n => n[0]).join('').toUpperCase().slice(0,2) || 'U' }}
            </div>
            <div>
              <p class="font-semibold text-gray-900">{{ selectedContact.full_name }}</p>
              <p class="text-xs text-gray-400 capitalize">{{ selectedContact.role?.toLowerCase() }}</p>
            </div>
          </div>
          <button @click="loadMessages" class="text-gray-400 hover:text-gray-600 p-1.5 hover:bg-gray-100 rounded-lg" title="Refresh">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>
        </div>

        <!-- Messages -->
        <div class="flex-1 overflow-y-auto p-4 space-y-4" ref="messagesContainer">
          <LoadingSpinner v-if="loadingMessages" size="sm" />
          <div v-else-if="!messages.length" class="flex items-center justify-center h-full">
            <div class="text-center">
              <div class="text-4xl mb-2">👋</div>
              <p class="text-gray-500 text-sm">Start the conversation!</p>
            </div>
          </div>
          <div
            v-for="msg in messages"
            :key="msg.id"
            class="flex"
            :class="msg.sender_id === currentUserId ? 'justify-end' : 'justify-start'"
          >
            <div class="max-w-xs lg:max-w-sm">
              <div
                :class="msg.sender_id === currentUserId ? 'message-sent' : 'message-received'"
              >
                {{ msg.content }}
              </div>
              <p class="text-xs text-gray-400 mt-1" :class="msg.sender_id === currentUserId ? 'text-right' : ''">
                {{ formatTime(msg.created_at) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Input -->
        <div class="p-4 border-t border-gray-100 flex-shrink-0">
          <form @submit.prevent="sendMessage" class="flex gap-3">
            <input
              v-model="newMessage"
              type="text"
              class="form-input flex-1"
              placeholder="Type a message..."
              :disabled="sending"
              @keydown.enter.prevent="sendMessage"
            />
            <button
              type="submit"
              class="btn-primary flex-shrink-0"
              :disabled="!newMessage.trim() || sending"
            >
              <span v-if="sending" class="spinner w-4 h-4"></span>
              <svg v-else class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
              </svg>
              <span v-if="!sending">Send</span>
            </button>
          </form>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useToast } from 'vue-toastification'
import LoadingSpinner from './LoadingSpinner.vue'

const props = defineProps({
  contacts: { type: Array, default: () => [] },
  loadingContacts: Boolean
})

const authStore = useAuthStore()
const toast = useToast()

const search = ref('')
const selectedContact = ref(null)
const messages = ref([])
const newMessage = ref('')
const loadingMessages = ref(false)
const sending = ref(false)
const messagesContainer = ref(null)

const currentUserId = computed(() => authStore.user?.id)

const filteredContacts = computed(() => {
  if (!search.value) return props.contacts
  return props.contacts.filter(c =>
    c.full_name?.toLowerCase().includes(search.value.toLowerCase())
  )
})

async function selectContact(contact) {
  selectedContact.value = contact
  await loadMessages()
}

async function loadMessages() {
  if (!selectedContact.value) return
  loadingMessages.value = true
  try {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .or(
        `and(sender_id.eq.${currentUserId.value},receiver_id.eq.${selectedContact.value.id}),and(sender_id.eq.${selectedContact.value.id},receiver_id.eq.${currentUserId.value})`
      )
      .order('created_at', { ascending: true })

    if (error) throw error
    messages.value = data || []
    await nextTick()
    scrollToBottom()
  } catch (err) {
    toast.error('Failed to load messages')
  } finally {
    loadingMessages.value = false
  }
}

async function sendMessage() {
  if (!newMessage.value.trim() || !selectedContact.value) return
  sending.value = true
  try {
    const { error } = await supabase.from('messages').insert({
      sender_id: currentUserId.value,
      receiver_id: selectedContact.value.id,
      content: newMessage.value.trim(),
    })
    if (error) throw error
    newMessage.value = ''
    await loadMessages()
  } catch (err) {
    toast.error('Failed to send message')
  } finally {
    sending.value = false
  }
}

function scrollToBottom() {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

function formatTime(ts) {
  return new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}
</script>
