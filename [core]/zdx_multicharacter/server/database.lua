MySQL = MySQL or exports.oxmysql

function GetCharacters(license)
    local result = MySQL.query.await([[
        SELECT * FROM characters 
        WHERE license = ? AND archived = false 
        ORDER BY slot ASC
    ]], {license})
    
    return result or {}
end

function GetCharacterBySlot(license, slot)
    local result = MySQL.single.await([[
        SELECT * FROM characters 
        WHERE license = ? AND slot = ? AND archived = false
    ]], {license, slot})
    
    return result
end

function CreateCharacter(license, slot, data)
    local result = MySQL.insert.await([[
        INSERT INTO characters 
        (license, slot, firstname, lastname, dob, gender, nationality, appearance, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        license,
        slot,
        data.firstname,
        data.lastname,
        data.dob,
        data.gender,
        data.nationality,
        json.encode(data.appearance or {}),
        json.encode(data.metadata or {})
    })
    
    return result
end

function UpdateCharacter(license, slot, data)
    MySQL.update.await([[
        UPDATE characters 
        SET appearance = ?, metadata = ?, position = ?
        WHERE license = ? AND slot = ?
    ]], {
        type(data.appearance) == 'string' and data.appearance or json.encode(data.appearance),
        type(data.metadata) == 'string' and data.metadata or json.encode(data.metadata),
        data.position,
        license,
        slot
    })
end

function DeleteCharacter(license, slot)
    if Config.ArchiveInsteadDelete then
        MySQL.update.await([[
            UPDATE characters SET archived = true WHERE license = ? AND slot = ?
        ]], {license, slot})
    else
        MySQL.query.await([[
            DELETE FROM characters WHERE license = ? AND slot = ?
        ]], {license, slot})
    end
end

function UpdatePlaytime(license, slot, playtime)
    MySQL.update.await([[
        UPDATE characters SET playtime = playtime + ? WHERE license = ? AND slot = ?
    ]], {playtime, license, slot})
end

function SaveScreenshot(license, slot, url)
    MySQL.update.await([[
        UPDATE characters SET screenshot = ? WHERE license = ? AND slot = ?
    ]], {url, license, slot})
end

function SaveLastPosition(license, slot, coords)
    local position = json.encode({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.w or 0.0
    })
    
    MySQL.update.await([[
        UPDATE characters SET position = ? WHERE license = ? AND slot = ?
    ]], {position, license, slot})
end