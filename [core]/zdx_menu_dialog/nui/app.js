// ── ZDX Menu Dialog NUI ──
'use strict';

const wrap       = document.getElementById('dialog-wrap');
const titleEl    = document.getElementById('dialog-title');
const inputEl    = document.getElementById('dialog-input');
const textareaEl = document.getElementById('dialog-textarea');
const btnSubmit  = document.getElementById('btn-submit');
const btnCancel  = document.getElementById('btn-cancel');

let currentNS   = null;
let currentName = null;

function fetchNui(event, data) {
  return fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  });
}

// Polyfill for NUI context (FiveM injects GetParentResourceName)
if (typeof GetParentResourceName === 'undefined') {
  window.GetParentResourceName = () => 'zdx_menu_dialog';
}

function open(ns, name, data) {
  currentNS   = ns;
  currentName = name;
  titleEl.textContent = data.title || 'Input';

  const isBig = data.type === 'big';
  inputEl.style.display    = isBig ? 'none' : 'block';
  textareaEl.style.display = isBig ? 'block' : 'none';

  const active = isBig ? textareaEl : inputEl;
  active.value = data.value || '';
  wrap.style.display = 'flex';
  setTimeout(() => active.focus(), 50);
}

function close() {
  wrap.style.display = 'none';
  inputEl.value = '';
  textareaEl.value = '';
  currentNS = currentName = null;
}

function submit() {
  if (!currentNS) return;
  const isBig = textareaEl.style.display !== 'none';
  const value = (isBig ? textareaEl.value : inputEl.value).trim();
  fetchNui('menu_submit', { _namespace: currentNS, _name: currentName, value });
  close();
}

function cancel() {
  if (!currentNS) return;
  fetchNui('menu_cancel', { _namespace: currentNS, _name: currentName });
  close();
}

btnSubmit.addEventListener('click', submit);
btnCancel.addEventListener('click', cancel);

document.addEventListener('keydown', (e) => {
  if (!currentNS) return;
  if (e.key === 'Enter' && inputEl.style.display !== 'none') submit();
  if (e.key === 'Escape') cancel();
});

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'openMenu')  open(data.namespace, data.name, data.data || {});
  if (data.action === 'closeMenu') close();
});

// Report input changes
const reportChange = () => {
  if (!currentNS) return;
  const isBig = textareaEl.style.display !== 'none';
  const value = isBig ? textareaEl.value : inputEl.value;
  fetchNui('menu_change', { _namespace: currentNS, _name: currentName, value });
};

inputEl.addEventListener('input', reportChange);
textareaEl.addEventListener('input', reportChange);
