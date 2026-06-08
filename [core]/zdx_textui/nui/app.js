// ── ZDX TextUI NUI ──
'use strict';

const elements = {
  info:    document.getElementById('notify-info'),
  success: document.getElementById('notify-success'),
  error:   document.getElementById('notify-error'),
};
const texts = {
  info:    document.getElementById('text-info'),
  success: document.getElementById('text-success'),
  error:   document.getElementById('text-error'),
};

let lastType = null;

function show(message, type) {
  type = type || 'info';

  // Hide previous
  if (lastType && lastType !== type) {
    const prev = elements[lastType];
    if (prev) {
      prev.classList.remove('show');
      prev.classList.add('hide');
      setTimeout(() => { prev.style.display = 'none'; prev.classList.remove('hide'); }, 300);
    }
  }

  const el = elements[type];
  const tx = texts[type];
  if (!el || !tx) return;

  tx.innerHTML = message;
  el.style.display = 'flex';
  el.classList.remove('hide');
  void el.offsetWidth; // reflow
  el.classList.add('show');
  lastType = type;
}

function hide() {
  if (!lastType) return;
  const el = elements[lastType];
  if (!el) return;
  el.classList.remove('show');
  el.classList.add('hide');
  setTimeout(() => { el.style.display = 'none'; el.classList.remove('hide'); }, 300);
  lastType = null;
}

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'show') show(data.message, data.type);
  else if (data.action === 'hide') hide();
});
