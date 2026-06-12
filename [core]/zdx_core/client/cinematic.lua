-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Cinematic Optimizations
-- Optimizations tailored for FiveM cinematic production.
--
-- Features:
--   • Dispatch/police system disabled (no wanted level)
--   • Idle camera disabled (prevents auto-cinematic cam)
--   • Clean HUD toggle (/cleanhud)
--   • Ambient audio suppression (/muteambient)
--   • Timecycle modifier support (/timecycle)
--   • Weather lock support (server-side via /lockweather)
--   • Performance: aggressive LOD, reduced clutter
--
-- All features are toggleable so you can switch between
-- cinematic and normal gameplay modes.
-- ══════════════════════════════════════════════════════════════

-- ── State ────────────────────────────────────────────────────
local cinematicMode = false   -- Master toggle
local cleanHud = false        -- HUD hidden
local muteAmbient = false     -- Ambient sounds muted
local activeTimecycle = nil   -- Current timecycle modifier
local timecycleStrength = 1.0

-- ══════════════════════════════════════════════════════════════
-- ALWAYS-ON CINEMATIC OPTIMIZATIONS
-- These run regardless of cinematic mode — they're baseline
-- quality-of-life for a cinematic framework.
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    -- ── Disable dispatch / wanted level ──────────────────────
    -- Cops should never chase players during cinematic work
    for i = 1, 15 do
        EnableDispatchService(i, false)
    end

    -- ── Disable idle camera ─────────────────────────────────
    -- Prevents the game from taking over the camera after idle
    DisableIdleCamera(true)

    -- ── Disable auto-start for ambient events ───────────────
    SetRandomEventFlag(false)

    -- ── Reduce AI aggression ────────────────────────────────
    -- NPCs won't start fights or run away as aggressively
    SetMaxWantedLevel(0)

    while true do
        -- Ensure wanted level stays at 0
        if GetPlayerWantedLevel(PlayerId()) > 0 then
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end

        -- Disable idle camera every frame
        InvalidateIdleCam()
        DisableIdleCamera(true)

        Wait(1000)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- CINEMATIC MODE TOGGLE
-- Enables: clean HUD, mute ambient, reduced world clutter
-- ══════════════════════════════════════════════════════════════

--- Toggle cinematic mode on/off
local function ToggleCinematicMode()
    cinematicMode = not cinematicMode

    if cinematicMode then
        cleanHud = true
        muteAmbient = true
        ZDX.ShowNotification('[ZDX] ~g~Cinematic Mode ON~s~ — HUD hidden, ambient muted')
    else
        cleanHud = false
        muteAmbient = false
        -- Clear any timecycle
        if activeTimecycle then
            ClearTimecycleModifier()
            activeTimecycle = nil
        end
        ZDX.ShowNotification('[ZDX] ~r~Cinematic Mode OFF~s~ — Normal mode restored')
    end
end

exports('ToggleCinematicMode', ToggleCinematicMode)
exports('IsCinematicMode', function() return cinematicMode end)

RegisterCommand('cinematic', function()
    ToggleCinematicMode()
end, false)

TriggerEvent('chat:addSuggestion', '/cinematic', 'Toggle cinematic mode (clean HUD + mute ambient)')

-- ══════════════════════════════════════════════════════════════
-- CLEAN HUD — Hide all HUD elements for recording
-- ══════════════════════════════════════════════════════════════

local HUD_COMPONENTS = {
    1,  -- Wanted stars
    2,  -- Weapon icon
    3,  -- Cash
    4,  -- MP Cash
    6,  -- Vehicle name
    7,  -- Area name
    8,  -- Vehicle class
    9,  -- Street name
    13, -- Cash change
    17, -- Save game
    20, -- Weapon wheel stats
}

local function ToggleCleanHud()
    cleanHud = not cleanHud
    if cleanHud then
        ZDX.ShowNotification('[ZDX] HUD ~r~hidden')
    else
        ZDX.ShowNotification('[ZDX] HUD ~g~visible')
    end
end

exports('ToggleCleanHud', ToggleCleanHud)
exports('IsCleanHud', function() return cleanHud end)

RegisterCommand('cleanhud', function()
    ToggleCleanHud()
end, false)

TriggerEvent('chat:addSuggestion', '/cleanhud', 'Toggle HUD visibility for clean recording')

