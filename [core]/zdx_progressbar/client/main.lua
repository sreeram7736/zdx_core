-- ══════════════════════════════════════════════════════════════
-- ZDX Progressbar: Client
-- Displays a timed progress bar with optional anim/freeze.
-- Only one bar active at a time. Cancellable with BACKSPACE.
-- API:
--   exports['zdx_progressbar']:Progressbar(message, length, options)
--   exports['zdx_progressbar']:CancelProgressbar()
-- ══════════════════════════════════════════════════════════════

local IsRunning = false
local CancelCallback = nil

--- Parse ~color~ codes to HTML spans.
local function ParseColorCodes(msg)
    if type(msg) ~= 'string' then return tostring(msg) end
    local map = {
        ['~r~'] = '<span style="color:#e74c3c">',
        ['~g~'] = '<span style="color:#2ecc71">',
        ['~b~'] = '<span style="color:#3498db">',
        ['~y~'] = '<span style="color:#f39c12">',
        ['~o~'] = '<span style="color:#e67e22">',
        ['~s~'] = '</span>',
    }
    for code, html in pairs(map) do
        msg = msg:gsub(code, html)
    end
    return msg
end

--- Cancel an active progress bar immediately.
local function CancelProgressbar()
    if not IsRunning then return end
    IsRunning = false
    SendNuiMessage(json.encode({ type = 'Close' }))
    local cb = CancelCallback
    CancelCallback = nil
    if cb then cb() end
end

--- Start a progress bar.
--- @param message string   Label shown above the bar
--- @param length  number   Duration in ms
--- @param options table?   { FreezePlayer, animation{type,dict,lib,Scenario}, onFinish, onCancel }
local function Progressbar(message, length, options)
    if IsRunning then return false end
    IsRunning = true
    options = options or {}
    length  = length  or 3000

    local ped = PlayerPedId()

    -- Optional freeze
    if options.FreezePlayer then
        FreezeEntityPosition(ped, true)
    end

    -- Optional animation
    if options.animation then
        local anim = options.animation
        if anim.type == 'anim' then
            RequestAnimDict(anim.dict)
            local timeout = GetGameTimer() + 5000
            while not HasAnimDictLoaded(anim.dict) do
                Wait(0)
                if GetGameTimer() > timeout then break end
            end
            TaskPlayAnim(ped, anim.dict, anim.lib, 2.0, -2.0, -1, 49, 0, false, false, false)
        elseif anim.type == 'Scenario' then
            TaskStartScenarioInPlace(ped, anim.Scenario, 0, true)
        end
    end

    -- Store cancel callback
    CancelCallback = options.onCancel

    -- Show NUI
    SendNuiMessage(json.encode({
        type    = 'Progressbar',
        length  = length,
        message = ParseColorCodes(message or 'Working...'),
    }))

    -- Wait for completion or cancel
    CreateThread(function()
        local startTime = GetGameTimer()
        while IsRunning and (GetGameTimer() - startTime) < length do
            Wait(0)
            -- BACKSPACE to cancel
            if IsControlJustReleased(0, 177) then
                CancelProgressbar()
                return
            end
        end

        if IsRunning then
            -- Completed naturally
            IsRunning = false
            SendNuiMessage(json.encode({ type = 'Close' }))

            if options.FreezePlayer then
                FreezeEntityPosition(ped, false)
            end
            if options.animation then
                ClearPedTasks(ped)
            end

            CancelCallback = nil
            if options.onFinish then options.onFinish() end
        else
            -- Was cancelled (CancelProgressbar already fired onCancel)
            if options.FreezePlayer then
                FreezeEntityPosition(ped, false)
            end
            if options.animation then
                ClearPedTasks(ped)
            end
        end
    end)

    return true
end

-- ── Exports ──────────────────────────────────────────────────
exports('Progressbar', Progressbar)
exports('CancelProgressbar', CancelProgressbar)
