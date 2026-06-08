-- ══════════════════════════════════════════════════════════════
-- ZDX Core: ESX Client Bridge
-- Provides full ESX client compatibility so ESX scripts
-- can run without modification on zdx-core.
-- ══════════════════════════════════════════════════════════════

ESX = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false

ESX.playerId = PlayerId()
ESX.serverId = GetPlayerServerId(ESX.playerId)

ESX.UI = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

-- ══════════════════════════════════════════════════════════════
-- SHARED OBJECT
-- ══════════════════════════════════════════════════════════════

local function getSharedObject()
    return ESX
end

exports('getSharedObject', getSharedObject)

-- Also handle the old-style event callback
AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER LOAD
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('esx:playerLoaded', function(playerData, isNew, skin)
    ESX.PlayerData = playerData or ZDX.PlayerData
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER DATA FUNCTIONS
-- ══════════════════════════════════════════════════════════════

function ESX.GetPlayerData()
    return ZDX.PlayerData or ESX.PlayerData
end

function ESX.IsPlayerLoaded()
    return ZDX.IsLoggedIn or ESX.PlayerLoaded
end

function ESX.SetPlayerData(key, value)
    ESX.PlayerData[key] = value
end

-- ══════════════════════════════════════════════════════════════
-- SERVER CALLBACK (ESX Style)
-- ══════════════════════════════════════════════════════════════

ESX.ServerCallbacks = {}

function ESX.TriggerServerCallback(name, cb, ...)
    local requestId = name
    ESX.ServerCallbacks[requestId] = cb
    TriggerServerEvent(('esx_callback:%s'):format(name), ...)
end

RegisterNetEvent('esx_callback_response', function(name, ...)
    if ESX.ServerCallbacks[name] then
        ESX.ServerCallbacks[name](...)
        ESX.ServerCallbacks[name] = nil
    end
end)

-- Generic fallback for any esx_callback_response:* event
AddEventHandler('esx_callback_response', function(...)
    -- handled above
end)

-- ══════════════════════════════════════════════════════════════
-- GAME UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════

function ESX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(tostring(msg))
    DrawNotification(flash or false, saveToBrief or true)
end

function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    if thisFrame then
        AddTextEntry('esxHelpNotification', msg)
        DisplayHelpTextThisFrame('esxHelpNotification', false)
    else
        BeginTextCommandDisplayHelp('esxHelpNotification')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, beep or false, duration or 5000)
    end
end

function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if hudColorIndex then ThefeedSetNextPostBackgroundColor(hudColorIndex) end
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    SetNotificationMessage(textureDict or 'CHAR_DEFAULT', textureDict or 'CHAR_DEFAULT', flash or false, iconType or 1, sender or 'System', subject or '')
    DrawNotification(false, saveToBrief or true)
end

-- ══════════════════════════════════════════════════════════════
-- GAME FUNCTIONS
-- ══════════════════════════════════════════════════════════════

function ESX.Game.GetPedMugshot(ped, transparent)
    if transparent then
        return RegisterPedheadshotTransparent(ped)
    end
    return RegisterPedheadshot(ped)
end

function ESX.Game.Teleport(entity, coords, cb)
    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, true)
    if coords.heading then
        SetEntityHeading(entity, coords.heading)
    end
    if cb then cb() end
end

function ESX.Game.SpawnLocalVehicle(model, coords, heading, cb)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading or 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)
    if cb then cb(vehicle) end
end

function ESX.Game.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function ESX.Game.GetClosestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestDist = -1
    local closestVeh = -1
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(coords - vehCoords)
        if closestDist == -1 or dist < closestDist then
            closestDist = dist
            closestVeh = vehicle
        end
    end
    return closestVeh, closestDist
end

function ESX.Game.GetClosestPlayer(coords)
    local players = GetActivePlayers()
    local closestDist = -1
    local closestPlayer = -1
    local myPed = PlayerPedId()
    coords = coords or GetEntityCoords(myPed)
    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        if ped ~= myPed then
            local pedCoords = GetEntityCoords(ped)
            local dist = #(coords - pedCoords)
            if closestDist == -1 or dist < closestDist then
                closestDist = dist
                closestPlayer = playerId
            end
        end
    end
    return closestPlayer, closestDist
end

