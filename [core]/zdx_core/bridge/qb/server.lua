-- ══════════════════════════════════════════════════════════════
-- ZDX Core: QBCore Server Bridge
-- Translates ZDX events/API into QBCore format so
-- third-party QB scripts can run without modification.
-- ══════════════════════════════════════════════════════════════

QBCore = {}
QBCore.Functions = {}
QBCore.Shared = {
    Vehicles = {},
    Items = {},
    Jobs = Config.Jobs,
    Gangs = Config.Gangs
}
QBCore.Players = {}

-- Exports moved to the end of the loading sequence
-- ══════════════════════════════════════════════════════════════
-- LISTEN TO ZDX EVENTS → FIRE QB EVENTS
-- ══════════════════════════════════════════════════════════════

AddEventHandler('zdx:playerLoaded', function(playerId, zdxPlayer)
    if zdxPlayer then
        QBCore.Players[playerId] = zdxPlayer

        -- Fire QB load event
        TriggerEvent('QBCore:Server:PlayerLoaded', zdxPlayer)
    end
end)

AddEventHandler('zdx:playerDropped', function(playerId, reason)
    QBCore.Players[playerId] = nil
    TriggerEvent('QBCore:Server:OnPlayerUnload', playerId)
end)

AddEventHandler('zdx:moneyChange', function(source, moneyType, amount, changeType, reason)
    TriggerEvent('QBCore:Server:OnMoneyChange', source, moneyType, amount, changeType, reason)
end)

AddEventHandler('zdx:jobUpdate', function(source, job)
    TriggerEvent('QBCore:Server:OnJobUpdate', source, job)
end)

AddEventHandler('zdx:gangUpdate', function(source, gang)
    TriggerEvent('QBCore:Server:OnGangUpdate', source, gang)
end)

-- ══════════════════════════════════════════════════════════════
-- QB PLAYER FUNCTIONS (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.GetPlayer(source)
    return ZDX.GetPlayer(source)
end

function QBCore.Functions.GetPlayerByCitizenId(citizenid)
    return ZDX.GetPlayerByCitizenId(citizenid)
end

function QBCore.Functions.GetPlayerByPhone(number)
    for _, player in pairs(ZDX.Players) do
        if player.charinfo.phone == number then
            return player
        end
    end
    return nil
end

function QBCore.Functions.GetPlayers()
    return ZDX.GetPlayers()
end

function QBCore.Functions.GetPlayersOnDuty(job)
    local players = {}
    local count = 0
    for src, player in pairs(ZDX.Players) do
        if player.job.name == job and player.job.onduty then
            players[#players + 1] = src
            count = count + 1
        end
    end
    return players
end

function QBCore.Functions.GetDutyCount(job)
    local count = 0
    for _, player in pairs(ZDX.Players) do
        if player.job.name == job and player.job.onduty then
            count = count + 1
        end
    end
    return count
end

-- ══════════════════════════════════════════════════════════════
-- QB CALLBACKS / ITEMS / UTILS (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.CreateCallback(name, cb)
    ZDX.RegisterCallback(name, cb)
end

function QBCore.Functions.TriggerCallback(name, source, cb, ...)
    ZDX.TriggerCallback(name, source, cb, ...)
end

function QBCore.Functions.CreateUseableItem(item, cb)
    ZDX.RegisterUsableItem(item, cb)
end

function QBCore.Functions.CanUseItem(item)
    return ZDX.CanUseItem(item)
end

function QBCore.Functions.UseItem(source, item)
    ZDX.UseItem(source, item)
end

function QBCore.Functions.Kick(source, reason)
    ZDX.Kick(source, reason)
end

function QBCore.Functions.HasPermission(source, permission)
    return ZDX.HasPermission(source, permission)
end

function QBCore.Functions.AddPermission(source, permission)
    ZDX.AddPermission(source, permission)
end

function QBCore.Functions.RemovePermission(source, permission)
    ZDX.RemovePermission(source, permission)
end

function QBCore.Functions.GetIdentifier(source, idtype)
    local idtype = idtype or 'license'
    return GetPlayerIdentifierByType(source, idtype)
end

-- ══════════════════════════════════════════════════════════════
-- QB NOTIFICATION (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

function QBCore.Functions.Notify(source, text, type, length)
    ZDX.Notify(source, text, type, length)
end

RegisterNetEvent('QBCore:Notify', function(text, type, length)
    local src = source
    ZDX.Notify(src, text, type, length)
end)

-- ══════════════════════════════════════════════════════════════
-- QB MATH (delegate to ZDX)
-- ══════════════════════════════════════════════════════════════

QBCore.Shared.Math = {}

function QBCore.Shared.Round(value, numDecimalPlaces)
    return ZDX.Math.Round(value, numDecimalPlaces)
end

function QBCore.Shared.GroupDigits(value)
    return ZDX.Math.GroupDigits(value)
end

print('^2[ZDX]^0 QBCore Server Bridge loaded.')
