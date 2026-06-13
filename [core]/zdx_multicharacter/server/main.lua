
local function getBridge()
    return ServerCore.FrameworkBridge
end

local function waitForBridge()
    local attempts = 0
    while not ServerCore.FrameworkBridge and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    return ServerCore.FrameworkBridge
end

local function refreshCharacters(source)
    local bridge = getBridge()
    if not bridge then
        return {}
    end
    return bridge.GetCharacters(source)
end

local function pushCharacterList(source)
    local characters = refreshCharacters(source)
    TriggerClientEvent("zdx_multichar:client:updateCharacters", source, characters)
    return characters
end

local function validateCreationData(data)
    if type(data) ~= "table" then
        return false, "invalid_payload"
    end

    local nameCfg = CreationConfig.Name or { minLength = 2, maxLength = 30 }
    local firstname = tostring(data.firstname or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local lastname = tostring(data.lastname or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if #firstname < (nameCfg.minLength or 2) or #firstname > (nameCfg.maxLength or 30) then
        return false, "invalid_firstname"
    end

    if #lastname < (nameCfg.minLength or 2) or #lastname > (nameCfg.maxLength or 30) then
        return false, "invalid_lastname"
    end

    data.firstname = firstname
    data.lastname = lastname
    return true
end

local function shouldOpenBuiltinSpawnSelect()
    if Config.SpawnSelector ~= "builtin" then
        return false
    end
    return Config.SpawnLocations and #Config.SpawnLocations > 0
end

CreateThread(function()
    waitForBridge()

    ServerCore.CreateCallback("zdx_multichar:getCharacters", function(source, cb)
        local bridge = getBridge()
        if not bridge then
            cb({ characters = {}, maxCharacters = Config.MaxCharacters, canDelete = CanPlayerDeleteCharacter(source) })
            return
        end

        cb({
            characters = bridge.GetCharacters(source),
            maxCharacters = bridge.GetMaxCharacters(source),
            canDelete = CanPlayerDeleteCharacter(source),
        })
    end)
end)

RegisterNetEvent("zdx_multichar:playerEnteredMultichar", function()
    local source = source
    SetPlayerRoutingBucket(source, source)
    SetRoutingBucketPopulationEnabled(source, false)
    TriggerClientEvent("zdx_multichar:client:bucketReady", source)
end)

RegisterNetEvent("zdx_multichar:playerLeftMultichar", function()
    local source = source
    SetPlayerRoutingBucket(source, 0)
end)

RegisterNetEvent("zdx_multichar:previewCharacter", function(charId)
    local source = source
    local bridge = getBridge()
    if bridge and charId then
        bridge.PreviewCharacter(source, charId)
    end
end)

RegisterNetEvent("zdx_multichar:selectCharacter", function(charId)
    local source = source
    local bridge = getBridge()
    if not bridge or not charId then
        return
    end

    if bridge.SelectCharacter(source, charId) and shouldOpenBuiltinSpawnSelect() then
        TriggerClientEvent("zdx_multichar:client:openSpawnSelect", source)
    end
end)

RegisterNetEvent("zdx_multichar:createCharacter", function(data)
    local source = source
    local bridge = getBridge()
    if not bridge then
        return
    end

    local valid, reason = validateCreationData(data)
    if not valid then
        if Config.Debug then
            print(("[zdx Multichar] createCharacter rejected: %s"):format(reason))
        end
        TriggerClientEvent("zdx_multichar:client:characterCreateFailed", source, reason)
        return
    end

    local success, newCharId = bridge.CreateCharacter(source, data)
    if not success then
        if Config.Debug then
            print(("[zdx Multichar] createCharacter failed: %s"):format(tostring(newCharId)))
        end
        TriggerClientEvent("zdx_multichar:client:characterCreateFailed", source, newCharId)
        return
    end

    Wait(100)
    local characters = refreshCharacters(source)

    local foundNewChar = false
    for _, char in ipairs(characters) do
        if tostring(char.id) == tostring(newCharId) then
            foundNewChar = true
            break
        end
    end

    if not foundNewChar and newCharId and bridge.GetCharacterById then
        local createdChar = bridge.GetCharacterById(newCharId, source)
        if createdChar then
            characters[#characters + 1] = createdChar
        end
    end

    TriggerClientEvent("zdx_multichar:client:updateCharacters", source, characters)
    TriggerClientEvent("zdx_multichar:client:characterCreated", source, characters, newCharId)
end)

RegisterNetEvent("zdx_multichar:deleteCharacter", function(charId)
    local source = source
    if not CanPlayerDeleteCharacter(source) then
        return
    end

    local bridge = getBridge()
    if not bridge or not charId then
        return
    end

    if not bridge.DeleteCharacter(source, charId) then
        return
    end

    local characters = pushCharacterList(source)
    TriggerClientEvent("zdx_multichar:client:characterDeleted", source, characters)
end)

RegisterNetEvent("zdx_multichar:confirmSpawn", function()
    local source = source
    local bridge = getBridge()
    if bridge and bridge.OnConfirmSpawn then
        bridge.OnConfirmSpawn(source)
    end
end)

RegisterNetEvent("zdx_multichar:server:quitGame", function()
    DropPlayer(source, "You left the server.")
end)

if Config.LogoutCommand and Config.LogoutCommand ~= false then
    RegisterCommand(Config.LogoutCommand, function(commandSource)
        if commandSource <= 0 then
            return
        end

        if Config.LogoutRestricted then
            if type(Config.LogoutRestricted) == "function" and not Config.LogoutRestricted(commandSource) then
                return
            end
        end

        TriggerClientEvent("zdx_multichar:client:logout", commandSource)
    end, false)
end

exports("GetCharacters", function(playerSource)
    local bridge = getBridge()
    if not bridge then
        return {}
    end
    return bridge.GetCharacters(playerSource)
end)

exports("OpenMultichar", function(playerSource)
    TriggerClientEvent("zdx_multichar:client:open", playerSource)
end)