function ESX.Game.GetPlayersInArea(coords, maxDistance)
    local players = {}
    local myPed = PlayerPedId()
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= myPed then
            local pedCoords = GetEntityCoords(ped)
            if #(coords - pedCoords) <= maxDistance then
                players[#players+1] = playerId
            end
        end
    end
    return players
end

function ESX.Game.GetVehiclesInArea(coords, maxDistance)
    local vehicles = {}
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        local vehCoords = GetEntityCoords(vehicle)
        if #(coords - vehCoords) <= maxDistance then
            vehicles[#vehicles+1] = vehicle
        end
    end
    return vehicles
end

function ESX.Game.GetVehicleInDirection()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwdVector = GetEntityForwardVector(ped)
    local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z, coords.x + fwdVector.x * 5, coords.y + fwdVector.y * 5, coords.z + fwdVector.z * 5, 10, ped, 0)
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    return vehicle
end

function ESX.Game.GetClosestObject(coords, filter)
    local objects = GetGamePool('CObject')
    local closestDist = -1
    local closestObj = -1
    for _, obj in ipairs(objects) do
        local objCoords = GetEntityCoords(obj)
        local dist = #(coords - objCoords)
        if closestDist == -1 or dist < closestDist then
            if not filter or filter[GetEntityModel(obj)] then
                closestDist = dist
                closestObj = obj
            end
        end
    end
    return closestObj, closestDist
end

function ESX.Game.GetClosestPed(coords, ignoreList)
    local peds = GetGamePool('CPed')
    local closestDist = -1
    local closestPed = -1
    local myPed = PlayerPedId()
    coords = coords or GetEntityCoords(myPed)
    for _, ped in ipairs(peds) do
        if ped ~= myPed and (not ignoreList or not ignoreList[ped]) then
            local pedCoords = GetEntityCoords(ped)
            local dist = #(coords - pedCoords)
            if closestDist == -1 or dist < closestDist then
                closestDist = dist
                closestPed = ped
            end
        end
    end
    return closestPed, closestDist
end

-- ══════════════════════════════════════════════════════════════
-- STREAMING
-- ══════════════════════════════════════════════════════════════

function ESX.Streaming.RequestModel(model, cb)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    if cb then cb() end
end

function ESX.Streaming.RequestAnimDict(animDict, cb)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(0) end
    if cb then cb() end
end

function ESX.Streaming.RequestAnimSet(animSet, cb)
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do Wait(0) end
    if cb then cb() end
end

function ESX.Streaming.RequestTextureDict(textureDict, cb)
    RequestStreamedTextureDict(textureDict)
    while not HasStreamedTextureDictLoaded(textureDict) do Wait(0) end
    if cb then cb() end
end

function ESX.Streaming.RequestNamedPtfxAsset(ptfxName, cb)
    RequestNamedPtfxAsset(ptfxName)
    while not HasNamedPtfxAssetLoaded(ptfxName) do Wait(0) end
    if cb then cb() end
end

-- ══════════════════════════════════════════════════════════════
-- SCALEFORM
-- ══════════════════════════════════════════════════════════════

function ESX.Scaleform.ShowFreemodeMessage(title, msg, sec)
    local scaleform = RequestScaleformMovie('MP_BIG_MESSAGE_FREEMODE')
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end
    BeginScaleformMovieMethod(scaleform, 'SHOW_SHARD_WASTED_MP_MESSAGE')
    ScaleformMovieMethodAddParamTextureNameString(title)
    ScaleformMovieMethodAddParamTextureNameString(msg)
    EndScaleformMovieMethod()
    local endTime = GetGameTimer() + (sec or 5) * 1000
    while GetGameTimer() < endTime do
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
        Wait(0)
    end
end

-- ══════════════════════════════════════════════════════════════
-- DISABLE SPAWN MANAGER (prevent "awaiting scripts")
-- ══════════════════════════════════════════════════════════════

function ESX.DisableSpawnManager()
    -- No spawnmanager to disable; zdx handles it natively
end

-- ══════════════════════════════════════════════════════════════
-- Math / Table / Streaming / Scaleform namespaces init
-- ══════════════════════════════════════════════════════════════

ESX.Math = {}
function ESX.Math.Round(num, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(num + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((num * power) + 0.5) / power
end

function ESX.Math.GroupDigits(value)
    local left, num, right = string.match(tostring(value), '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

ESX.Table = {}
function ESX.Table.Clone(t)
    local clone = {}
    for k, v in pairs(t) do
        clone[k] = type(v) == 'table' and ESX.Table.Clone(v) or v
    end
    return clone
end

ESX.Streaming = ESX.Streaming or {}
ESX.Scaleform = ESX.Scaleform or {}

print('^2[ZDX-CORE]^0 ESX Client Bridge loaded.')
