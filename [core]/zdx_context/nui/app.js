// ── ZDX Context Menu NUI ──
'use strict';

if (typeof GetParentResourceName === 'undefined') {
  window.GetParentResourceName = () => 'zdx_context';
}

const container = document.getElementById('container');
let canClose = true;

function fetchNui(event, data) {
  return fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  });
}

function buildItem(el, idx) {
  const item = document.createElement('div');

  if (el.unselectable) {
    item.className = 'item unselectable';
  } else if (el.disabled) {
    item.className = 'item disabled';
  } else {
    item.className = 'item';
  }

  // Icon column
  const iconDiv = document.createElement('div');
  iconDiv.className = 'item-icon';
  if (el.icon) {
    const i = document.createElement('i');
    i.className = el.icon;
    iconDiv.appendChild(i);
  }
  item.appendChild(iconDiv);

  // Body column
  const body = document.createElement('div');
  body.className = 'item-body';

  const titleSpan = document.createElement('span');
  titleSpan.className = 'item-title';
  titleSpan.textContent = el.title || '';
  body.appendChild(titleSpan);

  if (el.description) {
    const desc = document.createElement('span');
    desc.className = 'item-desc';
    desc.textContent = el.description;
    body.appendChild(desc);
  }

  // Input variants
  if (el.input) {
    if (el.inputType === 'radio') {
      const rg = document.createElement('div');
      rg.className = 'radio-group';
      (el.inputValues || []).forEach(opt => {
        const lbl = document.createElement('label');
        lbl.className = 'radio-label';
        const inp = document.createElement('input');
        inp.type = 'radio';
        inp.name = el.name || `radio_${idx}`;
        inp.value = opt.value;
        const mark = document.createElement('span');
        mark.className = 'checkmark';
        lbl.appendChild(inp);
        lbl.appendChild(mark);
        lbl.appendChild(document.createTextNode(' ' + opt.text));
        inp.addEventListener('change', () => {
          fetchNui('changed', { index: idx, value: opt.value });
        });
        rg.appendChild(lbl);
      });
      body.appendChild(rg);
    } else {
      const inp = document.createElement('input');
      inp.type = el.inputType || 'text';
      inp.placeholder = el.inputPlaceholder || '';
      inp.value = el.inputValue !== undefined ? el.inputValue : '';
      if (el.inputMin !== undefined) inp.min = el.inputMin;
      if (el.inputMax !== undefined) inp.max = el.inputMax;
      inp.addEventListener('input', () => {
        fetchNui('changed', { index: idx, value: inp.value });
      });
      body.appendChild(inp);
    }
  }

  item.appendChild(body);

  // Click handler for non-input, non-unselectable items
  if (!el.input && !el.unselectable && !el.disabled) {
    item.addEventListener('click', () => {
      fetchNui('selected', { index: idx });
    });
  }

  return item;
}

function open(elements, position, closeable) {
  canClose = closeable !== false;
  container.className = '';
  container.classList.add(position || 'left');
  container.innerHTML = '';
  (elements || []).forEach((el, idx) => {
    container.appendChild(buildItem(el, idx));
  });
  container.style.display = 'flex';
}

function close() {
  container.style.display = 'none';
  container.innerHTML = '';
}

document.addEventListener('keydown', (e) => {
  if ((e.key === 'Escape' || e.key === 'Backspace') && canClose) {
    fetchNui('closed', {});
    close();
  }
});

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.func === 'Open') {
    open(data.args.elements, data.args.position, data.args.canClose);
  } else if (data.func === 'Closed') {
    close();
  }
});
