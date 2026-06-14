-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Server API
-- The core API object for the ZDX custom framework.
-- All server-side scripts should use this instead of ESX/QB.
--
-- Usage from other resources:
--   local ZDX = exports['zdx_core']:GetCoreObject()
--   local player = ZDX.GetPlayer(source)
-- ══════════════════════════════════════════════════════════════

ZDX = ZDX or {}
ZDX.Players = ZDX.Players or {}
ZDX.Jobs = Config.Jobs
ZDX.Gangs = Config.Gangs
ZDX.Items = {}
ZDX.UsableItems = {}
ZDX.Pickups = {}
ZDX.RegisteredCommands = {}

-- ══════════════════════════════════════════════════════════════
-- CORE OBJECT EXPORT
-- ══════════════════════════════════════════════════════════════

-- Export moved to the end of the loading sequence to ensure all functions are attached


-- ══════════════════════════════════════════════════════════════
-- PLAYER FUNCTIONS
-- ══════════════════════════════════════════════════════════════

--- Get a player by server source id
---@param source number
---@return table|nil
function ZDX.GetPlayer(source)
    return GetZDXPlayer(source)
end

--- Get a player by their identifier
---@param identifier string
---@return table|nil
function ZDX.GetPlayerByIdentifier(identifier)
    return GetZDXPlayerByIdentifier(identifier)
end

--- Get a player by their citizen id
---@param citizenid string
---@return table|nil
function ZDX.GetPlayerByCitizenId(citizenid)
    return GetZDXPlayerByCitizenId(citizenid)
end

