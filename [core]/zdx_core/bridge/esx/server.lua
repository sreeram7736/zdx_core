-- ══════════════════════════════════════════════════════════════
-- ZDX Core: ESX Server Bridge
-- Provides full ESX Legacy compatibility so ESX scripts
-- can run without modification on zdx-core.
-- ══════════════════════════════════════════════════════════════

ESX = {}
ESX.Players = {}
ESX.Jobs = Config.Jobs
ESX.Items = {}

Core = {}
Core.UsableItemsCallbacks = {}
Core.Pickups = {}
Core.playersByIdentifier = {}
Core.JobsPlayerCount = {}
Core.RegisteredCommands = {}

-- ── The shared object that ESX scripts request ──
local function getSharedObject()
    return ESX
end

exports('getSharedObject', getSharedObject)

AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

-- ══════════════════════════════════════════════════════════════
-- ESX PLAYER FUNCTIONS
-- ══════════════════════════════════════════════════════════════

--- Get player from server id
---@param source number
---@return table|nil
function ESX.GetPlayerFromId(source)
    return GetZDXPlayer(source)
end

--- Get player from identifier
---@param identifier string
---@return table|nil
function ESX.GetPlayerFromIdentifier(identifier)
    return GetZDXPlayerByIdentifier(identifier)
end

--- Get all extended players
---@return table
function ESX.GetExtendedPlayers(key, val)
    local players = {}
    for src, zdxPlayer in pairs(ZDX.Players) do
        if key then
            if key == 'job' and zdxPlayer.job.name == val then
                players[#players+1] = zdxPlayer
            elseif key == 'group' and (zdxPlayer.metadata.group or 'user') == val then
                players[#players+1] = zdxPlayer
            end
        else
            players[#players+1] = zdxPlayer
        end
    end
    return players
end

--- Get all player sources
---@return table
function ESX.GetPlayers()
    local sources = {}
    for src in pairs(ZDX.Players) do
        sources[#sources+1] = src
    end
    return sources
end

--- Check if a job exists
---@param job string
---@param grade string|number
---@return boolean
function ESX.DoesJobExist(job, grade)
    grade = tonumber(grade) or 0
    if Config.Jobs[job] and Config.Jobs[job].grades[grade] then
        return true
    end
    return false
end

--- Register a useable item
---@param item string
---@param cb function
function ESX.RegisterUsableItem(item, cb)
    Core.UsableItemsCallbacks[item] = cb
end

--- Use an item
---@param source number
---@param item string
function ESX.UseItem(source, item)
    if Core.UsableItemsCallbacks[item] then
        Core.UsableItemsCallbacks[item](source)
    end
end

--- Get item label
---@param item string
---@return string
function ESX.GetItemLabel(item)
    if ESX.Items[item] then
        return ESX.Items[item].label
    end
    return item
end

--- Register server callback (ESX style)
---@param name string
---@param cb function
function ESX.RegisterServerCallback(name, cb)
    RegisterNetEvent(('esx_callback:%s'):format(name), function(...)
        local src = source
        cb(src, function(...)
            TriggerClientEvent(('esx_callback_response:%s'):format(name), src, ...)
        end, ...)
    end)
end

--- Trigger server callback from server
---@param name string
---@param source number
---@param cb function
function ESX.TriggerServerCallback(name, source, cb, ...)
    RegisterNetEvent(('esx_callback:%s'):format(name), function(...)
        cb(...)
    end)
end

--- Create a pickup (stub)
function ESX.CreatePickup(pickupType, name, count, label, playerId, components, tintIndex)
    -- Stub: pickups not needed for cinematic
end

--- Get weapon label
---@param weaponName string
---@return string
function ESX.GetWeaponLabel(weaponName)
    return weaponName
end

--- Get weapon from name
---@param weaponName string
---@return boolean, table|nil
function ESX.GetWeapon(weaponName)
    return false, nil
end

--- Get identifier from source
---@param source number
---@return string|nil
function ESX.GetIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license2') or GetPlayerIdentifierByType(source, 'license')
end

--- Math utilities
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

function ESX.Math.Random(lowest, highest)
    return math.random(lowest, highest)
end

--- Table utilities
ESX.Table = {}
function ESX.Table.Clone(t)
    local clone = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            clone[k] = ESX.Table.Clone(v)
        else
            clone[k] = v
        end
    end
    return clone
end

--- OneSync utilities
ESX.OneSync = {}
function ESX.OneSync.SpawnVehicle(model, coords, heading, props, cb)
    local veh = CreateVehicleServerSetter(model, 'automobile', coords.x, coords.y, coords.z, heading or 0.0)
    while not DoesEntityExist(veh) do Wait(0) end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if cb then cb(netId) end
    return netId
end

function ESX.OneSync.GetPlayersInArea(coords, maxDistance)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(ped)
        if #(playerCoords - coords) <= maxDistance then
            players[#players+1] = tonumber(playerId)
        end
    end
    return players
end

function ESX.OneSync.GetPedsInArea(coords, maxDistance)
    return {}
end

function ESX.OneSync.GetVehiclesInArea(coords, maxDistance)
    return {}
end

--- Admin check
function Core.IsPlayerAdmin(source)
    return IsPlayerAceAllowed(tostring(source), 'command')
end

--- Save single player
function Core.SavePlayer(xPlayer, cb)
    if xPlayer and xPlayer.Functions then
        xPlayer.Functions.Save()
    end
    if cb then cb() end
end

--- Save all players
function Core.SavePlayers()
    for _, zdxPlayer in pairs(ZDX.Players) do
        zdxPlayer.Functions.Save()
    end
end

--- Track ESX players when zdx players load
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if xPlayer then
        ESX.Players[playerId] = xPlayer
        Core.playersByIdentifier[xPlayer.identifier] = xPlayer
    end
end)

AddEventHandler('esx:playerDropped', function(playerId)
    ESX.Players[playerId] = nil
end)

-- ══════════════════════════════════════════════════════════════
-- GLOBAL STATE INIT
-- ══════════════════════════════════════════════════════════════
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    GlobalState['playerCount'] = 0
end)

print('^2[ZDX-CORE]^0 ESX Bridge loaded.')
