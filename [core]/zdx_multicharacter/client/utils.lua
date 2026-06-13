local clientCallbacks = {}
local callbackId = 0

function TriggerServerCallback(name, cb, ...)
    callbackId = callbackId + 1
    local requestId = callbackId
    
    clientCallbacks[requestId] = cb
    
    TriggerServerEvent('nexus-multicharacter:server:triggerCallback', name, requestId, ...)
end

RegisterNetEvent('nexus-multicharacter:client:callbackResponse', function(requestId, ...)
    if clientCallbacks[requestId] then
        clientCallbacks[requestId](...)
        clientCallbacks[requestId] = nil
    end
end)

function SendNUIMessage(data)
    SendNUIMessage(data)
end

function RegisterNUICallback(name, cb)
    RegisterNUICallback(name, cb)
end

_G.TriggerServerCallback = TriggerServerCallback