-- ── HUD hide loop ────────────────────────────────────────────
CreateThread(function()
    while true do
        if cleanHud then
            -- Hide HUD components
            for _, id in ipairs(HUD_COMPONENTS) do
                HideHudComponentThisFrame(id)
            end
            -- Hide minimap
            DisplayRadar(false)
            -- Hide reticle
            HideHudComponentThisFrame(14)
            Wait(0)
        else
            DisplayRadar(true)
            Wait(500)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- AMBIENT AUDIO — Mute ambient sounds for clean audio
-- ══════════════════════════════════════════════════════════════

local function ToggleMuteAmbient()
    muteAmbient = not muteAmbient
    if muteAmbient then
        ZDX.ShowNotification('[ZDX] Ambient audio ~r~muted')
    else
        ZDX.ShowNotification('[ZDX] Ambient audio ~g~restored')
    end
end

exports('ToggleMuteAmbient', ToggleMuteAmbient)

RegisterCommand('muteambient', function()
    ToggleMuteAmbient()
end, false)

TriggerEvent('chat:addSuggestion', '/muteambient', 'Toggle ambient audio for clean recording')

CreateThread(function()
    while true do
        if muteAmbient then
            -- Suppress various ambient audio sources
            SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Ambient_Powerful_Waves', false, false)
            SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Distant_Rain_Powerful', false, false)
            StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')  -- Suppresses most ambient
            SetStaticEmitterEnabled('LOS_SANTOS_DISTANT_SIRENS', false)
            SetStaticEmitterEnabled('LOS_SANTOS_DISTANT_CARS', false)
            SetStaticEmitterEnabled('LOS_SANTOS_DISTANT_GUNSHOTS', false)
            Wait(0)
        else
            StopAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
            SetStaticEmitterEnabled('LOS_SANTOS_DISTANT_SIRENS', true)
            SetStaticEmitterEnabled('LOS_SANTOS_DISTANT_CARS', true)
            SetStaticEmitterEnabled('LOS_SANTOS_DISTANT_GUNSHOTS', true)
            Wait(2000)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- TIMECYCLE MODIFIERS — Quick visual filters for cinematic look
-- ══════════════════════════════════════════════════════════════

local TIMECYCLES = {
    'default',
    'cinema',               -- Classic cinema look
    'NG_filmic01',          -- Film grain look
    'NG_filmic02',
    'NG_filmic03',
    'NG_filmic08',
    'NG_filmic10',
    'NG_filmic16',
    'NG_filmic20',
    'NG_filmic25',
    'CAMERA_secuirity',     -- Security cam look
    'phone_cam',            -- Phone camera
    'prologue',             -- Prologue color grade
    'stunt_cam_dirt',       -- Stunt cam look
    'spectator1',           -- Spectator view
    'spectator5',
    'underwater',           -- Underwater tint
}

local currentTimecycleIndex = 0

RegisterCommand('timecycle', function(source, args)
    if args[1] == 'off' or args[1] == 'clear' then
        ClearTimecycleModifier()
        activeTimecycle = nil
        currentTimecycleIndex = 0
        ZDX.ShowNotification('[ZDX] Timecycle ~r~cleared')
        return
    end

    if args[1] == 'list' then
        for i, tc in ipairs(TIMECYCLES) do
            TriggerEvent('chat:addMessage', {
                args = { '^3ZDX', ('%d. %s'):format(i, tc) }
            })
        end
        return
    end

    if args[1] then
        -- Direct name
        SetTimecycleModifier(args[1])
        SetTimecycleModifierStrength(tonumber(args[2]) or 1.0)
        activeTimecycle = args[1]
        ZDX.ShowNotification(('[ZDX] Timecycle: ~b~%s'):format(args[1]))
    else
        -- Cycle through presets
        currentTimecycleIndex = currentTimecycleIndex + 1
        if currentTimecycleIndex > #TIMECYCLES then
            ClearTimecycleModifier()
            activeTimecycle = nil
            currentTimecycleIndex = 0
            ZDX.ShowNotification('[ZDX] Timecycle ~r~cleared')
        else
            local tc = TIMECYCLES[currentTimecycleIndex]
            SetTimecycleModifier(tc)
            SetTimecycleModifierStrength(1.0)
            activeTimecycle = tc
            ZDX.ShowNotification(('[ZDX] Timecycle: ~b~%s~s~ (%d/%d)'):format(tc, currentTimecycleIndex, #TIMECYCLES))
        end
    end
end, false)

TriggerEvent('chat:addSuggestion', '/timecycle', 'Set a timecycle visual filter (leave empty to cycle, "off" to clear, "list" to show all)', {
    { name = 'name', help = 'Timecycle name or "off"/"list" (leave empty to cycle)' },
    { name = 'strength', help = 'Strength 0.0 - 1.0 (default 1.0)' }
})

-- ══════════════════════════════════════════════════════════════
-- PERFORMANCE OPTIMIZATIONS FOR CINEMATICS
-- Reduce background clutter that doesn't affect visuals
-- but improves FPS during complex scenes.
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    -- Disable auto-loading screen tips
    SetNoLoadingScreen(true)

    while true do
        -- Disable distant sirens / explosions that break scenes
        DistantCopCarSirens(false)

        -- Remove weapon/ammo pickups that spawn randomly
        SetCreateRandomCops(false)
        SetCreateRandomCopsNotOnScenarios(false)
        SetCreateRandomCopsOnScenarios(false)

        Wait(5000)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- BLACKOUT MODE — Kill all lights for night scenes
-- ══════════════════════════════════════════════════════════════

local blackout = false

local function ToggleBlackout()
    blackout = not blackout
    SetArtificialLightsState(blackout)
    SetArtificialLightsStateAffectsVehicles(false) -- Keep vehicle lights on
    if blackout then
        ZDX.ShowNotification('[ZDX] Blackout ~r~ON~s~ — Street lights off')
    else
        ZDX.ShowNotification('[ZDX] Blackout ~g~OFF~s~ — Lights restored')
    end
end

exports('ToggleBlackout', ToggleBlackout)
exports('IsBlackout', function() return blackout end)

RegisterCommand('blackout', function()
    ToggleBlackout()
end, false)

TriggerEvent('chat:addSuggestion', '/blackout', 'Toggle street lights off for dark cinematic scenes')

print('^2[ZDX]^0 Cinematic optimizations loaded.')
