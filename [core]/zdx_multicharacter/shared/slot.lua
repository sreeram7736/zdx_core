
Config.MaxCharacters = Config.MaxCharacters or 5
Config.CanDeleteCharacter = Config.CanDeleteCharacter ~= false

Config.PlayerSlotOverrides = Config.PlayerSlotOverrides or {}

function GetMaxCharactersForLicense(license)
    if not license then
        return Config.MaxCharacters
    end

    for _, entry in ipairs(Config.PlayerSlotOverrides) do
        if entry.license == license then
            return entry.slots or entry.max or Config.MaxCharacters
        end
    end

    return Config.MaxCharacters
end

function CanPlayerDeleteCharacter(source)
    if not Config.CanDeleteCharacter then
        return false
    end

    if Config.DeleteCharacterPermission then
        return Config.DeleteCharacterPermission(source)
    end

    return true
end

