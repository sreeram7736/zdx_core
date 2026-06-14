-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Server Main (Connection, DB Load, Save Loop)
-- ══════════════════════════════════════════════════════════════

-- Ensure DB table on startup
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ZDX_DB.EnsureTable()
    GlobalState.PlayerCount = 0
    GlobalState.MaxPlayers = GetConvarInt('sv_maxclients', 48)
    print('^2[ZDX]^0 ZDX Framework started.')
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER CONNECTION
-- ══════════════════════════════════════════════════════════════

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    local identifier = GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license')

    if not identifier then
        deferrals.done('No valid license found. Please restart your game.')
        return
    end

    deferrals.update(('[ZDX] Welcome %s, loading your data...'):format(name))
    Wait(0)

    deferrals.done()
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER JOINED (after fully connected)
-- ══════════════════════════════════════════════════════════════

local function LoadPlayerAndSpawn(src, identifier)
    if ZDX.Players[src] then return end -- Already loaded

    local playerName = GetPlayerName(src)

    -- Load or create from database
    local dbData = ZDX_DB.LoadPlayer(identifier)
    if not dbData then
        print(('^3[ZDX]^0 New player %s, creating database entry...'):format(playerName))
        dbData = ZDX_DB.CreatePlayer(identifier, playerName)
    end

    if not dbData then
        DropPlayer(tostring(src), 'Failed to load your character data. Please try again.')
        return
    end

    -- Create player object
    local zdxPlayer = CreateZDXPlayer(src, identifier, dbData)
    GlobalState.PlayerCount = (GlobalState.PlayerCount or 0) + 1

    print(('^2[ZDX]^0 Player %s loaded (ID: %s | CitizenID: %s)'):format(playerName, src, zdxPlayer.citizenid))

    -- Determine spawn position
    local spawnPos = Config.DefaultSpawn
    if dbData.position then
        local pos = dbData.position
        if pos.x and pos.y and pos.z then
            spawnPos = vector4(pos.x, pos.y, pos.z, pos.heading or 0.0)
        end
    end

    -- Send data to client for spawning
    TriggerClientEvent('zdx_core:client:spawnPlayer', src, spawnPos, Config.DefaultModel, zdxPlayer.PlayerData)
end

RegisterNetEvent('zdx_core:server:playerJoined', function()
    local src = source
    local identifier = GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license')
    if not identifier then
        DropPlayer(tostring(src), 'No valid license found.')
        return
    end
    LoadPlayerAndSpawn(src, identifier)
end)

AddEventHandler('zdx_core:server:loadCharacter', function(src, identifier)
    LoadPlayerAndSpawn(src, identifier)
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER LOADED (Fired by client after spawn is complete)
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent('zdx_core:server:playerLoaded', function()
    local src = source
    local zdxPlayer = GetZDXPlayer(src)
    if not zdxPlayer then return end

    -- Set state bag
    Player(src).state:set('isLoggedIn', true, true)

    -- Fire ZDX native load event (bridges will pick this up)
    TriggerEvent('zdx:playerLoaded', src, zdxPlayer)

    -- PVP
    if Config.PVP then
        GlobalState.PVPEnabled = true
    end
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER DROPPED
-- ══════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local src = source
    local zdxPlayer = GetZDXPlayer(src)
    if not zdxPlayer then return end

    -- Save to database
    zdxPlayer.Functions.Save()

    -- Fire ZDX native drop event (bridges will pick this up)
    TriggerEvent('zdx:playerDropped', src, reason)

    print(('^1[ZDX]^0 Player %s disconnected (ID: %s). Reason: %s'):format(zdxPlayer.name, src, reason))

    ZDX.Players[src] = nil
    GlobalState.PlayerCount = math.max((GlobalState.PlayerCount or 1) - 1, 0)
end)

-- ══════════════════════════════════════════════════════════════
-- AUTO-SAVE LOOP (every 5 minutes)
-- ══════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(5 * 60 * 1000) -- 5 minutes
        local count = 0
        for src, zdxPlayer in pairs(ZDX.Players) do
            zdxPlayer.Functions.Save()
            count = count + 1
        end
        if count > 0 then
            print(('^2[ZDX]^0 Auto-saved %d player(s).'):format(count))
        end
    end
end)

-- Save all on txAdmin shutdown/restart
AddEventHandler('txAdmin:events:serverShuttingDown', function()
    for _, zdxPlayer in pairs(ZDX.Players) do
        zdxPlayer.Functions.Save()
    end
    print('^2[ZDX]^0 All players saved on shutdown.')
end)
