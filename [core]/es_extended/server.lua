-- ══════════════════════════════════════════════════════════════
-- es_extended Compatibility Shim
-- Forwards exports.es_extended:getSharedObject() → zdx_core's ESX bridge
-- ══════════════════════════════════════════════════════════════

local ESX = nil

local function getSharedObject()
    if not ESX then
        ESX = exports['zdx_core']:getSharedObject()
    end
    return ESX
end

exports('getSharedObject', getSharedObject)

-- Legacy event-based approach used by older ESX scripts
AddEventHandler('esx:getSharedObject', function(cb)
    cb(getSharedObject())
end)

print('^2[ZDX]^0 es_extended compatibility shim loaded.')
