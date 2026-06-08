-- ══════════════════════════════════════════════════════════════
-- ZDX Menu Dialog: Client
-- Single text/textarea input dialog. Accessed via ZDX Menu registry.
-- ══════════════════════════════════════════════════════════════

local OpenMenus = {}

local function Trim(s)
    return s and s:match('^%s*(.-)%s*$') or ''
end

--- Opens a dialog menu.
--- Called by the ZDX menu registry when type == "dialog".
--- @param data table  { title, type("default"|"big"), value?, align? }
--- @param submit  function(value, menu)
--- @param cancel  function(data, menu)
--- @param change  function(data, menu)
--- @param close   function()
local function OpenMenu(namespace, name, data, submit, cancel, change, close)
    local menuKey = namespace .. ':' .. name

    OpenMenus[menuKey] = {
        namespace = namespace,
        name      = name,
        data      = data,
        submit    = submit,
        cancel    = cancel,
        change    = change,
        close     = close,
    }

    SetNuiFocus(true, true)
    SendNuiMessage(json.encode({
        action    = 'openMenu',
        namespace = namespace,
        name      = name,
        data      = data,
    }))
end

--- Closes a dialog menu.
local function CloseMenu(namespace, name)
    local menuKey = namespace .. ':' .. name
    local menu = OpenMenus[menuKey]
    if not menu then return end

    OpenMenus[menuKey] = nil
    SetNuiFocus(false, false)
    SendNuiMessage(json.encode({
        action    = 'closeMenu',
        namespace = namespace,
        name      = name,
    }))
    if menu.close then menu.close() end
end

-- ── NUI Callbacks ─────────────────────────────────────────────

RegisterNUICallback('menu_submit', function(data, cb)
    cb({ ok = true })
    local menuKey = data._namespace .. ':' .. data._name
    local menu = OpenMenus[menuKey]
    if not menu then return end

    local value = Trim(tostring(data.value or ''))
    if value == '' then
        exports['zdx_notify']:Notify('error', 3000, 'Input cannot be empty.')
        return
    end

    OpenMenus[menuKey] = nil
    SetNuiFocus(false, false)
    if menu.submit then menu.submit(value, menu) end
    if menu.close then menu.close() end
end)

RegisterNUICallback('menu_cancel', function(data, cb)
    cb({ ok = true })
    local menuKey = data._namespace .. ':' .. data._name
    local menu = OpenMenus[menuKey]
    if not menu then return end

    OpenMenus[menuKey] = nil
    SetNuiFocus(false, false)
    if menu.cancel then menu.cancel(data, menu) end
    if menu.close then menu.close() end
end)

RegisterNUICallback('menu_change', function(data, cb)
    cb({ ok = true })
    local menuKey = data._namespace .. ':' .. data._name
    local menu = OpenMenus[menuKey]
    if menu and menu.change then menu.change(data, menu) end
end)

-- ── Exports ──────────────────────────────────────────────────
exports('OpenMenu',  OpenMenu)
exports('CloseMenu', CloseMenu)
