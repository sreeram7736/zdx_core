RegisterServerCallback('nexus-multicharacter:server:getCharacters', function(source, cb)
    local license = GetPlayerIdentifierByType(source, 'license')
    
    if not license then
        cb(nil)
        return
    end
    
    local characters = GetCharacters(license)
    local maxSlots = GetMaxSlots(license)
    
    cb({
        characters = characters,
        maxSlots = maxSlots
    })
end)

RegisterServerCallback('nexus-multicharacter:server:getCharacter', function(source, cb, slot)
    local license = GetPlayerIdentifierByType(source, 'license')
    
    if not license then
        cb(nil)
        return
    end
    
    local character = GetCharacterBySlot(license, slot)
    cb(character)
end)

RegisterNetEvent('nexus-multicharacter:server:createCharacter', function(data)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then return end
    
    local maxSlots = GetMaxSlots(license)
    
    -- Validate slot
    if data.slot > maxSlots then
        TriggerClientEvent('nexus-multicharacter:client:notify', src, 'error', 'Invalid slot')
        return
    end
    
    -- Check if slot is taken
    if GetCharacterBySlot(license, data.slot) then
        TriggerClientEvent('nexus-multicharacter:client:notify', src, 'error', 'Slot already taken')
        return
    end
    
    -- Validate data
    if not ValidateCharacterData(data) then
        TriggerClientEvent('nexus-multicharacter:client:notify', src, 'error', 'Invalid character data')
        return
    end
    
    -- Set starting money
    data.metadata = {
        cash = Config.StartingMoney.cash,
        bank = Config.StartingMoney.bank,
        job = 'unemployed',
        gang = 'none'
    }
    
    local characterId = CreateCharacter(license, data.slot, data)
    
    if characterId then
        TriggerClientEvent('nexus-multicharacter:client:characterCreated', src, data.slot)
    end
end)

RegisterNetEvent('nexus-multicharacter:server:deleteCharacter', function(slot)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then return end
    
    DeleteCharacter(license, slot)
    TriggerClientEvent('nexus-multicharacter:client:characterDeleted', src, slot)
end)

RegisterNetEvent('nexus-multicharacter:server:saveAppearance', function(slot, appearance)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then return end
    
    local char = GetCharacterBySlot(license, slot)
    if not char then return end
    
    UpdateCharacter(license, slot, {
        appearance = appearance,
        metadata = char.metadata,
        position = char.position
    })
end)

RegisterNetEvent('nexus-multicharacter:server:selectCharacter', function(slot, spawnId)
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license')
    
    if not license then return end
    
    local char = GetCharacterBySlot(license, slot)
    if not char then return end
    
    -- Save current position if not first spawn
    local coords = GetEntityCoords(GetPlayerPed(src))
    if coords and spawnId ~= 'last_location' then
        SaveLastPosition(license, slot, {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            w = GetEntityHeading(GetPlayerPed(src))
        })
    end
    
    -- Update last played
    MySQL.update.await([[
        UPDATE characters SET last_played = NOW() WHERE license = ? AND slot = ?
    ]], {license, slot})
    
    -- Trigger framework-specific event
    TriggerEvent('nexus-multicharacter:server:onCharacterSelected', src, char)
end)

RegisterNetEvent('nexus-multicharacter:server:disconnect', function()
    local src = source
    DropPlayer(src, 'Disconnected from character selection')
end)

function ValidateCharacterData(data)
    if not data.firstname or type(data.firstname) ~= 'string' or #data.firstname < 2 or #data.firstname > 50 then 
        return false 
    end
    
    if not data.lastname or type(data.lastname) ~= 'string' or #data.lastname < 2 or #data.lastname > 50 then 
        return false 
    end
    
    if not data.dob or type(data.dob) ~= 'string' then 
        return false 
    end
    
    if not data.gender or (data.gender ~= 'male' and data.gender ~= 'female') then 
        return false 
    end
    
    if not data.nationality or type(data.nationality) ~= 'string' then 
        return false 
    end
    
    if data.slot and type(data.slot) ~= 'number' then
        return false
    end
    
    return true
end

-- Helper function
function GetPlayerIdentifierByType(source, idType)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, idType) then
            return identifier
        end
    end
    return nil
end