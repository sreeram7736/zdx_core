local serverCallbacks = {}

function RegisterServerCallback(name, cb)
    serverCallbacks[name] = cb
end

RegisterNetEvent('nexus-multicharacter:server:triggerCallback', function(name, requestId, ...)
    local src = source
    
    if serverCallbacks[name] then
        serverCallbacks[name](src, function(...)
            TriggerClientEvent('nexus-multicharacter:client:callbackResponse', src, requestId, ...)
        end, ...)
    else
        print('^1[ERROR] Server callback not found: ' .. name .. '^0')
    end
end)

_G.RegisterServerCallback = RegisterServerCallback