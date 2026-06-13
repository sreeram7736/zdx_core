
if ServerCore.Framework ~= "esx" then
    return
end

local ESX = ServerCore.Obj
local freemodeMale = joaat("mp_m_freemode_01")
local freemodeFemale = joaat("mp_f_freemode_01")

local function decodeJson(value, fallback)
    if not value or value == "" then
        return fallback
    end
    if type(value) == "table" then
        return value
    end
    local ok, decoded = pcall(json.decode, value)
    if ok and decoded then
        return decoded
    end
    return fallback
end

local function stripLicensePrefix(identifier)
    if not identifier then
        return identifier
    end
    return identifier:match("^[^:]+:(.+)$") or identifier
end

local function getLicensePattern(license)
    return "%:" .. stripLicensePrefix(license) .. "$"
end

local function getSlotFromIdentifier(identifier)
    local slot = identifier:match("^char(%d+):")
    return tonumber(slot) or 1
end

local function getPlaytime(charId)
    local row = MySQL.single.await("SELECT playtime FROM zdx_playtime WHERE char_id = ?", { charId })
    return row and row.playtime or 0
end

local function getUsedSlots(license)
    local count = MySQL.scalar.await(
        "SELECT COUNT(*) FROM users WHERE identifier LIKE ?",
        { "%:" .. stripLicensePrefix(license) }
    )
    return count or 0
end

local function findNextSlot(license, maxSlots)
    for slot = 1, maxSlots do
        local identifier = ("char%d:%s"):format(slot, stripLicensePrefix(license))
        local exists = MySQL.scalar.await("SELECT identifier FROM users WHERE identifier = ? LIMIT 1", { identifier })
        if not exists then
            return slot, identifier
        end
    end
    return nil, nil
end

local function formatCharacter(row)
    local position = decodeJson(row.position, nil)
    local accounts = decodeJson(row.accounts, {})
    local gender = 0
    if row.sex == "f" or row.sex == "1" or row.sex == 1 then
        gender = 1
    end

    return {
        id = row.identifier,
        citizenid = row.identifier,
        cid = getSlotFromIdentifier(row.identifier),
        firstname = row.firstname or "Unknown",
        lastname = row.lastname or "Unknown",
        dob = row.dateofbirth or "",
        gender = gender,
        nationality = row.nationality or "",
        backstory = row.backstory or "",
        height = row.height or 180,
        job = {
            name = row.job or "unemployed",
            label = row.job or "Unemployed",
            grade = row.job_grade or 0,
        },
        money = {
            bank = accounts.bank or row.bank or 0,
            cash = accounts.money or accounts.cash or row.money or 0,
        },
        position = position,
        playtime = getPlaytime(row.identifier),
    }
end

local function buildAppearance(identifier, sex)
    local row = MySQL.single.await("SELECT skin, sex FROM users WHERE identifier = ? LIMIT 1", { identifier })
    local model = freemodeMale
    local skin = {}

    if row then
        skin = decodeJson(row.skin, {})
        local gender = row.sex or sex
        if gender == "f" or gender == 1 or gender == "1" then
            model = freemodeFemale
        end
    elseif sex == "f" or sex == 1 then
        model = freemodeFemale
    end

    return {
        model = model,
        skin = skin,
    }
end

local function giveStarterItems(source)
    if not Config.StarterItems or type(Config.StarterItems) ~= "table" then
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end

    for _, entry in ipairs(Config.StarterItems) do
        if entry.item and entry.count then
            xPlayer.addInventoryItem(entry.item, entry.count)
        end
    end
end

local ESXBridge = {}

