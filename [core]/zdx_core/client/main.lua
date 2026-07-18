-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Client Main
-- Handles spawning, model loading, and fires ZDX load events.
-- Bridges translate these into ESX/QB events for compat.
-- NO "awaiting script" — we handle everything natively.
-- ══════════════════════════════════════════════════════════════

-- ── Wait for network activation and signal server ──
CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsPlayerActive(PlayerId()) then
            TriggerServerEvent('zdx_core:server:playerJoined')
            break
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- SPAWN HANDLER
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('zdx_core:client:spawnPlayer', function(spawnCoords, modelName, playerData)
    local ped = PlayerPedId()

    -- Fade out immediately
    DoScreenFadeOut(0)

    -- Load model
    local model = joaat(modelName)
    RequestModel(model)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
        Wait(0)
        if GetGameTimer() > timeout then
            print('^1[ZDX]^0 Model load timed out, using fallback.')
            model = joaat('mp_m_freemode_01')
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(0) end
            break
        end
    end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    ped = PlayerPedId()

    -- Teleport
    SetEntityCoordsNoOffset(ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
    SetEntityHeading(ped, spawnCoords.w or 0.0)

    -- Freeze during load
    FreezeEntityPosition(ped, true)

    -- Kill native loading screens
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    -- End the tutorial / "awaiting scripts" session
    NetworkEndTutorialSession()
    while NetworkIsInTutorialSession() do
        Wait(0)
    end

    -- Store player data
    ZDX.PlayerData = playerData or {}
    ZDX.IsLoggedIn = true

    -- Apply skin if using illenium-appearance
    if Config.UseAppearanceOnFirstSpawn and Config.AppearanceResource == 'illenium-appearance' then
        if ZDX.PlayerData.skin and next(ZDX.PlayerData.skin) ~= nil then
            exports['illenium-appearance']:setPedAppearance(ped, ZDX.PlayerData.skin)
        end
    end

    -- Let server know we're fully loaded
    TriggerServerEvent('zdx_core:server:playerLoaded')

    -- Cinematic fade in
    Wait(500)
    FreezeEntityPosition(ped, false)
    DoScreenFadeIn(1000)

    -- PVP
    if GlobalState.PVPEnabled then
        SetCanAttackFriendly(ped, true, false)
        NetworkSetFriendlyFireOption(true)
    end

    -- ══════════════════════════════════════════════════════════
    -- FIRE ZDX NATIVE LOAD EVENT
    -- Bridges listen for this and fire ESX/QB events
    -- ══════════════════════════════════════════════════════════
    TriggerEvent('zdx:playerLoaded', ZDX.PlayerData)

    -- State bag
    LocalPlayer.state:set('isLoggedIn', true, false)
end)

-- ══════════════════════════════════════════════════════════════
-- APPEARANCE CREATION
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('zdx_core:client:openAppearance', function()
    -- Fade out
    DoScreenFadeOut(0)

    local ped = PlayerPedId()

    -- Spawn default male freemode ped
    local model = joaat('mp_m_freemode_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    ped = PlayerPedId()
    
    -- Setup coords for ped creation (can be configured if needed, using default for now)
    local createCoords = Config.DefaultSpawn
    SetEntityCoordsNoOffset(ped, createCoords.x, createCoords.y, createCoords.z, false, false, false, true)
    SetEntityHeading(ped, createCoords.w or 0.0)

    -- Kill native loading screens
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    NetworkEndTutorialSession()
    while NetworkIsInTutorialSession() do Wait(0) end

    DoScreenFadeIn(1000)

    -- Initialize illenium-appearance character creation
    if Config.AppearanceResource == 'illenium-appearance' then
        local config = {
            ped = true,
            headBlend = true,
            faceFeatures = true,
            headOverlays = true,
            components = true,
            props = true,
            allowExit = false
        }
        
        exports['illenium-appearance']:startPlayerCustomization(function(appearance)
            if appearance then
                TriggerServerEvent('zdx_core:server:saveAppearance', appearance)
                TriggerServerEvent('zdx_core:server:appearanceDone')
            end
        end, config)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- ZDX PLAYER DATA SYNC
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('zdx:client:playerDataUpdate', function(val)
    local invokingResource = GetInvokingResource()
    if invokingResource and invokingResource ~= GetCurrentResourceName() then return end
    ZDX.PlayerData = val
end)

RegisterNetEvent('zdx:client:playerUnloaded', function()
    ZDX.IsLoggedIn = false
    ZDX.PlayerData = {}
end)

RegisterNetEvent('zdx:client:jobUpdate', function(jobInfo)
    if ZDX.PlayerData then
        ZDX.PlayerData.job = jobInfo
    end
end)

RegisterNetEvent('zdx:client:gangUpdate', function(gangInfo)
    if ZDX.PlayerData then
        ZDX.PlayerData.gang = gangInfo
    end
end)

RegisterNetEvent('zdx:client:moneyChange', function(moneyType, amount, changeType, reason)
    -- Other scripts can listen to this for UI updates, etc.
end)

-- ══════════════════════════════════════════════════════════════
-- TELEPORT HANDLERS
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('zdx_core:client:teleport', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
end)

RegisterNetEvent('zdx_core:client:teleportToWaypoint', function()
    local ped = PlayerPedId()
    local waypointBlip = GetFirstBlipInfoId(8)

    if DoesBlipExist(waypointBlip) then
        DoScreenFadeOut(500)
        Wait(500)

        local waypointCoords = GetBlipInfoIdCoord(waypointBlip)

        for i = 950.0, 0.0, -25.0 do
            SetEntityCoordsNoOffset(ped, waypointCoords.x, waypointCoords.y, i, false, false, false)
            Wait(50)
            local found, groundZ = GetGroundZFor_3dCoord(waypointCoords.x, waypointCoords.y, i, false)
            if found then
                SetEntityCoordsNoOffset(ped, waypointCoords.x, waypointCoords.y, groundZ, false, false, false)
                break
            end
        end

        DoScreenFadeIn(500)
    else
        TriggerEvent('chat:addMessage', { args = { '^1SYSTEM', 'No waypoint set.' } })
    end
end)

-- ══════════════════════════════════════════════════════════════
-- MODEL CHANGE
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('zdx_core:client:setModel', function(modelName)
    local model = joaat(modelName)
    if IsModelInCdimage(model) and IsModelValid(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
    else
        TriggerEvent('chat:addMessage', { args = { '^1SYSTEM', 'Invalid model.' } })
    end
end)

-- ══════════════════════════════════════════════════════════════
-- ZDX NOTIFICATION HANDLER
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('zdx:showNotification', function(msg, nType, duration)
    -- Use zdx_notify if available, otherwise fallback to native
    if GetResourceState('zdx_notify') == 'started' then
        exports['zdx_notify']:Notify(nType or 'info', duration or 5000, msg)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(tostring(msg))
        DrawNotification(false, true)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- PVP STATE HANDLER
-- ══════════════════════════════════════════════════════════════

AddStateBagChangeHandler('PVPEnabled', nil, function(bagName, _, value)
    if bagName == 'global' then
        SetCanAttackFriendly(PlayerPedId(), value, false)
        NetworkSetFriendlyFireOption(value)
    end
end)
