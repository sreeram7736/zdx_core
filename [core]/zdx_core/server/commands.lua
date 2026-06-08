-- Basic cinematic and admin commands for zdx-core

-- Teleport to coordinates
RegisterCommand('tp', function(source, args, rawCommand)
    if source == 0 then return end -- Console cannot teleport
    -- Basic permission check can be added here
    -- if not IsPlayerAceAllowed(source, "command.tp") then return end

    if #args < 3 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Usage: /tp [x] [y] [z]' } })
        return
    end

    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])

    if x and y and z then
        TriggerClientEvent('zdx_core:client:teleport', source, vector3(x, y, z))
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Invalid coordinates.' } })
    end
end, true) -- Set to true to require ace permissions by default

-- Teleport to marker (waypoint)
RegisterCommand('tpm', function(source, args, rawCommand)
    if source == 0 then return end
    TriggerClientEvent('zdx_core:client:teleportToWaypoint', source)
end, true)

-- Change model
RegisterCommand('setmodel', function(source, args, rawCommand)
    if source == 0 then return end
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1SYSTEM', 'Usage: /setmodel [modelName]' } })
        return
    end

    local model = tostring(args[1])
    TriggerClientEvent('zdx_core:client:setModel', source, model)
end, true)
