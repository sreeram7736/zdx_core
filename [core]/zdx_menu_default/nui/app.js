// ── ZDX Menu Default NUI ──
'use strict';

if (typeof GetParentResourceName === 'undefined') {
  window.GetParentResourceName = () => 'zdx_menu_default';
}

const root      = document.getElementById('menu-root');
const titleEl   = document.getElementById('menu-title');
const itemsList = document.getElementById('menu-items');

let menuStack = [];   // array of menu objects (last = top)
let currentIndex = 0;

function fetchNui(event, data) {
  return fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  });
}

function currentMenu() {
  return menuStack[menuStack.length - 1] || null;
}

function render() {
  const menu = currentMenu();
  if (!menu) { root.style.display = 'none'; return; }

  // Apply position alignment to root container
  applyAlign(menu.align || 'right-center');

  titleEl.textContent = menu.title || '';
  root.style.display = 'block';

  itemsList.innerHTML = '';
  (menu.elements || []).forEach((el, idx) => {
    const item = document.createElement('div');
    item.className = 'menu-item' +
      (el.unselectable ? ' unselectable' : '') +
      (idx === currentIndex ? ' selected' : '');

    const leftDiv = document.createElement('div');
    leftDiv.className = 'item-left';

    if (el.icon) {
      const ico = document.createElement('i');
      ico.className = `item-icon ${el.icon}`;
      leftDiv.appendChild(ico);
    }

    const labels = document.createElement('div');
    labels.className = 'item-labels';

    const lbl = document.createElement('span');
    lbl.className = 'item-label';
    lbl.textContent = el.label || '';
    labels.appendChild(lbl);

    if (el.description) {
      const desc = document.createElement('span');
      desc.className = 'item-desc';
      desc.textContent = el.description;
      labels.appendChild(desc);
    }

    leftDiv.appendChild(labels);
    item.appendChild(leftDiv);

    // Right side
    if (el.type === 'slider') {
      const sliderDiv = document.createElement('div');
      sliderDiv.className = 'item-slider';

      const chevL = document.createElement('span');
      chevL.className = 'slider-arrow';
      chevL.textContent = '‹';

      const val = document.createElement('span');
      val.className = 'slider-value';

      // If options array, show option text; else show numeric value
      if (el.options && el.options.length > 0) {
        val.textContent = el.options[el.value] || el.value;
      } else {
        val.textContent = el.value;
      }

      const chevR = document.createElement('span');
      chevR.className = 'slider-arrow';
      chevR.textContent = '›';

      sliderDiv.appendChild(chevL);
      sliderDiv.appendChild(val);
      sliderDiv.appendChild(chevR);
      item.appendChild(sliderDiv);
    } else if (el.usable !== false && !el.unselectable) {
      const arr = document.createElement('span');
      arr.className = 'item-arrow';
      arr.innerHTML = '›';
      item.appendChild(arr);
    }

    itemsList.appendChild(item);
  });
}

function applyAlign(align) {
  const styles = {
    'top-left':     { top:'2%',    bottom:'auto', left:'2%',   right:'auto', transform:'none' },
    'top-right':    { top:'2%',    bottom:'auto', left:'auto', right:'2%',   transform:'none' },
    'bottom-left':  { top:'auto',  bottom:'2%',   left:'2%',   right:'auto', transform:'none' },
    'bottom-right': { top:'auto',  bottom:'2%',   left:'auto', right:'2%',   transform:'none' },
    'center':       { top:'50%',   bottom:'auto', left:'50%',  right:'auto', transform:'translate(-50%,-50%)' },
    'left-center':  { top:'50%',   bottom:'auto', left:'2%',   right:'auto', transform:'translateY(-50%)' },
    'right-center': { top:'50%',   bottom:'auto', left:'auto', right:'2%',   transform:'translateY(-50%)' },
  };
  const s = styles[align] || styles['right-center'];
  Object.assign(root.style, s);
}

function navigableElements() {
  const menu = currentMenu();
  if (!menu) return [];
  return (menu.elements || []).reduce((acc, el, idx) => {
    if (!el.unselectable) acc.push(idx);
    return acc;
  }, []);
}

function nextIndex(dir) {
  const nav = navigableElements();
  if (nav.length === 0) return currentIndex;
  const pos = nav.indexOf(currentIndex);
  if (dir > 0) return nav[(pos + 1) % nav.length];
  return nav[(pos - 1 + nav.length) % nav.length];
}

function handleControl(control) {
  const menu = currentMenu();
  if (!menu) return;
  const elements = menu.elements || [];

  if (control === 'TOP') {
    currentIndex = nextIndex(-1);
    render();
    fetchNui('menu_change', buildPayload(menu));
  } else if (control === 'DOWN') {
    currentIndex = nextIndex(1);
    render();
    fetchNui('menu_change', buildPayload(menu));
  } else if (control === 'ENTER') {
    const el = elements[currentIndex];
    if (!el || el.unselectable || el.usable === false) return;
    fetchNui('menu_submit', buildPayload(menu));
    removeMenu(menu.namespace, menu.name);
  } else if (control === 'BACKSPACE') {
    fetchNui('menu_cancel', { _namespace: menu.namespace, _name: menu.name });
    removeMenu(menu.namespace, menu.name);
  } else if (control === 'LEFT' || control === 'RIGHT') {
    const el = elements[currentIndex];
    if (!el || el.type !== 'slider') return;
    const step = control === 'RIGHT' ? 1 : -1;

    if (el.options && el.options.length > 0) {
      el.value = ((el.value || 0) + step + el.options.length) % el.options.length;
    } else {
      const min = el.min !== undefined ? el.min : 0;
      const max = el.max !== undefined ? el.max : 10;
      el.value = ((el.value || 0) + step - min + (max - min + 1)) % (max - min + 1) + min;
    }
    render();
    fetchNui('menu_change', buildPayload(menu));
  }
}

function buildPayload(menu) {
  return {
    _namespace: menu.namespace,
    _name: menu.name,
    current: currentIndex,
    elements: menu.elements,
  };
}

function removeMenu(ns, name) {
  menuStack = menuStack.filter(m => !(m.namespace === ns && m.name === name));
  currentIndex = 0;
  render();
}

window.addEventListener('message', (e) => {
  const data = e.data || {};

  if (data.action === 'openMenu') {
    const d = data.data;
    // Remove if already in stack
    menuStack = menuStack.filter(m => !(m.namespace === d.namespace && m.name === d.name));
    menuStack.push(d);
    currentIndex = 0;
    // Auto-select first navigable
    const nav = navigableElements();
    if (nav.length > 0) currentIndex = nav[0];
    render();
  }

  if (data.action === 'closeMenu') {
    removeMenu(data.namespace, data.name);
  }

  if (data.action === 'controlPressed') {
    handleControl(data.control);
  }
});
