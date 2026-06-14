-- ══════════════════════════════════════════════════════════════
-- ZDX Core: QBCore Client Bridge
-- Translates ZDX client events/API into QBCore format
-- so third-party QB client scripts work without modification.
-- ══════════════════════════════════════════════════════════════

QBCore = {}
QBCore.Functions = {}
QBCore.PlayerData = {}
QBCore.Shared = {
    Vehicles = {},
    Items = {},
    Jobs = Config.Jobs,
    Gangs = Config.Gangs
}

-- Exports moved to the end of the loading sequence
-- ══════════════════════════════════════════════════════════════
-- LISTEN TO ZDX EVENTS → FIRE QB EVENTS
-- ══════════════════════════════════════════════════════════════

AddEventHandler('zdx:playerLoaded', function(playerData)
    QBCore.PlayerData = playerData or ZDX.PlayerData
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end)

AddEventHandler('zdx:client:playerDataUpdate', function(playerData)
    QBCore.PlayerData = playerData
    TriggerEvent('QBCore:Player:SetPlayerData', playerData)
end)

AddEventHandler('zdx:client:playerUnloaded', function()
    QBCore.PlayerData = {}
    TriggerEvent('QBCore:Client:OnPlayerUnload')
end)

AddEventHandler('zdx:client:jobUpdate', function(jobInfo)
    if QBCore.PlayerData then
        QBCore.PlayerData.job = jobInfo
    end
    TriggerEvent('QBCore:Client:OnJobUpdate', jobInfo)
end)

AddEventHandler('zdx:client:gangUpdate', function(gangInfo)
    if QBCore.PlayerData then
        QBCore.PlayerData.gang = gangInfo
    end
    TriggerEvent('QBCore:Client:OnGangUpdate', gangInfo)
end)

AddEventHandler('zdx:client:moneyChange', function(moneyType, amount, changeType, reason)
    TriggerEvent('QBCore:Client:OnMoneyChange', moneyType, amount, changeType, reason)
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER DATA FUNCTIONS (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.GetPlayerData(cb)
    if cb then
        cb(ZDX.GetPlayerData())
    else
        return ZDX.GetPlayerData()
    end
end

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.TriggerCallback(name, cb, ...)
    ZDX.TriggerCallback(name, cb, ...)
end

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATIONS / UI (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.Notify(text, texttype, length)
    ZDX.ShowNotification(text)
end

-- ══════════════════════════════════════════════════════════════
-- GAME UTILITIES (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.SpawnVehicle(model, cb, coords, isnetworked)
    return ZDX.Game.SpawnLocalVehicle(model, coords, 0.0, cb)
end

function QBCore.Functions.DeleteVehicle(vehicle)
    ZDX.Game.DeleteVehicle(vehicle)
end

function QBCore.Functions.GetClosestVehicle(coords)
    local veh, dist = ZDX.Game.GetClosestVehicle(coords)
    return veh, dist
end

function QBCore.Functions.GetClosestPlayer(coords)
    local player, dist = ZDX.Game.GetClosestPlayer(coords)
    return player, dist
end

function QBCore.Functions.GetPlayersFromCoords(coords, distance)
    return ZDX.Game.GetPlayersInArea(coords, distance)
end

function QBCore.Functions.GetVehiclesInArea(coords, distance)
    return ZDX.Game.GetVehiclesInArea(coords, distance)
end

function QBCore.Functions.GetPlate(vehicle)
    return ZDX.Game.GetPlate(vehicle)
end

function QBCore.Functions.GetVehicleProperties(vehicle)
    return ZDX.Game.GetVehicleProperties(vehicle)
end

function QBCore.Functions.SetVehicleProperties(vehicle, props)
    ZDX.Game.SetVehicleProperties(vehicle, props)
end

-- ══════════════════════════════════════════════════════════════
-- MATH / TABLE (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

QBCore.Shared.Math = {}

function QBCore.Shared.Round(value, numDecimalPlaces)
    return ZDX.Math.Round(value, numDecimalPlaces)
end

function QBCore.Shared.GroupDigits(value)
    return ZDX.Math.GroupDigits(value)
end

print('^2[ZDX]^0 QBCore Client Bridge loaded.')
