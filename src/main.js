import { createApp } from 'vue'
import { createPinia } from 'pinia'
import Toast, { POSITION } from 'vue-toastification'
import 'vue-toastification/dist/index.css'

import App from './App.vue'
import router from './router'
import './assets/main.css'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.use(Toast, {
  position: POSITION.TOP_RIGHT,
  timeout: 3500,
  closeOnClick: true,
  pauseOnFocusLoss: true,
  pauseOnHover: true,
  draggable: true,
  draggablePercent: 0.6,
  showCloseButtonOnHover: false,
  hideProgressBar: false,
  closeButton: 'button',
  icon: true,
  rtl: false,
  transition: 'Vue-Toastification__fade',
  maxToasts: 5,
  newestOnTop: true,
  toastClassName: 'rounded-lg shadow-lg font-medium text-sm',
})

// Initialize auth before mounting
import { useAuthStore } from './stores/auth'

const authStore = useAuthStore()
authStore.initialize().then(() => {
  app.mount('#app')
})
