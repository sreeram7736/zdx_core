-- ══════════════════════════════════════════════════════════════
-- ZDX Core: Client Main
-- Handles spawning, model loading, and fires framework load events
-- NO "awaiting script" - we handle everything natively.
-- ══════════════════════════════════════════════════════════════

ZDX = ZDX or {}
ZDX.PlayerData = {}
ZDX.IsLoggedIn = false

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
            print('^1[ZDX-CORE]^0 Model load timed out, using fallback.')
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
    -- FIRE FRAMEWORK LOAD EVENTS (ESX & QB Compat)
    -- ══════════════════════════════════════════════════════════

    -- QB / QBox
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    -- ESX
    TriggerEvent('esx:playerLoaded', ZDX.PlayerData, false, {})

    -- QB statebag
    LocalPlayer.state:set('isLoggedIn', true, false)
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER DATA SYNC
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    local invokingResource = GetInvokingResource()
    if invokingResource and invokingResource ~= GetCurrentResourceName() then return end
    ZDX.PlayerData = val
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ZDX.IsLoggedIn = false
    ZDX.PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    if ZDX.PlayerData then
        ZDX.PlayerData.job = jobInfo
    end
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gangInfo)
    if ZDX.PlayerData then
        ZDX.PlayerData.gang = gangInfo
    end
end)

RegisterNetEvent('QBCore:Client:OnMoneyChange', function(moneyType, amount, changeType, reason)
    -- Other scripts can listen to this
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
-- ESX NOTIFICATION HANDLER
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('esx:showNotification', function(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, true)
end)

-- ══════════════════════════════════════════════════════════════
-- QB NOTIFICATION HANDLER
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('QBCore:Notify', function(text, nType, duration)
    SetNotificationTextEntry('STRING')
    if type(text) == 'table' then
        AddTextComponentString(text.text or 'Notification')
    else
        AddTextComponentString(tostring(text))
    end
    DrawNotification(false, true)
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