function ESXBridge.GetCharacters(source)
    local license = ServerCore.GetLicense(source)
    if not license then
        return {}
    end

    local rows = MySQL.query.await(
        "SELECT * FROM users WHERE identifier LIKE ? ORDER BY identifier ASC",
        { "%:" .. stripLicensePrefix(license) }
    ) or {}

    local characters = {}
    for _, row in ipairs(rows) do
        characters[#characters + 1] = formatCharacter(row)
    end

    return characters
end

function ESXBridge.GetMaxCharacters(source)
    local license = ServerCore.GetLicense(source)
    return GetMaxCharactersForLicense(license)
end

function ESXBridge.GetAppearance(charId, callback)
    callback(buildAppearance(charId))
end

function ESXBridge.PreviewCharacter(source, charId)
    local license = ServerCore.GetLicense(source)
    local owned = MySQL.scalar.await(
        "SELECT identifier FROM users WHERE identifier = ? AND identifier LIKE ? LIMIT 1",
        { charId, getLicensePattern(license) }
    )

    if not owned then
        return
    end

    ESXBridge.GetAppearance(charId, function(appearance)
        if appearance then
            TriggerClientEvent("zdx_multichar:client:previewPed", source, appearance.model, appearance)
        end
    end)
end

function ESXBridge.SelectCharacter(source, charId)
    local license = ServerCore.GetLicense(source)
    local owned = MySQL.scalar.await(
        "SELECT identifier FROM users WHERE identifier = ? AND identifier LIKE ? LIMIT 1",
        { charId, getLicensePattern(license) }
    )

    if not owned then
        return false
    end

    TriggerEvent("esx:onPlayerJoined", source, charId)
    TriggerClientEvent("zdx_multichar:client:onPlayerLoaded", source)
    Webhooks.Send("login", "Character Selected", ("**%s** loaded character `%s`"):format(GetPlayerName(source), charId))
    return true
end

function ESXBridge.CreateCharacter(source, data)
    local license = ServerCore.GetLicense(source)
    if not license then
        return false, "missing_license"
    end

    local maxSlots = GetMaxCharactersForLicense(license)
    if getUsedSlots(license) >= maxSlots then
        return false, "max_characters"
    end

    local slot, identifier = findNextSlot(license, maxSlots)
    if not identifier then
        return false, "no_slot"
    end

    local sex = "m"
    if data.gender == 1 or data.gender == "1" or data.gender == "female" or data.gender == "Female" then
        sex = "f"
    end

    local firstname = data.firstname
    local lastname = data.lastname

    local defaultAccounts = json.encode({ bank = 5000, money = 500, black_money = 0 })
    local defaultPosition = json.encode({
        x = -1037.93,
        y = -2738.13,
        z = 20.17,
        heading = 0.0,
    })

    if Config.FirstSpawnLocation then
        defaultPosition = json.encode({
            x = Config.FirstSpawnLocation.x,
            y = Config.FirstSpawnLocation.y,
            z = Config.FirstSpawnLocation.z,
            heading = 0.0,
        })
    end

    MySQL.insert.await(
        [[INSERT INTO users
            (identifier, accounts, `group`, inventory, job, job_grade, loadout, position, firstname, lastname, dateofbirth, sex, height, skin, status)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            identifier,
            defaultAccounts,
            "user",
            json.encode({}),
            "unemployed",
            0,
            json.encode({}),
            defaultPosition,
            firstname,
            lastname,
            data.dob or data.birthdate or "01/01/1990",
            sex,
            tonumber(data.height) or 180,
            json.encode({}),
            json.encode({}),
        }
    )

    Webhooks.Send(
        "create",
        "Character Created",
        ("**%s** created `%s %s` (%s)"):format(GetPlayerName(source), firstname, lastname, identifier),
        65280
    )

    return true, identifier
end

function ESXBridge.DeleteCharacter(source, charId)
    local license = ServerCore.GetLicense(source)
    local owned = MySQL.scalar.await(
        "SELECT identifier FROM users WHERE identifier = ? AND identifier LIKE ? LIMIT 1",
        { charId, getLicensePattern(license) }
    )

    if not owned then
        return false
    end

    for _, entry in ipairs(Config.DeleteTables.esx or {}) do
        pcall(function()
            MySQL.update.await(
                ("DELETE FROM `%s` WHERE `%s` = ?"):format(entry.table, entry.column),
                { charId }
            )
        end)
    end

    Webhooks.Send("delete", "Character Deleted", ("**%s** deleted `%s`"):format(GetPlayerName(source), charId), 16711680)
    return true
end

function ESXBridge.GetCharacterOwnerSource(charId)
    local row = MySQL.single.await("SELECT identifier FROM users WHERE identifier = ? LIMIT 1", { charId })
    if not row then
        return nil
    end

    local licenseSuffix = stripLicensePrefix(row.identifier)
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local playerLicense = ServerCore.GetLicense(src)
        if playerLicense and stripLicensePrefix(playerLicense) == licenseSuffix then
            return src
        end
    end

    return nil
end

function ESXBridge.SearchCharacters(source, query)
    local license = ServerCore.GetLicense(source)
    query = tostring(query or ""):lower()

    if query == "" then
        return {}
    end

    local rows = MySQL.query.await(
        [[SELECT identifier, firstname, lastname FROM users
          WHERE identifier NOT LIKE ?
          AND (LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(identifier) LIKE ?)
          LIMIT 20]],
        {
            getLicensePattern(license),
            "%" .. query .. "%",
            "%" .. query .. "%",
            "%" .. query .. "%",
        }
    ) or {}

    local results = {}
    for _, row in ipairs(rows) do
        local fullName = ("%s %s"):format(row.firstname or "", row.lastname or "")
        results[#results + 1] = {
            id = row.identifier,
            targetId = row.identifier,
            partnerIdentifier = row.identifier,
            name = fullName,
            partnerName = fullName,
        }
    end

    return results
end

function ESXBridge.GetCharacterName(charId)
    local row = MySQL.single.await(
        "SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1",
        { charId }
    )
    if not row then
        return "Unknown"
    end
    return ("%s %s"):format(row.firstname or "Unknown", row.lastname or "")
end

ServerCore.RegisterFrameworkBridge("esx", ESXBridge)

