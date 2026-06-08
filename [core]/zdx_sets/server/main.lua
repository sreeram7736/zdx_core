-- zdx_sets server main

local activeSets = {}

RegisterNetEvent('zdx_sets:CreateSet', function(setName, pos)
    local src = source
    activeSets[setName] = pos
    TriggerClientEvent('zdx_sets:UpdateSets', -1, activeSets)
    print("Set created by " .. tostring(src) .. ": " .. setName)
end)

RegisterNetEvent('zdx_sets:DeleteSet', function(setName)
    local src = source
    if activeSets[setName] then
        activeSets[setName] = nil
        TriggerClientEvent('zdx_sets:UpdateSets', -1, activeSets)
        print("Set deleted by " .. tostring(src) .. ": " .. setName)
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    TriggerClientEvent('zdx_sets:UpdateSets', src, activeSets)
end)
