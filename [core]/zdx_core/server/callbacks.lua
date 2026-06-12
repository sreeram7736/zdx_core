-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Server Callbacks
-- Custom callback system — no ESX or QB dependency.
--
-- Server usage:
--   ZDX.RegisterCallback('zdx:getPlayerData', function(source, cb, ...)
--       cb(someData)
--   end)
--
-- Client usage (via client/callbacks.lua):
--   ZDX.TriggerCallback('zdx:getPlayerData', function(data)
--       print(data)
--   end, arg1, arg2)
-- ══════════════════════════════════════════════════════════════

ZDX.Callbacks = {}

--- Register a server callback
---@param name string   Unique callback name
---@param cb function   function(source, cb, ...)
function ZDX.RegisterCallback(name, cb)
    ZDX.Callbacks[name] = cb
end

--- Trigger a registered callback from server-side (internal use)
---@param name string
---@param source number
---@param cb function
function ZDX.TriggerCallback(name, source, cb, ...)
    if ZDX.Callbacks[name] then
        ZDX.Callbacks[name](source, cb, ...)
    else
        print(('^1[ZDX]^0 Callback "%s" not registered.'):format(name))
    end
end

-- ── Net event: client triggers a callback ─────────────────────
RegisterNetEvent('zdx:triggerCallback', function(name, requestId, ...)
    local src = source
    if ZDX.Callbacks[name] then
        ZDX.Callbacks[name](src, function(...)
            TriggerClientEvent('zdx:callbackResponse', src, requestId, ...)
        end, ...)
    else
        print(('^1[ZDX]^0 Client requested unregistered callback: %s'):format(name))
    end
end)

print('^2[ZDX]^0 Callback system loaded.')
