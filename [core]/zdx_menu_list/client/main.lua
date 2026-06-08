-- ══════════════════════════════════════════════════════════════
-- ZDX Menu List: Client
-- Table-style selection menu. Accessed via ZDX Menu registry.
-- ══════════════════════════════════════════════════════════════

local OpenMenus = {}

--- Opens a list menu.
--- @param namespace string
--- @param name      string
--- @param data      table  { head = {col1, col2}, rows = { {cols={..}, data={..}} } }
--- @param submit    function(data, menu)
--- @param cancel    function(data, menu)
--- @param close     function()
local function OpenMenu(namespace, name, data, submit, cancel, close)
    local menuKey = namespace .. ':' .. name

    OpenMenus[menuKey] = {
        namespace = namespace,
        name      = name,
        data      = data,
        submit    = submit,
        cancel    = cancel,
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

--- Closes a list menu.
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

    OpenMenus[menuKey] = nil
    SetNuiFocus(false, false)
    if menu.submit then menu.submit(data, menu) end
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

-- ── Exports ──────────────────────────────────────────────────
exports('OpenMenu',  OpenMenu)
exports('CloseMenu', CloseMenu)
