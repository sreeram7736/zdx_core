// ── ZDX Progressbar NUI ──
'use strict';

const wrap    = document.getElementById('progressbar-wrap');
const msgEl   = document.getElementById('prog-message');
const progEl  = document.getElementById('progline');

let timer = null;

function start(message, length) {
  if (timer) clearTimeout(timer);
  msgEl.innerHTML = message || 'Working...';
  wrap.style.display = 'block';

  // Reset bar
  progEl.style.transition = 'none';
  progEl.style.width = '0%';
  void progEl.offsetWidth; // reflow

  // Animate to 100%
  progEl.style.transition = `width ${length}ms linear`;
  progEl.style.width = '100%';

  // Auto-close after duration
  timer = setTimeout(close, length);
}

function close() {
  if (timer) { clearTimeout(timer); timer = null; }
  wrap.style.display = 'none';
  progEl.style.transition = 'none';
  progEl.style.width = '0%';
}

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.type === 'Progressbar') start(data.message, data.length || 3000);
  else if (data.type === 'Close')  close();
});
