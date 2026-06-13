function GetMaxSlots(license)
    local result = MySQL.single.await([[
        SELECT max_slots FROM character_slots WHERE license = ?
    ]], {license})
    
    if result then
        return result.max_slots
    end
    
    -- Check Discord roles if enabled
    if Config.DiscordSlots and Config.DiscordSlots.enabled then
        local slots = GetDiscordSlots(license)
        if slots then
            SetMaxSlots(license, slots)
            return slots
        end
    end
    
    return Config.DefaultSlots
end

function SetMaxSlots(license, slots)
    MySQL.insert.await([[
        INSERT INTO character_slots (license, max_slots)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE max_slots = ?
    ]], {license, slots, slots})
end

function GetDiscordSlots(license)
    -- This is a placeholder - implement your Discord API integration
    -- For now, return nil to use default slots
    return nil
end

-- Export functions
exports('GetMaxSlots', GetMaxSlots)
exports('SetMaxSlots', SetMaxSlots)