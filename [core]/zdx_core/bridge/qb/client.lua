-- ══════════════════════════════════════════════════════════════
-- ZDX Core: QBCore Client Bridge
-- Provides full QB-Core / QBox client compatibility so QB scripts
-- can run without modification on zdx-core.
-- ══════════════════════════════════════════════════════════════

QBCore = {}
QBCore.Config = Config
QBCore.Shared = {}
QBCore.Shared.Jobs = Config.Jobs
QBCore.Shared.Gangs = Config.Gangs
QBCore.Shared.Items = {}
QBCore.Shared.Vehicles = {}
QBCore.Shared.Weapons = {}
QBCore.Shared.Locations = {}

QBCore.PlayerData = {}
QBCore.Functions = {}
QBCore.ClientCallbacks = {}
QBCore.ServerCallbacks = {}

-- ══════════════════════════════════════════════════════════════
-- CORE OBJECT EXPORT
-- ══════════════════════════════════════════════════════════════

local function getCoreObject()
    return QBCore
end

exports('GetCoreObject', getCoreObject)

-- ══════════════════════════════════════════════════════════════
-- PLAYER DATA
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.GetPlayerData(cb)
    local data = ZDX.PlayerData or QBCore.PlayerData
    if cb then cb(data) end
    return data
end

-- Sync QB PlayerData with ZDX
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.PlayerData = ZDX.PlayerData or {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    QBCore.PlayerData = val
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    QBCore.PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    QBCore.PlayerData.job = jobInfo
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gangInfo)
    QBCore.PlayerData.gang = gangInfo
end)

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS (QBCore Style)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.CreateClientCallback(name, cb)
    QBCore.ClientCallbacks[name] = cb
end

function QBCore.Functions.TriggerClientCallback(name, cb, ...)
    if QBCore.ClientCallbacks[name] then
        QBCore.ClientCallbacks[name](cb, ...)
    end
end

function QBCore.Functions.TriggerCallback(name, cb, ...)
    QBCore.ServerCallbacks[name] = cb
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, ...)
end

RegisterNetEvent('QBCore:Client:TriggerCallback', function(name, ...)
    if QBCore.ServerCallbacks[name] then
        QBCore.ServerCallbacks[name](...)
        QBCore.ServerCallbacks[name] = nil
    end
end)

RegisterNetEvent('QBCore:Client:TriggerClientCallback', function(name, ...)
    if QBCore.ClientCallbacks[name] then
        QBCore.ClientCallbacks[name](function(...)
            TriggerServerEvent('QBCore:Server:TriggerClientCallback', name, ...)
        end, ...)
    end
end)

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATION
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.Notify(text, nType, duration)
    SetNotificationTextEntry('STRING')
    if type(text) == 'table' then
        AddTextComponentString(text.text or text.caption or 'Notification')
    else
        AddTextComponentString(tostring(text))
    end
    DrawNotification(false, true)
end

-- ══════════════════════════════════════════════════════════════
-- VEHICLE UTILITIES
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.SpawnVehicle(model, cb, coords, isNetwork, teleportInto)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local ped = PlayerPedId()
    coords = coords or GetEntityCoords(ped)

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, GetEntityHeading(ped), isNetwork ~= false, false)
    SetModelAsNoLongerNeeded(hash)

    if teleportInto then
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
    end

    if cb then cb(vehicle) end
end

function QBCore.Functions.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

function QBCore.Functions.GetClosestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestDist = -1
    local closestVeh = -1
    coords = coords or GetEntityCoords(PlayerPedId())
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

function QBCore.Functions.GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        return {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            color1 = {GetVehicleColours(vehicle)},
        }
    end
    return {}
end

function QBCore.Functions.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) then return end
    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
end

function QBCore.Functions.GetPlate(vehicle)
    if vehicle and vehicle ~= 0 then
        return string.gsub(GetVehicleNumberPlateText(vehicle), '^%s+', ''):gsub('%s+$', '')
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════
-- PED / PLAYER UTILITIES
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.GetClosestPlayer(coords)
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

function QBCore.Functions.GetPlayersFromCoords(coords, maxDist)
    local players = {}
    local myPed = PlayerPedId()
    coords = coords or GetEntityCoords(myPed)
    maxDist = maxDist or 5.0
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= myPed then
            local pedCoords = GetEntityCoords(ped)
            if #(coords - pedCoords) <= maxDist then
                players[#players+1] = playerId
            end
        end
    end
    return players
end

-- ══════════════════════════════════════════════════════════════
-- PROGRESS BAR (Stub)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    -- Stub: wait for duration then fire callback
    CreateThread(function()
        Wait(duration)
        if onFinish then onFinish() end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG
-- ══════════════════════════════════════════════════════════════

function QBCore.Debug(_, obj)
    print(json.encode(obj, { indent = true }))
end

-- ══════════════════════════════════════════════════════════════
-- HAS KEYS (Vehicle Keys compat stub)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.HasKeys(plate, vehicle)
    return true -- Cinematic: always has keys
end

print('^2[ZDX-CORE]^0 QBCore Client Bridge loaded.')
