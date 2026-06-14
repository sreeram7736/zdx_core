-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Client API
-- Full client-side API for the ZDX custom framework.
--
-- Usage from other resources:
--   local ZDX = exports['zdx_core']:GetCoreObject()
--   local data = ZDX.GetPlayerData()
-- ══════════════════════════════════════════════════════════════

ZDX = ZDX or {}
ZDX.PlayerData = ZDX.PlayerData or {}
ZDX.IsLoggedIn = ZDX.IsLoggedIn or false

ZDX.playerId = PlayerId()
ZDX.serverId = GetPlayerServerId(ZDX.playerId)

-- ══════════════════════════════════════════════════════════════
-- CORE OBJECT EXPORT
-- ══════════════════════════════════════════════════════════════

-- Export moved to the end of the loading sequence to ensure all functions are attached

-- ══════════════════════════════════════════════════════════════
-- PLAYER DATA
-- ══════════════════════════════════════════════════════════════

--- Get current player data
---@return table
function ZDX.GetPlayerData()
    return ZDX.PlayerData
end

--- Check if the local player is logged in
---@return boolean
function ZDX.IsPlayerLoaded()
    return ZDX.IsLoggedIn
end

--- Set a player data field locally
---@param key string
---@param value any
function ZDX.SetPlayerData(key, value)
    ZDX.PlayerData[key] = value
end

-- ══════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ══════════════════════════════════════════════════════════════

--- Show a standard GTA notification
---@param msg string
---@param flash boolean|nil
---@param saveToBrief boolean|nil
---@param hudColorIndex number|nil
function ZDX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
    if hudColorIndex then ThefeedSetNextPostBackgroundColor(hudColorIndex) end
    SetNotificationTextEntry('STRING')
    AddTextComponentString(tostring(msg))
    DrawNotification(flash or false, saveToBrief ~= false)
end

--- Show a help notification
---@param msg string
---@param thisFrame boolean|nil
---@param beep boolean|nil
---@param duration number|nil
function ZDX.ShowHelpNotification(msg, thisFrame, beep, duration)
    if thisFrame then
        AddTextEntry('zdxHelpNotification', msg)
        DisplayHelpTextThisFrame('zdxHelpNotification', false)
    else
        BeginTextCommandDisplayHelp('zdxHelpNotification')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, beep or false, duration or 5000)
    end
end

--- Show an advanced notification with picture
function ZDX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if hudColorIndex then ThefeedSetNextPostBackgroundColor(hudColorIndex) end
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    SetNotificationMessage(textureDict or 'CHAR_DEFAULT', textureDict or 'CHAR_DEFAULT', flash or false, iconType or 1, sender or 'ZDX', subject or '')
    DrawNotification(false, saveToBrief ~= false)
end

-- ══════════════════════════════════════════════════════════════
-- GAME UTILITIES
-- ══════════════════════════════════════════════════════════════

ZDX.Game = {}

--- Get ped mugshot
function ZDX.Game.GetPedMugshot(ped, transparent)
    if transparent then
        return RegisterPedheadshotTransparent(ped)
    end
    return RegisterPedheadshot(ped)
end

--- Teleport an entity to coordinates
---@param entity number
---@param coords table|vector3|vector4
---@param cb function|nil
function ZDX.Game.Teleport(entity, coords, cb)
    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, true)
    if coords.heading or coords.w then
        SetEntityHeading(entity, coords.heading or coords.w)
    end
    if cb then cb() end
end

--- Spawn a local vehicle
function ZDX.Game.SpawnLocalVehicle(model, coords, heading, cb)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading or 0.0, true, false)
    SetModelAsNoLongerNeeded(hash)
    if cb then cb(vehicle) end
    return vehicle
end

--- Delete a vehicle
function ZDX.Game.DeleteVehicle(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

--- Get closest vehicle to coords
function ZDX.Game.GetClosestVehicle(coords)
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

--- Get closest player
function ZDX.Game.GetClosestPlayer(coords)
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

--- Get players in area
function ZDX.Game.GetPlayersInArea(coords, maxDistance)
    local players = {}
    local myPed = PlayerPedId()
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= myPed then
            local pedCoords = GetEntityCoords(ped)
            if #(coords - pedCoords) <= maxDistance then
                players[#players + 1] = playerId
            end
        end
    end
    return players
end

--- Get vehicles in area
function ZDX.Game.GetVehiclesInArea(coords, maxDistance)
    local vehicles = {}
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        local vehCoords = GetEntityCoords(vehicle)
        if #(coords - vehCoords) <= maxDistance then
            vehicles[#vehicles + 1] = vehicle
        end
    end
    return vehicles
end

--- Get vehicle in direction (raycast forward)
function ZDX.Game.GetVehicleInDirection()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwdVector = GetEntityForwardVector(ped)
    local rayHandle = StartShapeTestRay(
        coords.x, coords.y, coords.z,
        coords.x + fwdVector.x * 5, coords.y + fwdVector.y * 5, coords.z + fwdVector.z * 5,
        10, ped, 0
    )
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    return vehicle
end

--- Get closest object
function ZDX.Game.GetClosestObject(coords, filter)
    local objects = GetGamePool('CObject')
    local closestDist = -1
    local closestObj = -1
    coords = coords or GetEntityCoords(PlayerPedId())
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

--- Get closest ped
function ZDX.Game.GetClosestPed(coords, ignoreList)
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

--- Get vehicle properties
function ZDX.Game.GetVehicleProperties(vehicle)
    if DoesEntityExist(vehicle) then
        return {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            color1 = { GetVehicleColours(vehicle) },
        }
    end
    return {}
end

--- Set vehicle properties
function ZDX.Game.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) then return end
    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
end

--- Get vehicle plate
function ZDX.Game.GetPlate(vehicle)
    if vehicle and vehicle ~= 0 then
        return string.gsub(GetVehicleNumberPlateText(vehicle), '^%s+', ''):gsub('%s+$', '')
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════
-- STREAMING UTILITIES
-- ══════════════════════════════════════════════════════════════

ZDX.Streaming = {}

function ZDX.Streaming.RequestModel(model, cb)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    if cb then cb() end
    return hash
end

function ZDX.Streaming.RequestAnimDict(animDict, cb)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(0) end
    if cb then cb() end
end

function ZDX.Streaming.RequestAnimSet(animSet, cb)
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do Wait(0) end
    if cb then cb() end
end

function ZDX.Streaming.RequestTextureDict(textureDict, cb)
    RequestStreamedTextureDict(textureDict)
    while not HasStreamedTextureDictLoaded(textureDict) do Wait(0) end
    if cb then cb() end
end

function ZDX.Streaming.RequestNamedPtfxAsset(ptfxName, cb)
    RequestNamedPtfxAsset(ptfxName)
    while not HasNamedPtfxAssetLoaded(ptfxName) do Wait(0) end
    if cb then cb() end
end

-- ══════════════════════════════════════════════════════════════
-- SCALEFORM UTILITIES
-- ══════════════════════════════════════════════════════════════

ZDX.Scaleform = {}

function ZDX.Scaleform.ShowFreemodeMessage(title, msg, sec)
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

-- ══════════════════════════════════════════════════════════════
-- DEBUG
-- ══════════════════════════════════════════════════════════════

function ZDX.Debug(resource, obj)
    print(('[^3ZDX-DEBUG^0] [%s]'):format(resource or 'unknown'))
    print(json.encode(obj, { indent = true }))
end

print('^2[ZDX]^0 Client API loaded.')
