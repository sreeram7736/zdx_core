-- ══════════════════════════════════════════════════════════════
-- ZDX Context: Client
-- Right-click style context menu positioned at left/center/right.
-- API:
--   exports['zdx_context']:Open(position, elements, onSelect, onClose, canClose)
--   exports['zdx_context']:Preview(position, elements, onSelect, onClose, canClose)
--   exports['zdx_context']:Close()
--   exports['zdx_context']:Refresh(elements, position)
--   exports['zdx_context']:FocusPreview()
-- ══════════════════════════════════════════════════════════════

local IsOpen     = false
local OnSelect   = nil
local OnClose    = nil

local function SendToNUI(payload)
    SendNuiMessage(json.encode(payload))
end

--- Internal open implementation.
--- @param focus   boolean  Whether to acquire NUI focus
--- @param position string  "left" | "center" | "right"
--- @param elements table
--- @param onSelect function?
--- @param onClose  function?
--- @param canClose boolean?
local function OpenInternal(focus, position, elements, onSelect, onClose, canClose)
    IsOpen   = true
    OnSelect = onSelect
    OnClose  = onClose

    if canClose == nil then canClose = true end

    SendToNUI({
        func     = 'Open',
        args     = { elements = elements, position = position or 'left', canClose = canClose },
    })

    if focus then
        SetNuiFocus(true, true)
        LocalPlayer.state:set('context:active', true, false)
    end
end

--- Open context menu with NUI focus (clickable).
local function Open(position, elements, onSelect, onClose, canClose)
    OpenInternal(true, position, elements, onSelect, onClose, canClose)
end

--- Open context menu without focus (ambient display).
local function Preview(position, elements, onSelect, onClose, canClose)
    OpenInternal(false, position, elements, onSelect, onClose, canClose)
end

--- Focus an already-open preview menu.
local function FocusPreview()
    if not IsOpen then return end
    SetNuiFocus(true, true)
end

--- Close the active context menu.
local function Close()
    if not IsOpen then return end
    IsOpen = false
    SendToNUI({ func = 'Closed' })
    SetNuiFocus(false, false)
    LocalPlayer.state:set('context:active', false, false)
    if OnClose then OnClose() end
    OnSelect = nil
    OnClose  = nil
end

--- Update elements/position without closing.
local function Refresh(elements, position)
    if not IsOpen then return end
    SendToNUI({
        func = 'Open',
        args = { elements = elements, position = position or 'left', canClose = true },
    })
end

-- ── Preview keybind ───────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(0)
        if IsOpen and IsControlJustReleased(0, 19) then -- LMENU
            FocusPreview()
        end
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────

RegisterNUICallback('selected', function(data, cb)
    cb({ ok = true })
    if OnSelect then
        OnSelect(data.index, data)
    end
end)

RegisterNUICallback('changed', function(data, cb)
    cb({ ok = true })
    -- Forward change to open menu's handler if needed
end)

RegisterNUICallback('closed', function(data, cb)
    cb({ ok = true })
    Close()
end)

-- ── Exports ──────────────────────────────────────────────────
exports('Open',         Open)
exports('Preview',      Preview)
exports('Close',        Close)
exports('Refresh',      Refresh)
exports('FocusPreview', FocusPreview)
