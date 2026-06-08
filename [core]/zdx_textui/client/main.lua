-- ══════════════════════════════════════════════════════════════
-- ZDX TextUI: Client
-- Persistent on-screen hint that stays until HideUI() is called.
-- API:
--   exports['zdx_textui']:TextUI(message, type)
--   exports['zdx_textui']:HideUI()
--   RegisterNetEvent 'zdx:TextUI' / 'zdx:HideUI'
-- ══════════════════════════════════════════════════════════════

--- Parse ~color~ codes into HTML span tags.
local function ParseColorCodes(msg)
    if type(msg) ~= 'string' then return tostring(msg) end
    local map = {
        ['~r~'] = '<span style="color:#e74c3c">',
        ['~g~'] = '<span style="color:#2ecc71">',
        ['~b~'] = '<span style="color:#3498db">',
        ['~y~'] = '<span style="color:#f39c12">',
        ['~p~'] = '<span style="color:#9b59b6">',
        ['~o~'] = '<span style="color:#e67e22">',
        ['~c~'] = '<span style="color:#95a5a6">',
        ['~s~'] = '</span>',
        ['~br~'] = '<br>',
    }
    for code, html in pairs(map) do
        msg = msg:gsub(code, html)
    end
    return msg
end

--- Show the TextUI hint.
--- @param message string  Text to display (supports ~color~ codes)
--- @param uiType  string  "info" | "success" | "error"
local function TextUI(message, uiType)
    SendNuiMessage(json.encode({
        action  = 'show',
        message = ParseColorCodes(message or ''),
        type    = uiType or 'info',
    }))
end

--- Hide the TextUI hint.
local function HideUI()
    SendNuiMessage(json.encode({ action = 'hide' }))
end

-- ── Exports ──────────────────────────────────────────────────
exports('TextUI', TextUI)
exports('HideUI', HideUI)

-- ── Net events (esx compat) ───────────────────────────────────
RegisterNetEvent('ESX:TextUI', TextUI)
RegisterNetEvent('ESX:HideUI', HideUI)

-- ── Net events (zdx compat) ───────────────────────────────────
RegisterNetEvent('zdx:TextUI', TextUI)
RegisterNetEvent('zdx:HideUI', HideUI)
