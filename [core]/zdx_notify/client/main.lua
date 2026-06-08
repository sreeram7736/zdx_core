-- ══════════════════════════════════════════════════════════════
-- ZDX Notify: Client
-- Sends toast notifications to the NUI layer.
-- API:
--   exports['zdx_notify']:Notify(type, length, message, title, position)
--   RegisterNetEvent 'zdx:Notify'
-- ══════════════════════════════════════════════════════════════

--- Parse ~color~ codes into HTML span tags.
--- @param msg string
--- @return string
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
        ['~u~'] = '<span style="color:#2c3e50">',
        ['~s~'] = '</span>',
        ['~br~'] = '<br>',
    }
    for code, html in pairs(map) do
        msg = msg:gsub(code, html)
    end
    return msg
end

--- Show a notification.
--- @param notifType string  "success" | "error" | "info" | "warning"
--- @param length    number  Duration in ms (default Config.DefaultDuration)
--- @param message   string  Notification body text
--- @param title     string? Optional title
--- @param position  string? Override Config.DefaultPosition
local function Notify(notifType, length, message, title, position)
    notifType = notifType or 'info'
    length    = length    or Config.DefaultDuration
    message   = ParseColorCodes(message or '')
    title     = title     or Config.DefaultTitle
    position  = position  or Config.DefaultPosition

    SendNuiMessage(json.encode({
        type     = notifType,
        length   = length,
        message  = message,
        title    = title,
        position = position,
        soundEnabled = Config.SoundEnabled,
    }))
end

-- ── Exports ──────────────────────────────────────────────────
exports('Notify', Notify)


-- ── zdx compat net event ──────────────────────────────────────
RegisterNetEvent('zdx:Notify', Notify)

-- ── ESX compat net event ──────────────────────────────────────
RegisterNetEvent('ESX:Notify', Notify)


-- ── QB compat: QBCore:Notify ──────────────────────────────────
RegisterNetEvent('QBCore:Notify', function(text, nType, duration)
    Notify(nType or 'info', duration or Config.DefaultDuration, type(text) == 'table' and text.text or tostring(text))
end)
