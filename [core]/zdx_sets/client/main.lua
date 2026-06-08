-- zdx_sets client main

local activeSets = {}

RegisterNetEvent('zdx_sets:UpdateSets', function(sets)
    activeSets = sets
end)

RegisterCommand('createset', function(source, args)
    if args[1] then
        local setName = args[1]
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        TriggerServerEvent('zdx_sets:CreateSet', setName, {x = coords.x, y = coords.y, z = coords.z, w = heading})
        print("Created set: " .. setName)
    else
        print("Usage: /createset [name]")
    end
end, false)

RegisterCommand('delset', function(source, args)
    if args[1] then
        local setName = args[1]
        TriggerServerEvent('zdx_sets:DeleteSet', setName)
    else
        print("Usage: /delset [name]")
    end
end, false)

RegisterCommand('tpset', function(source, args)
    if args[1] then
        local setName = args[1]
        if activeSets[setName] then
            local pos = activeSets[setName]
            local ped = PlayerPedId()
            SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, true)
            SetEntityHeading(ped, pos.w)
            print("Teleported to set: " .. setName)
        else
            print("Set not found: " .. setName)
        end
    else
        print("Usage: /tpset [name]")
    end
end, false)

RegisterCommand('listsets', function()
    print("--- Active Sets ---")
    local count = 0
    for name, pos in pairs(activeSets) do
        print("- " .. name)
        count = count + 1
    end
    if count == 0 then
        print("No active sets.")
    end
end, false)
