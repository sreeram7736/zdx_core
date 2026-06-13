import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

// Mock GetParentResourceName for development
if (!window.GetParentResourceName) {
  window.GetParentResourceName = () => 'nexus-multicharacter'
}

createApp(App).mount('#app')