--- Get all player source IDs
---@return table
function ZDX.GetPlayers()
    local sources = {}
    for src in pairs(ZDX.Players) do
        sources[#sources + 1] = src
    end
    return sources
end

--- Get all extended player objects, optionally filtered
---@param key string|nil  Filter key ('job' or 'group')
---@param val string|nil  Filter value
---@return table
function ZDX.GetExtendedPlayers(key, val)
    local players = {}
    for _, zdxPlayer in pairs(ZDX.Players) do
        if key then
            if key == 'job' and zdxPlayer.job.name == val then
                players[#players + 1] = zdxPlayer
            elseif key == 'group' and (zdxPlayer.metadata.group or 'user') == val then
                players[#players + 1] = zdxPlayer
            end
        else
            players[#players + 1] = zdxPlayer
        end
    end
    return players
end

--- Get players on duty for a specific job
---@param job string
---@return number count, table players
function ZDX.GetPlayersOnDuty(job)
    local players = {}
    local count = 0
    for src, player in pairs(ZDX.Players) do
        if player.job.name == job and player.job.onduty then
            players[#players + 1] = src
            count = count + 1
        end
    end
    return count, players
end

-- ══════════════════════════════════════════════════════════════
-- JOB FUNCTIONS
-- ══════════════════════════════════════════════════════════════

--- Check if a job and grade exists
---@param job string
---@param grade string|number
---@return boolean
function ZDX.DoesJobExist(job, grade)
    grade = tonumber(grade) or 0
    if Config.Jobs[job] and Config.Jobs[job].grades[grade] then
        return true
    end
    return false
end

-- ══════════════════════════════════════════════════════════════
-- USABLE ITEMS
-- ══════════════════════════════════════════════════════════════

--- Register a usable item
---@param item string
---@param cb function
function ZDX.RegisterUsableItem(item, cb)
    ZDX.UsableItems[item] = cb
end

--- Use an item
---@param source number
---@param item string
function ZDX.UseItem(source, item)
    if ZDX.UsableItems[item] then
        ZDX.UsableItems[item](source, item)
    end
end

--- Check if an item is usable
---@param item string
---@return function|nil
function ZDX.CanUseItem(item)
    return ZDX.UsableItems[item]
end

--- Get item label
---@param item string
---@return string
function ZDX.GetItemLabel(item)
    if ZDX.Items[item] then
        return ZDX.Items[item].label
    end
    return item
end

-- ══════════════════════════════════════════════════════════════
-- IDENTIFIER FUNCTIONS
-- ══════════════════════════════════════════════════════════════

--- Get a player's license identifier
---@param source number
---@return string|nil
function ZDX.GetIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license2') or GetPlayerIdentifierByType(source, 'license')
end

--- Get source from identifier
---@param identifier string
---@return number
function ZDX.GetSource(identifier)
    for src, player in pairs(ZDX.Players) do
        if player.identifier == identifier then
            return src
        end
    end
    return 0
end

-- ══════════════════════════════════════════════════════════════
-- ADMIN FUNCTIONS
-- ══════════════════════════════════════════════════════════════

--- Check if a player is admin
---@param source number
---@return boolean
function ZDX.IsPlayerAdmin(source)
    return IsPlayerAceAllowed(tostring(source), 'command')
end

--- Check if a player has a specific permission
---@param source number
---@param permission string|table
---@return boolean
function ZDX.HasPermission(source, permission)
    if type(permission) == 'string' then
        return IsPlayerAceAllowed(tostring(source), permission)
    elseif type(permission) == 'table' then
        for _, p in pairs(permission) do
            if IsPlayerAceAllowed(tostring(source), p) then return true end
        end
    end
    return false
end

--- Add a permission to a player
---@param source number
---@param permission string
function ZDX.AddPermission(source, permission)
    ExecuteCommand(('add_principal player.%s group.%s'):format(source, permission))
end

--- Remove a permission from a player
---@param source number
---@param permission string
function ZDX.RemovePermission(source, permission)
    ExecuteCommand(('remove_principal player.%s group.%s'):format(source, permission))
end

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATION
-- ══════════════════════════════════════════════════════════════

--- Send a notification to a player
---@param source number
---@param msg string
---@param nType string|nil
---@param duration number|nil
function ZDX.Notify(source, msg, nType, duration)
    TriggerClientEvent('zdx:showNotification', source, msg, nType or 'info', duration or 5000)
end

-- ══════════════════════════════════════════════════════════════
-- VEHICLE UTILITIES
-- ══════════════════════════════════════════════════════════════

--- Spawn a vehicle via OneSync
---@param model string|number
---@param coords vector3
---@param heading number
---@param props table|nil
---@param cb function|nil
---@return number netId
function ZDX.SpawnVehicle(source, model, coords, heading, cb)
    local hash = type(model) == 'number' and model or joaat(model)
    local veh = CreateVehicleServerSetter(hash, 'automobile', coords.x, coords.y, coords.z, heading or 0.0)
    while not DoesEntityExist(veh) do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if cb then cb(netId) end
    return netId
end

--- Delete a vehicle
---@param vehicle number
function ZDX.DeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
end

-- ══════════════════════════════════════════════════════════════
-- ONESYNC UTILITIES
-- ══════════════════════════════════════════════════════════════

ZDX.OneSync = {}

function ZDX.OneSync.SpawnVehicle(model, coords, heading, props, cb)
    local hash = type(model) == 'number' and model or joaat(model)
    local veh = CreateVehicleServerSetter(hash, 'automobile', coords.x, coords.y, coords.z, heading or 0.0)
    while not DoesEntityExist(veh) do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if cb then cb(netId) end
    return netId
end

function ZDX.OneSync.GetPlayersInArea(coords, maxDistance)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(ped)
        if #(playerCoords - coords) <= maxDistance then
            players[#players + 1] = tonumber(playerId)
        end
    end
    return players
end

function ZDX.OneSync.GetPedsInArea(coords, maxDistance)
    local peds = {}
    for _, ped in ipairs(GetAllPeds()) do
        local pedCoords = GetEntityCoords(ped)
        if #(pedCoords - coords) <= maxDistance then
            peds[#peds + 1] = ped
        end
    end
    return peds
end

function ZDX.OneSync.GetVehiclesInArea(coords, maxDistance)
    local vehicles = {}
    for _, veh in ipairs(GetAllVehicles()) do
        local vehCoords = GetEntityCoords(veh)
        if #(vehCoords - coords) <= maxDistance then
            vehicles[#vehicles + 1] = veh
        end
    end
    return vehicles
end

-- ══════════════════════════════════════════════════════════════
-- SAVE UTILITIES
-- ══════════════════════════════════════════════════════════════

--- Save a single player
---@param zdxPlayer table
---@param cb function|nil
function ZDX.SavePlayer(zdxPlayer, cb)
    if zdxPlayer and zdxPlayer.Functions then
        zdxPlayer.Functions.Save()
    end
    if cb then cb() end
end

--- Save all online players
function ZDX.SavePlayers()
    for _, zdxPlayer in pairs(ZDX.Players) do
        zdxPlayer.Functions.Save()
    end
end

-- ══════════════════════════════════════════════════════════════
-- KICK
-- ══════════════════════════════════════════════════════════════

--- Kick a player
---@param source number
---@param reason string|nil
function ZDX.Kick(source, reason)
    DropPlayer(tostring(source), reason or 'Kicked by ZDX')
end

-- ══════════════════════════════════════════════════════════════
-- ROUTING BUCKETS
-- ══════════════════════════════════════════════════════════════

ZDX.Buckets = {}
ZDX.Buckets.Players = {}
ZDX.Buckets.Entities = {}

function ZDX.SetPlayerBucket(source, bucket)
    SetPlayerRoutingBucket(tostring(source), bucket)
    ZDX.Buckets.Players[source] = bucket
    return true
end

function ZDX.SetEntityBucket(entity, bucket)
    SetEntityRoutingBucket(entity, bucket)
    ZDX.Buckets.Entities[entity] = bucket
    return true
end

function ZDX.GetPlayersInBucket(bucket)
    local players = {}
    for k, v in pairs(ZDX.Buckets.Players) do
        if v == bucket then players[#players + 1] = k end
    end
    return players
end

function ZDX.GetEntitiesInBucket(bucket)
    local entities = {}
    for k, v in pairs(ZDX.Buckets.Entities) do
        if v == bucket then entities[#entities + 1] = k end
    end
    return entities
end

-- ══════════════════════════════════════════════════════════════
-- MATH UTILITIES
-- ══════════════════════════════════════════════════════════════

ZDX.Math = {}

function ZDX.Math.Round(num, numDecimalPlaces)
    if not numDecimalPlaces then return math.floor(num + 0.5) end
    local power = 10 ^ numDecimalPlaces
    return math.floor((num * power) + 0.5) / power
end

function ZDX.Math.GroupDigits(value)
    local left, num, right = string.match(tostring(value), '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

function ZDX.Math.Random(lowest, highest)
    return math.random(lowest, highest)
end

-- ══════════════════════════════════════════════════════════════
-- TABLE UTILITIES
-- ══════════════════════════════════════════════════════════════

ZDX.Table = {}

function ZDX.Table.Clone(t)
    if type(t) ~= 'table' then return t end
    local clone = {}
    for k, v in pairs(t) do
        clone[k] = type(v) == 'table' and ZDX.Table.Clone(v) or v
    end
    return clone
end

function ZDX.Table.Contains(t, value)
    for _, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

function ZDX.Table.Count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function ZDX.Table.Merge(t1, t2)
    local result = ZDX.Table.Clone(t1)
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG
-- ══════════════════════════════════════════════════════════════

function ZDX.Debug(resource, obj)
    print(('[^3ZDX-DEBUG^0] [%s]'):format(resource or 'unknown'))
    print(json.encode(obj, { indent = true }))
end

-- ══════════════════════════════════════════════════════════════
-- VERSION
-- ══════════════════════════════════════════════════════════════

function ZDX.GetVersion()
    return GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.0.0'
end

-- ══════════════════════════════════════════════════════════════
-- GLOBAL STATE INIT
-- ══════════════════════════════════════════════════════════════

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    GlobalState['zdx:playerCount'] = 0
end)

print('^2[ZDX]^0 Server API loaded.')
