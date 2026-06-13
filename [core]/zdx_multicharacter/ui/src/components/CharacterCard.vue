<script setup>
const props = defineProps({
  character: {
    type: Object,
    default: null
  },
  slot: {
    type: Number,
    required: true
  }
})

const emit = defineEmits(['select', 'create', 'delete', 'edit', 'focus'])

function GetParentResourceName() {
  return window.GetParentResourceName ? window.GetParentResourceName() : 'nexus-multicharacter'
}

function handleHover() {
  if (props.character) {
    emit('focus', props.slot)
  }
}

function handleDelete() {
  const name = `${props.character.firstname} ${props.character.lastname}`
  if (confirm(`Delete ${name}? This action cannot be undone.`)) {
    emit('delete', props.character)
  }
}

function getJobLabel(character) {
  if (!character || !character.metadata) return 'Unemployed'
  
  try {
    const metadata = typeof character.metadata === 'string' 
      ? JSON.parse(character.metadata) 
      : character.metadata
    return metadata?.job || 'Unemployed'
  } catch (e) {
    return 'Unemployed'
  }
}

function formatPlaytime(minutes) {
  if (!minutes || minutes === 0) return '0h'
  const hours = Math.floor(minutes / 60)
  return `${hours}h`
}

function formatMoney(amount) {
  if (!amount) return '0'
  return new Intl.NumberFormat('en-US').format(amount)
}

function getCash(character) {
  if (!character || !character.metadata) return 0
  
  try {
    const metadata = typeof character.metadata === 'string' 
      ? JSON.parse(character.metadata) 
      : character.metadata
    return metadata?.cash || 0
  } catch (e) {
    return 0
  }
}
</script>