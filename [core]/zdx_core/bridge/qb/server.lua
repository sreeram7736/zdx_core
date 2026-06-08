-- ══════════════════════════════════════════════════════════════
-- ZDX Core: QBCore Server Bridge
-- Provides full QB-Core / QBox compatibility so QB scripts
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
QBCore.Shared.ForceJobDefaultDutyAtLogin = false

QBCore.Players = ZDX.Players
QBCore.Player_Buckets = {}
QBCore.Entity_Buckets = {}
QBCore.UsableItems = {}
QBCore.Functions = {}
QBCore.Commands = {}
QBCore.ServerCallbacks = {}
QBCore.ClientCallbacks = {}

-- ══════════════════════════════════════════════════════════════
-- CORE OBJECT EXPORT
-- ══════════════════════════════════════════════════════════════

local function getCoreObject()
    return QBCore
end

exports('GetCoreObject', getCoreObject)

-- ══════════════════════════════════════════════════════════════
-- PLAYER FUNCTIONS
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.GetPlayer(source)
    return GetZDXPlayer(source)
end

function QBCore.Functions.GetPlayerByCitizenId(citizenid)
    return GetZDXPlayerByCitizenId(citizenid)
end

function QBCore.Functions.GetPlayerByPhone(phone)
    for _, player in pairs(ZDX.Players) do
        if player.charinfo and player.charinfo.phone == phone then
            return player
        end
    end
    return nil
end

function QBCore.Functions.GetPlayers()
    local sources = {}
    for src in pairs(ZDX.Players) do
        sources[#sources+1] = src
    end
    return sources
end

function QBCore.Functions.GetQBPlayers()
    return ZDX.Players
end

function QBCore.Functions.GetPlayersOnDuty(job)
    local players = {}
    local count = 0
    for src, player in pairs(ZDX.Players) do
        if player.job.name == job and player.job.onduty then
            players[#players+1] = src
            count = count + 1
        end
    end
    return count, players
end

function QBCore.Functions.GetDutyCount(job)
    local count, _ = QBCore.Functions.GetPlayersOnDuty(job)
    return count
end

-- ══════════════════════════════════════════════════════════════
-- ROUTING BUCKETS
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.SetPlayerBucket(source, bucket)
    SetPlayerRoutingBucket(tostring(source), bucket)
    QBCore.Player_Buckets[source] = bucket
    return true
end

function QBCore.Functions.SetEntityBucket(entity, bucket)
    SetEntityRoutingBucket(entity, bucket)
    QBCore.Entity_Buckets[entity] = bucket
    return true
end

function QBCore.Functions.GetPlayersInBucket(bucket)
    local players = {}
    for k, v in pairs(QBCore.Player_Buckets) do
        if v == bucket then players[#players+1] = k end
    end
    return players
end

function QBCore.Functions.GetEntitiesInBucket(bucket)
    local entities = {}
    for k, v in pairs(QBCore.Entity_Buckets) do
        if v == bucket then entities[#entities+1] = k end
    end
    return entities
end

-- ══════════════════════════════════════════════════════════════
-- USEABLE ITEMS
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.CreateUseableItem(item, data)
    QBCore.UsableItems[item] = data
end

function QBCore.Functions.CanUseItem(item)
    return QBCore.UsableItems[item]
end

function QBCore.Functions.UseItem(source, item)
    if QBCore.UsableItems[item] then
        QBCore.UsableItems[item](source, item)
    end
end

-- ══════════════════════════════════════════════════════════════
-- SERVER CALLBACKS (QBCore Style)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.CreateCallback(name, cb)
    QBCore.ServerCallbacks[name] = cb
end

function QBCore.Functions.TriggerCallback(name, source, cb, ...)
    if QBCore.ServerCallbacks[name] then
        QBCore.ServerCallbacks[name](source, cb, ...)
    end
end

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, ...)
    local src = source
    if QBCore.ServerCallbacks[name] then
        QBCore.ServerCallbacks[name](src, function(...)
            TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, ...)
        end, ...)
    end
end)

RegisterNetEvent('QBCore:Server:TriggerClientCallback', function(name, ...)
    if QBCore.ClientCallbacks[name] then
        QBCore.ClientCallbacks[name](...)
        QBCore.ClientCallbacks[name] = nil
    end
end)

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATION
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.Notify(source, text, nType, duration)
    TriggerClientEvent('QBCore:Notify', source, text, nType, duration)
end

-- ══════════════════════════════════════════════════════════════
-- PERMISSION
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.HasPermission(source, permission)
    if type(permission) == 'string' then
        return IsPlayerAceAllowed(tostring(source), permission)
    elseif type(permission) == 'table' then
        for _, p in pairs(permission) do
            if IsPlayerAceAllowed(tostring(source), p) then return true end
        end
    end
    return false
end

function QBCore.Functions.AddPermission(source, permission)
    ExecuteCommand(('add_principal player.%s group.%s'):format(source, permission))
end

function QBCore.Functions.RemovePermission(source, permission)
    ExecuteCommand(('remove_principal player.%s group.%s'):format(source, permission))
end

function QBCore.Functions.IsOptin(source)
    return QBCore.Functions.HasPermission(source, 'admin')
end

-- ══════════════════════════════════════════════════════════════
-- VEHICLE UTILITIES
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.SpawnVehicle(source, model, coords, warp)
    local hash = type(model) == 'number' and model or joaat(model)
    local veh = CreateVehicleServerSetter(hash, 'automobile', coords.x, coords.y, coords.z, coords.w or 0.0)
    while not DoesEntityExist(veh) do Wait(0) end
    if warp then
        local ped = GetPlayerPed(source)
        SetPedIntoVehicle(ped, veh, -1)
    end
    return veh
end

function QBCore.Functions.CreateVehicle(source, model, vehType, coords, warp)
    return QBCore.Functions.SpawnVehicle(source, model, coords, warp)
end

function QBCore.Functions.DeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end

-- ══════════════════════════════════════════════════════════════
-- BAN / KICK
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.Kick(source, reason, setKickReason, deferrals)
    DropPlayer(tostring(source), reason or 'Kicked')
end

-- ══════════════════════════════════════════════════════════════
-- MISC
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.GetIdentifier(source, idType)
    return GetPlayerIdentifierByType(tostring(source), idType or 'license')
end

function QBCore.Functions.GetSource(identifier)
    for src, player in pairs(ZDX.Players) do
        if player.identifier == identifier then
            return src
        end
    end
    return 0
end

function QBCore.Functions.GetCoreVersion()
    return '1.0.0'
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG
-- ══════════════════════════════════════════════════════════════

function QBCore.Debug(_, obj)
    print(json.encode(obj, { indent = true }))
end

QBCore.ShowError = print
QBCore.ShowSuccess = print

-- ══════════════════════════════════════════════════════════════
-- SHARED DATA HELPERS
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.GetJobs()
    return Config.Jobs
end

function QBCore.Functions.GetGangs()
    return Config.Gangs
end

-- Sync with ZDX.Players on every update
AddEventHandler('QBCore:Server:PlayerLoaded', function(zdxPlayer)
    QBCore.Players = ZDX.Players
end)

print('^2[ZDX-CORE]^0 QBCore Server Bridge loaded.')
