-- ══════════════════════════════════════════════════════════════
-- ZDX Core: ESX Server Bridge
-- Translates ZDX events/API into ESX Legacy format so
-- third-party ESX scripts can run without modification.
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

-- Export moved to the end of the loading sequence


AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

-- ══════════════════════════════════════════════════════════════
-- LISTEN TO ZDX EVENTS → FIRE ESX EVENTS
-- ══════════════════════════════════════════════════════════════

AddEventHandler('zdx:playerLoaded', function(playerId, zdxPlayer)
    if zdxPlayer then
        ESX.Players[playerId] = zdxPlayer
        Core.playersByIdentifier[zdxPlayer.identifier] = zdxPlayer

        -- Attach ESX compat wrappers to the player object
        -- so ESX scripts calling xPlayer.getJob() etc. work
        zdxPlayer.getJob = zdxPlayer.Functions.GetJob
        zdxPlayer.getMoney = function() return zdxPlayer.accounts.money or 0 end
        zdxPlayer.getAccounts = zdxPlayer.Functions.GetAccounts
        zdxPlayer.getAccount = zdxPlayer.Functions.GetAccount
        zdxPlayer.getInventory = zdxPlayer.Functions.GetInventory
        zdxPlayer.getLoadout = zdxPlayer.Functions.GetLoadout
        zdxPlayer.getCoords = zdxPlayer.Functions.GetCoords
        zdxPlayer.getName = zdxPlayer.Functions.GetName
        zdxPlayer.getIdentifier = zdxPlayer.Functions.GetIdentifier
        zdxPlayer.getMeta = zdxPlayer.Functions.GetMetaData
        zdxPlayer.getMaxWeight = zdxPlayer.Functions.GetMaxWeight
        zdxPlayer.addMoney = function(amount, reason) return zdxPlayer.Functions.AddMoney('money', amount, reason) end
        zdxPlayer.removeMoney = function(amount, reason) return zdxPlayer.Functions.RemoveMoney('money', amount, reason) end
        zdxPlayer.addAccountMoney = zdxPlayer.Functions.AddAccountMoney
        zdxPlayer.removeAccountMoney = zdxPlayer.Functions.RemoveAccountMoney
        zdxPlayer.setAccountMoney = zdxPlayer.Functions.SetAccountMoney
        zdxPlayer.setJob = function(job, grade) return zdxPlayer.Functions.SetJob(job, grade) end
        zdxPlayer.setMeta = zdxPlayer.Functions.SetMetaData
        zdxPlayer.showNotification = zdxPlayer.Functions.ShowNotification
        zdxPlayer.triggerEvent = function(eventName, ...) TriggerClientEvent(eventName, zdxPlayer.source, ...) end
        zdxPlayer.addInventoryItem = zdxPlayer.Functions.AddItem
        zdxPlayer.removeInventoryItem = zdxPlayer.Functions.RemoveItem
        zdxPlayer.getInventoryItem = zdxPlayer.Functions.GetItemByName
        zdxPlayer.set = function(key, value) zdxPlayer.metadata[key] = value end
        zdxPlayer.get = function(key) return zdxPlayer.metadata[key] end
        zdxPlayer.setName = function(name) zdxPlayer.name = name end
        zdxPlayer.kick = function(reason) DropPlayer(tostring(zdxPlayer.source), reason or 'Kicked') end

        -- Fire ESX load event for ESX scripts
        TriggerEvent('esx:playerLoaded', playerId, zdxPlayer, false)
    end
end)

AddEventHandler('zdx:playerDropped', function(playerId, reason)
    ESX.Players[playerId] = nil
    TriggerEvent('esx:playerDropped', playerId, reason)
end)

AddEventHandler('zdx:jobUpdate', function(source, job, oldJob)
    TriggerEvent('esx:setJob', source, job, oldJob)
end)

-- ══════════════════════════════════════════════════════════════
-- ESX PLAYER FUNCTIONS (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function ESX.GetPlayerFromId(source)
    return ZDX.GetPlayer(source)
end

function ESX.GetPlayerFromIdentifier(identifier)
    return ZDX.GetPlayerByIdentifier(identifier)
end

function ESX.GetExtendedPlayers(key, val)
    return ZDX.GetExtendedPlayers(key, val)
end

function ESX.GetPlayers()
    return ZDX.GetPlayers()
end

function ESX.DoesJobExist(job, grade)
    return ZDX.DoesJobExist(job, grade)
end

function ESX.RegisterUsableItem(item, cb)
    ZDX.RegisterUsableItem(item, cb)
end

function ESX.UseItem(source, item)
    ZDX.UseItem(source, item)
end

function ESX.GetItemLabel(item)
    return ZDX.GetItemLabel(item)
end

--- Register server callback (ESX style)
function ESX.RegisterServerCallback(name, cb)
    ZDX.RegisterCallback(name, cb)
end

--- Trigger server callback from server
function ESX.TriggerServerCallback(name, source, cb, ...)
    ZDX.TriggerCallback(name, source, cb, ...)
end

--- Create a pickup (stub)
function ESX.CreatePickup(pickupType, name, count, label, playerId, components, tintIndex)
    -- Stub: pickups not needed for cinematic
end

--- Get weapon label
function ESX.GetWeaponLabel(weaponName)
    return weaponName
end

--- Get weapon from name
function ESX.GetWeapon(weaponName)
    return false, nil
end

--- Get identifier from source
function ESX.GetIdentifier(source)
    return ZDX.GetIdentifier(source)
end

-- ══════════════════════════════════════════════════════════════
-- MATH / TABLE UTILITIES (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

ESX.Math = {}
function ESX.Math.Round(num, numDecimalPlaces)
    return ZDX.Math.Round(num, numDecimalPlaces)
end

function ESX.Math.GroupDigits(value)
    return ZDX.Math.GroupDigits(value)
end

function ESX.Math.Random(lowest, highest)
    return ZDX.Math.Random(lowest, highest)
end

ESX.Table = {}
function ESX.Table.Clone(t)
    return ZDX.Table.Clone(t)
end

-- ══════════════════════════════════════════════════════════════
-- ONESYNC UTILITIES (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

ESX.OneSync = {}
function ESX.OneSync.SpawnVehicle(model, coords, heading, props, cb)
    return ZDX.OneSync.SpawnVehicle(model, coords, heading, props, cb)
end

function ESX.OneSync.GetPlayersInArea(coords, maxDistance)
    return ZDX.OneSync.GetPlayersInArea(coords, maxDistance)
end

function ESX.OneSync.GetPedsInArea(coords, maxDistance)
    return ZDX.OneSync.GetPedsInArea(coords, maxDistance)
end

function ESX.OneSync.GetVehiclesInArea(coords, maxDistance)
    return ZDX.OneSync.GetVehiclesInArea(coords, maxDistance)
end

-- ══════════════════════════════════════════════════════════════
-- ADMIN / SAVE (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function Core.IsPlayerAdmin(source)
    return ZDX.IsPlayerAdmin(source)
end

function Core.SavePlayer(xPlayer, cb)
    ZDX.SavePlayer(xPlayer, cb)
end

function Core.SavePlayers()
    ZDX.SavePlayers()
end

--- Get Configuration (ox_inventory requires this)
function ESX.GetConfig()
    return Config
end

print('^2[ZDX]^0 ESX Server Bridge loaded.')
