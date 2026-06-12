-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Client Callbacks
-- Async callback system — triggers server callbacks from client.
--
-- Usage:
--   ZDX.TriggerCallback('zdx:getPlayerData', function(data)
--       print(json.encode(data))
--   end, optionalArg1, optionalArg2)
-- ══════════════════════════════════════════════════════════════

ZDX.Callbacks = {}

local pendingCallbacks = {}
local callbackId = 0

--- Trigger a server callback
---@param name string   The registered callback name
---@param cb function   The response handler
---@vararg any          Extra arguments to pass to the server
function ZDX.TriggerCallback(name, cb, ...)
    callbackId = callbackId + 1
    local requestId = ('zdx_cb_%d_%d'):format(ZDX.serverId, callbackId)
    pendingCallbacks[requestId] = cb
    TriggerServerEvent('zdx:triggerCallback', name, requestId, ...)
end

-- ── Net event: receive callback response from server ──────────
RegisterNetEvent('zdx:callbackResponse', function(requestId, ...)
    if pendingCallbacks[requestId] then
        pendingCallbacks[requestId](...)
        pendingCallbacks[requestId] = nil
    end
end)

print('^2[ZDX]^0 Client callback system loaded.')
