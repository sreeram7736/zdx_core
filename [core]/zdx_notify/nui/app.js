// ── ZDX Notify NUI ──
'use strict';

// Type config: icon, in/out animation classes
const TYPE_CFG = {
  success: { icon: 'check_circle',  inAnim: 'slideInRight',  outAnim: 'slideOutRight' },
  error:   { icon: 'error',          inAnim: 'slideInRight',  outAnim: 'slideOutRight' },
  info:    { icon: 'info',           inAnim: 'slideInRight',  outAnim: 'slideOutRight' },
  warning: { icon: 'warning_amber',  inAnim: 'slideInRight',  outAnim: 'slideOutRight' },
};

const POSITION_ANIM = {
  'top-left':     { in: 'slideInLeft',  out: 'slideOutLeft'  },
  'top-middle':   { in: 'slideInDown',  out: 'slideOutUp'    },
  'top-right':    { in: 'slideInRight', out: 'slideOutRight' },
  'middle-left':  { in: 'slideInLeft',  out: 'slideOutLeft'  },
  'middle-right': { in: 'slideInRight', out: 'slideOutRight' },
  'bottom-left':  { in: 'slideInLeft',  out: 'slideOutLeft'  },
  'bottom-middle':{ in: 'slideInUp',    out: 'slideOutDown'  },
  'bottom-right': { in: 'slideInRight', out: 'slideOutRight' },
};

// Web Audio for sound
let audioCtx = null;
document.addEventListener('click', () => {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
}, { once: true });

const SOUND_CFG = {
  success: { freq: 800, dur: 100 },
  error:   { freq: 300, dur: 150 },
  info:    { freq: 600, dur: 100 },
  warning: { freq: 450, dur: 125 },
};

function playSound(type) {
  if (!audioCtx) return;
  const cfg = SOUND_CFG[type] || SOUND_CFG.info;
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.connect(gain);
  gain.connect(audioCtx.destination);
  osc.type = 'sine';
  osc.frequency.value = cfg.freq;
  gain.gain.setValueAtTime(0.08, audioCtx.currentTime);
  osc.start();
  osc.stop(audioCtx.currentTime + cfg.dur / 1000);
}

function notify({ type, length, message, title, position, soundEnabled }) {
  type     = type     || 'info';
  length   = length   || 3000;
  position = position || 'middle-right';
  title    = title    || 'Notification';

  const container = document.getElementById(position);
  if (!container) return;

  const cfg  = TYPE_CFG[type] || TYPE_CFG.info;
  const anim = POSITION_ANIM[position] || POSITION_ANIM['middle-right'];

  if (soundEnabled !== false) playSound(type);

  // Build element
  const el = document.createElement('div');
  el.className = `notify ${type}`;
  el.style.animation = `${anim.in} 0.3s ease forwards`;
  el.innerHTML = `
    <div class="icon-wrap">
      <span class="material-symbols-outlined notify-icon">${cfg.icon}</span>
    </div>
    <div class="notify-content">
      <div class="notify-title">${title}</div>
      <div class="notify-message">${message}</div>
    </div>
    <div class="progress-bar" id="pb-${Date.now()}"></div>
  `;
  container.appendChild(el);

  // Animate progress bar
  const pb = el.querySelector('.progress-bar');
  requestAnimationFrame(() => {
    pb.style.transition = `width ${length}ms linear`;
    pb.style.width = '100%';
  });

  // Remove after duration
  setTimeout(() => {
    el.style.animation = `${anim.out} 0.5s ease forwards`;
    setTimeout(() => el.remove(), 500);
  }, length);
}

window.addEventListener('message', (e) => {
  const data = e.data;
  if (data && data.type) notify(data);
});
