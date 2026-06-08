// ── ZDX Menu List NUI ──
'use strict';

if (typeof GetParentResourceName === 'undefined') {
  window.GetParentResourceName = () => 'zdx_menu_list';
}

const wrap     = document.getElementById('menu-wrap');
const thead    = document.getElementById('menu-head');
const tbody    = document.getElementById('menu-body');

let currentNS   = null;
let currentName = null;
let rowsData    = [];

function fetchNui(event, data) {
  return fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  });
}

// Parse {{Label|value}} button syntax
function parseCell(text) {
  const match = String(text).match(/^\{\{(.+?)\|(.+?)\}\}$/);
  if (match) {
    const btn = document.createElement('button');
    btn.textContent = match[1];
    btn.dataset.value = match[2];
    return btn;
  }
  return document.createTextNode(text);
}

function open(ns, name, data) {
  currentNS   = ns;
  currentName = name;
  rowsData    = data.rows || [];

  // Build header
  thead.innerHTML = '';
  const hRow = document.createElement('tr');
  (data.head || []).forEach(col => {
    const th = document.createElement('th');
    th.textContent = col;
    hRow.appendChild(th);
  });
  thead.appendChild(hRow);

  // Build body
  tbody.innerHTML = '';
  rowsData.forEach((row, idx) => {
    const tr = document.createElement('tr');
    (row.cols || []).forEach(cell => {
      const td = document.createElement('td');
      td.appendChild(parseCell(cell));
      tr.appendChild(td);
    });

    // Button click
    tr.querySelectorAll('button').forEach(btn => {
      btn.addEventListener('click', () => {
        const submitData = Object.assign({}, row.data || {}, {
          currentRow: idx + 1,
        });
        fetchNui('menu_submit', {
          _namespace: ns,
          _name: name,
          data: submitData,
          value: btn.dataset.value,
        });
        close();
      });
    });

    tbody.appendChild(tr);
  });

  wrap.style.display = 'block';
}

function close() {
  wrap.style.display = 'none';
  thead.innerHTML = '';
  tbody.innerHTML = '';
  currentNS = currentName = null;
  rowsData = [];
}

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && currentNS) {
    fetchNui('menu_cancel', { _namespace: currentNS, _name: currentName });
    close();
  }
});

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'openMenu')  open(data.namespace, data.name, data.data || {});
  if (data.action === 'closeMenu') close();
});
