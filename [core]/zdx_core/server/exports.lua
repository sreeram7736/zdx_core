-- ══════════════════════════════════════════════════════════════
-- ZDX Core: Server Exports
-- Defined at the end of the loading sequence to ensure all
-- functions and bridges are fully populated before export.
-- ══════════════════════════════════════════════════════════════

-- ZDX Core Export
exports('GetCoreObject', function()
    return ZDX
end)

-- ESX Bridge Export
exports('getSharedObject', function()
    return ESX
end)

-- QB Bridge Export
exports('GetSharedObject', function()
    return QBCore
end)
