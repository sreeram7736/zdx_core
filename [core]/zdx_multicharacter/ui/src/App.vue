<template>
  <div id="app" v-show="visible" class="antialiased">
    <transition name="fade" mode="out-in">
      <CharacterHub 
        v-if="currentView === 'hub'"
        :characters="characters"
        :max-slots="maxSlots"
        @select="handleSelect"
        @create="handleCreate"
        @delete="handleDelete"
        @edit="handleEdit"
        @focus="handleFocus"
      />
      
      <CreateCharacter 
        v-else-if="currentView === 'create'"
        :slot="selectedSlot"
        @submit="handleCreateSubmit"
        @cancel="currentView = 'hub'"
      />
      
      <SpawnSelector
        v-else-if="currentView === 'spawn'"
        :character="selectedCharacter"
        :spawns="spawns"
        @select="handleSpawnSelect"
        @preview="handleSpawnPreview"
      />
    </transition>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import CharacterHub from './components/CharacterHub.vue'
import CreateCharacter from './components/CreateCharacter.vue'
import SpawnSelector from './components/SpawnSelector.vue'

const visible = ref(false)
const currentView = ref('hub')
const characters = ref([])
const maxSlots = ref(3)
const selectedSlot = ref(null)
const selectedCharacter = ref(null)
const spawns = ref({})

function GetParentResourceName() {
  let name = 'nexus-multicharacter'
  
  if (window.GetParentResourceName) {
    name = window.GetParentResourceName()
  }
  
  return name
}

function handleMessage(event) {
  const data = event.data
  
  if (!data || !data.action) return
  
  switch(data.action) {
    case 'setVisible':
      visible.value = data.visible
      break
      
    case 'openCharacterHub':
      visible.value = true
      currentView.value = 'hub'
      characters.value = data.characters || []
      maxSlots.value = data.maxSlots || 3
      break
      
    case 'updateCharacters':
      characters.value = data.characters || []
      maxSlots.value = data.maxSlots || 3
      break
      
    case 'openSpawnSelector':
      currentView.value = 'spawn'
      selectedCharacter.value = data.character
      spawns.value = data.spawns || {}
      break
      
    case 'close':
      visible.value = false
      currentView.value = 'hub'
      break
  }
}

function post(endpoint, data = {}) {
  fetch(`https://${GetParentResourceName()}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  }).catch(err => {
    console.error('Failed to post to Lua:', err)
  })
}

function handleSelect(character) {
  selectedCharacter.value = character
  post('selectCharacter', { character })
}

function handleCreate(slot) {
  selectedSlot.value = slot
  currentView.value = 'create'
}

function handleDelete(character) {
  post('deleteCharacter', { slot: character.slot })
}

function handleEdit(character) {
  post('editCharacter', { character })
}

function handleFocus(slot) {
  post('focusCharacter', { slot })
}

function handleCreateSubmit(data) {
  post('createCharacter', data)
  currentView.value = 'hub'
}

function handleSpawnSelect(spawn) {
  post('selectSpawn', { 
    spawn: spawn,
    character: selectedCharacter.value
  })
  visible.value = false
}

function handleSpawnPreview(spawn) {
  post('previewSpawn', { spawn })
}

function handleKeydown(e) {
  if (e.key === 'Escape' && visible.value) {
    if (currentView.value === 'spawn') {
      return // Don't allow ESC during spawn selection
    }
    
    if (currentView.value === 'create') {
      currentView.value = 'hub'
    } else {
      post('close')
    }
  }
}

onMounted(() => {
  window.addEventListener('message', handleMessage)
  window.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  window.removeEventListener('message', handleMessage)
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  margin: 0;
  padding: 0;
  overflow: hidden;
}

#app {
  font-family: 'Inter', sans-serif;
  width: 100vw;
  height: 100vh;
  background: linear-gradient(135deg, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0.6) 100%);
  backdrop-filter: blur(10px);
  display: flex;
  align-items: center;
  justify-content: center;
  position: fixed;
  top: 0;
  left: 0;
}

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>