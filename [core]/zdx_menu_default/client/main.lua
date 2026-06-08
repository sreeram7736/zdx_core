-- ══════════════════════════════════════════════════════════════
-- ZDX Menu Default: Client
-- Arrow-key navigated menu with optional sliders.
-- API (via ZDX.UI.Menu registry):
--   ZDX.UI.Menu.Open("default", namespace, name, data, submit, cancel, change, close)
--   ZDX.UI.Menu.Close("default", namespace, name)
-- ══════════════════════════════════════════════════════════════

local MenuStack = {}   -- { [namespace:name] = menuObj }
local KeyDebounce = 0

local Controls = {
    TOP       = { id = 172 }, -- UP arrow
    DOWN      = { id = 173 }, -- DOWN arrow
    ENTER     = { id = 191 }, -- RETURN / Enter
    BACKSPACE = { id = 177 }, -- BACKSPACE
    LEFT      = { id = 174 }, -- LEFT arrow
    RIGHT     = { id = 175 }, -- RIGHT arrow
}

local function SendControl(ctrl)
    SendNuiMessage(json.encode({
        action  = 'controlPressed',
        control = ctrl,
    }))
end

--- Open a default menu.
--- @param namespace string
--- @param name      string
--- @param data      table   { title, align, elements = { {label,name,description,type,value,min,max,options,...} } }
--- @param submit    function(data, menu)
--- @param cancel    function(data, menu)
--- @param change    function(data, menu)
--- @param close     function()
local function OpenMenu(namespace, name, data, submit, cancel, change, close)
    local menuKey = namespace .. ':' .. name

    MenuStack[menuKey] = {
        namespace = namespace,
        name      = name,
        data      = data,
        submit    = submit,
        cancel    = cancel,
        change    = change,
        close     = close,
    }

    data.namespace = namespace
    data.name      = name

    SendNuiMessage(json.encode({
        action = 'openMenu',
        data   = data,
    }))
    SetNuiFocus(false, false) -- keyboard navigation, no mouse focus needed
end

--- Close a menu by key.
local function CloseMenu(namespace, name)
    local menuKey = namespace .. ':' .. name
    local menu = MenuStack[menuKey]
    if not menu then return end

    MenuStack[menuKey] = nil
    SendNuiMessage(json.encode({
        action    = 'closeMenu',
        namespace = namespace,
        name      = name,
    }))
    if menu.close then menu.close() end
end

-- ── Key polling thread ────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(0)
        if next(MenuStack) == nil then goto continue end

        local now = GetGameTimer()
        if now < KeyDebounce then goto continue end

        for ctrl, bind in pairs(Controls) do
            if IsControlJustReleased(0, bind.id) then
                if ctrl == 'ENTER' then KeyDebounce = now + 200 end
                SendControl(ctrl)
                break
            end
        end

        ::continue::
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────

RegisterNUICallback('menu_submit', function(data, cb)
    cb({ ok = true })
    local menuKey = data._namespace .. ':' .. data._name
    local menu = MenuStack[menuKey]
    if not menu then return end

    MenuStack[menuKey] = nil
    if menu.submit then menu.submit(data, menu) end
    if menu.close then menu.close() end
end)

RegisterNUICallback('menu_cancel', function(data, cb)
    cb({ ok = true })
    local menuKey = data._namespace .. ':' .. data._name
    local menu = MenuStack[menuKey]
    if not menu then return end

    MenuStack[menuKey] = nil
    if menu.cancel then menu.cancel(data, menu) end
    if menu.close then menu.close() end
end)

RegisterNUICallback('menu_change', function(data, cb)
    cb({ ok = true })
    local menuKey = data._namespace .. ':' .. data._name
    local menu = MenuStack[menuKey]
    if menu and menu.change then menu.change(data, menu) end
end)

-- ── Exports ──────────────────────────────────────────────────
exports('OpenMenu',  OpenMenu)
exports('CloseMenu', CloseMenu)
