-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: NPC Density Toggle
-- Toggle NPC (ped + vehicle) density for cinematic shoots.
--
-- Levels:
--   high   — Full GTA density (busy city, traffic)
--   medium — 50% density (some life, fewer distractions)
--   small  — 15% density (minimal background NPCs)
--   off    — 0% density (completely empty world)
--
-- Commands:
--   /npc [high|medium|small|off]
--   /npc              — cycles to next level
--
-- Export:
--   exports['zdx_core']:SetNPCLevel(level)
--   exports['zdx_core']:GetNPCLevel()
-- ══════════════════════════════════════════════════════════════

local NPC_LEVELS = {
    ['high']   = { ped = 1.0, vehicle = 1.0, parked = 1.0, scenario = 1.0, label = 'High'   },
    ['medium'] = { ped = 0.5, vehicle = 0.5, parked = 0.5, scenario = 0.5, label = 'Medium' },
    ['small']  = { ped = 0.15, vehicle = 0.15, parked = 0.1, scenario = 0.1, label = 'Small' },
    ['off']    = { ped = 0.0, vehicle = 0.0, parked = 0.0, scenario = 0.0, label = 'Off'    },
}

local LEVEL_ORDER = { 'high', 'medium', 'small', 'off' }

local currentLevel = 'high'
local densityActive = false

--- Set the NPC density level
---@param level string  'high' | 'medium' | 'small' | 'off'
local function SetNPCLevel(level)
    level = string.lower(level or 'high')
    if not NPC_LEVELS[level] then
        level = 'high'
    end

    currentLevel = level
    densityActive = (level ~= 'high')

    -- Clear the area immediately when reducing density
    if level == 'off' then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        ClearAreaOfPeds(coords.x, coords.y, coords.z, 500.0, 0)
        ClearAreaOfVehicles(coords.x, coords.y, coords.z, 500.0, false, false, false, false, false, false)
    elseif level == 'small' then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        ClearAreaOfPeds(coords.x, coords.y, coords.z, 200.0, 0)
        ClearAreaOfVehicles(coords.x, coords.y, coords.z, 200.0, false, false, false, false, false, false)
    end

    -- Notify the player
    ZDX.ShowNotification(('[ZDX] NPC Density: ~b~%s'):format(NPC_LEVELS[level].label))
end

--- Get the current NPC density level
---@return string
local function GetNPCLevel()
    return currentLevel
end

--- Cycle to the next level
local function CycleNPCLevel()
    for i, lvl in ipairs(LEVEL_ORDER) do
        if lvl == currentLevel then
            local nextIndex = (i % #LEVEL_ORDER) + 1
            SetNPCLevel(LEVEL_ORDER[nextIndex])
            return
        end
    end
    SetNPCLevel('high')
end

-- ── Exports ──────────────────────────────────────────────────
exports('SetNPCLevel', SetNPCLevel)
exports('GetNPCLevel', GetNPCLevel)
exports('CycleNPCLevel', CycleNPCLevel)

-- ── Command ──────────────────────────────────────────────────
RegisterCommand('npc', function(source, args)
    if args[1] then
        SetNPCLevel(args[1])
    else
        CycleNPCLevel()
    end
end, false)

-- Keybind suggestion text
TriggerEvent('chat:addSuggestion', '/npc', 'Toggle NPC density (high/medium/small/off)', {
    { name = 'level', help = 'high | medium | small | off (leave empty to cycle)' }
})

-- ══════════════════════════════════════════════════════════════
-- DENSITY CONTROL LOOP
-- Runs every frame when density is not 'high' to enforce the
-- multiplier. This is how GTA requires it — per-frame calls.
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        if densityActive then
            local cfg = NPC_LEVELS[currentLevel]

            -- Ped density
            SetPedDensityMultiplierThisFrame(cfg.ped)
            SetScenarioPedDensityMultiplierThisFrame(cfg.scenario, cfg.scenario)

            -- Vehicle density
            SetVehicleDensityMultiplierThisFrame(cfg.vehicle)
            SetRandomVehicleDensityMultiplierThisFrame(cfg.vehicle)
            SetParkedVehicleDensityMultiplierThisFrame(cfg.parked)

            -- When off, also suppress ambient peds/vehicles from spawning
            if currentLevel == 'off' then
                SetGarbageTrucks(false)
                SetRandomBoats(false)
                SetRandomTrains(false)

                -- Disable all ambient sounds for clean recording
                for i = 1, 15 do
                    EnableDispatchService(i, false)
                end
            end

            Wait(0) -- Must run every frame
        else
            -- Re-enable services when going back to high
            SetGarbageTrucks(true)
            SetRandomBoats(true)
            SetRandomTrains(true)
            for i = 1, 15 do
                EnableDispatchService(i, true)
            end
            Wait(1000) -- Sleep when not active
        end
    end
end)

print('^2[ZDX]^0 NPC density system loaded.')
