-- ══════════════════════════════════════════════════════════════
-- ZDX Core: ESX Client Bridge
-- Translates ZDX client events/API into ESX Legacy format
-- so third-party ESX client scripts work without modification.
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

-- Export moved to the end of the loading sequence
AddEventHandler('esx:getSharedObject', function(cb)
    cb(ESX)
end)

-- ══════════════════════════════════════════════════════════════
-- LISTEN TO ZDX EVENTS → FIRE ESX EVENTS
-- ══════════════════════════════════════════════════════════════

AddEventHandler('zdx:playerLoaded', function(playerData)
    ESX.PlayerData = playerData or ZDX.PlayerData
    ESX.PlayerLoaded = true
    TriggerEvent('esx:playerLoaded', ESX.PlayerData, false, {})
end)

AddEventHandler('zdx:client:playerUnloaded', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
    TriggerEvent('esx:onPlayerLogout')
end)

-- Also handle the legacy net event for ESX scripts that fire it
RegisterNetEvent('esx:playerLoaded', function(playerData, isNew, skin)
    ESX.PlayerData = playerData or ZDX.PlayerData
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER DATA FUNCTIONS (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function ESX.GetPlayerData()
    return ZDX.GetPlayerData()
end

function ESX.IsPlayerLoaded()
    return ZDX.IsPlayerLoaded()
end

function ESX.SetPlayerData(key, value)
    ESX.PlayerData[key] = value
    ZDX.SetPlayerData(key, value)
end

-- ══════════════════════════════════════════════════════════════
-- SERVER CALLBACK (ESX Style → wraps ZDX callbacks)
-- ══════════════════════════════════════════════════════════════

ESX.ServerCallbacks = {}

function ESX.TriggerServerCallback(name, cb, ...)
    ZDX.TriggerCallback(name, cb, ...)
end

-- Legacy callback response handler (for scripts using old pattern)
RegisterNetEvent('esx_callback_response', function(name, ...)
    if ESX.ServerCallbacks[name] then
        ESX.ServerCallbacks[name](...)
        ESX.ServerCallbacks[name] = nil
    end
end)

-- ══════════════════════════════════════════════════════════════
-- GAME UTILITY FUNCTIONS (delegate to ZDX.Game)
-- ══════════════════════════════════════════════════════════════

function ESX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
    ZDX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
end

function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    ZDX.ShowHelpNotification(msg, thisFrame, beep, duration)
end

function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    ZDX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end

function ESX.Game.GetPedMugshot(ped, transparent)
    return ZDX.Game.GetPedMugshot(ped, transparent)
end

function ESX.Game.Teleport(entity, coords, cb)
    ZDX.Game.Teleport(entity, coords, cb)
end

function ESX.Game.SpawnLocalVehicle(model, coords, heading, cb)
    return ZDX.Game.SpawnLocalVehicle(model, coords, heading, cb)
end

function ESX.Game.DeleteVehicle(vehicle)
    ZDX.Game.DeleteVehicle(vehicle)
end

function ESX.Game.GetClosestVehicle(coords)
    return ZDX.Game.GetClosestVehicle(coords)
end

function ESX.Game.GetClosestPlayer(coords)
    return ZDX.Game.GetClosestPlayer(coords)
end

function ESX.Game.GetPlayersInArea(coords, maxDistance)
    return ZDX.Game.GetPlayersInArea(coords, maxDistance)
end

function ESX.Game.GetVehiclesInArea(coords, maxDistance)
    return ZDX.Game.GetVehiclesInArea(coords, maxDistance)
end

function ESX.Game.GetVehicleInDirection()
    return ZDX.Game.GetVehicleInDirection()
end

function ESX.Game.GetClosestObject(coords, filter)
    return ZDX.Game.GetClosestObject(coords, filter)
end

function ESX.Game.GetClosestPed(coords, ignoreList)
    return ZDX.Game.GetClosestPed(coords, ignoreList)
end

-- ══════════════════════════════════════════════════════════════
-- STREAMING (delegate to ZDX.Streaming)
-- ══════════════════════════════════════════════════════════════

ESX.Streaming = {}

function ESX.Streaming.RequestModel(model, cb)
    ZDX.Streaming.RequestModel(model, cb)
end

function ESX.Streaming.RequestAnimDict(animDict, cb)
    ZDX.Streaming.RequestAnimDict(animDict, cb)
end

function ESX.Streaming.RequestAnimSet(animSet, cb)
    ZDX.Streaming.RequestAnimSet(animSet, cb)
end

function ESX.Streaming.RequestTextureDict(textureDict, cb)
    ZDX.Streaming.RequestTextureDict(textureDict, cb)
end

function ESX.Streaming.RequestNamedPtfxAsset(ptfxName, cb)
    ZDX.Streaming.RequestNamedPtfxAsset(ptfxName, cb)
end

-- ══════════════════════════════════════════════════════════════
-- SCALEFORM (delegate to ZDX.Scaleform)
-- ══════════════════════════════════════════════════════════════

ESX.Scaleform = {}

function ESX.Scaleform.ShowFreemodeMessage(title, msg, sec)
    ZDX.Scaleform.ShowFreemodeMessage(title, msg, sec)
end

-- ══════════════════════════════════════════════════════════════
-- DISABLE SPAWN MANAGER
-- ══════════════════════════════════════════════════════════════

function ESX.DisableSpawnManager()
    -- No spawnmanager to disable; ZDX handles it natively
end

-- ══════════════════════════════════════════════════════════════
-- MATH / TABLE (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

ESX.Math = {}
function ESX.Math.Round(num, numDecimalPlaces)
    return ZDX.Math.Round(num, numDecimalPlaces)
end

function ESX.Math.GroupDigits(value)
    return ZDX.Math.GroupDigits(value)
end

ESX.Table = {}
function ESX.Table.Clone(t)
    return ZDX.Table.Clone(t)
end

-- ══════════════════════════════════════════════════════════════
-- ESX NOTIFICATION HANDLER (for server-triggered events)
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('esx:showNotification', function(msg)
    ZDX.ShowNotification(msg)
end)

print('^2[ZDX]^0 ESX Client Bridge loaded.')
