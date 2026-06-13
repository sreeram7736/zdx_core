<template>
  <div class="character-hub">
    <div class="hub-header">
      <h1 class="hub-title">Character Selection</h1>
      <p class="hub-subtitle">Choose or create your character</p>
    </div>
    
    <div class="characters-grid">
      <CharacterCard
        v-for="slot in maxSlots"
        :key="slot"
        :character="getCharacterBySlot(slot)"
        :slot="slot"
        @select="$emit('select', $event)"
        @create="$emit('create', slot)"
        @delete="$emit('delete', $event)"
        @edit="$emit('edit', $event)"
        @focus="$emit('focus', slot)"
      />
    </div>
    
    <div class="hub-footer">
      <button class="btn btn-secondary" @click="handleDisconnect">
        <i class="fas fa-sign-out-alt"></i>
        Disconnect
      </button>
    </div>
  </div>
</template>

<script setup>
import CharacterCard from './CharacterCard.vue'

const props = defineProps({
  characters: {
    type: Array,
    default: () => []
  },
  maxSlots: {
    type: Number,
    default: 3
  }
})

const emit = defineEmits(['select', 'create', 'delete', 'edit', 'focus'])

function GetParentResourceName() {
  return window.GetParentResourceName ? window.GetParentResourceName() : 'nexus-multicharacter'
}

function getCharacterBySlot(slot) {
  return props.characters.find(c => c.slot === slot)
}

function handleDisconnect() {
  fetch(`https://${GetParentResourceName()}/disconnect`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  }).catch(err => console.error(err))
}
</script>

<style scoped>
.character-hub {
  max-width: 1400px;
  width: 90%;
  padding: 3rem;
  background: rgba(15, 15, 20, 0.95);
  border-radius: 24px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.hub-header {
  text-align: center;
  margin-bottom: 3rem;
}

.hub-title {
  font-size: 3rem;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.5rem;
}

.hub-subtitle {
  color: rgba(255, 255, 255, 0.6);
  font-size: 1.1rem;
}

.characters-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 2rem;
  margin-bottom: 3rem;
}

.hub-footer {
  display: flex;
  justify-content: center;
  padding-top: 2rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.btn {
  padding: 0.75rem 2rem;
  border: none;
  border-radius: 12px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.15);
  transform: translateY(-2px);
}
</style>