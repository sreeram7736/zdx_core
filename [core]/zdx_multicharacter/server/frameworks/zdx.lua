if ServerCore.Framework ~= "zdx" then
    return
end

local ZDX = ServerCore.Obj
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
        "SELECT COUNT(*) FROM zdx_users WHERE identifier LIKE ?",
        { "%:" .. stripLicensePrefix(license) }
    )
    return count or 0
end

local function findNextSlot(license, maxSlots)
    for slot = 1, maxSlots do
        local identifier = ("char%d:%s"):format(slot, stripLicensePrefix(license))
        local exists = MySQL.scalar.await("SELECT identifier FROM zdx_users WHERE identifier = ? LIMIT 1", { identifier })
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

    local jobName = row.job or "unemployed"
    local jobGrade = tonumber(row.job_grade) or 0
    local jobLabel = "Unemployed"
    
    if ZDX.Jobs and ZDX.Jobs[jobName] then
        jobLabel = ZDX.Jobs[jobName].label
    end

    return {
        id = row.identifier,
        citizenid = row.citizenid or row.identifier,
        cid = getSlotFromIdentifier(row.identifier),
        firstname = row.firstname or "Unknown",
        lastname = row.lastname or "Unknown",
        dob = row.dateofbirth or "",
        gender = gender,
        nationality = "Unknown",
        backstory = "",
        height = row.height or 180,
        job = {
            name = jobName,
            label = jobLabel,
            grade = jobGrade,
        },
        money = {
            bank = accounts.bank or 0,
            cash = accounts.money or 0,
        },
        position = position,
        playtime = getPlaytime(row.identifier),
    }
end

local function buildAppearance(identifier, sex)
    local row = MySQL.single.await("SELECT skin, sex FROM zdx_users WHERE identifier = ? LIMIT 1", { identifier })
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

local ZDXBridge = {}

function ZDXBridge.GetCharacters(source)
    local license = ServerCore.GetLicense(source)
    if not license then
        return {}
    end

    local rows = MySQL.query.await(
        "SELECT * FROM zdx_users WHERE identifier LIKE ? ORDER BY identifier ASC",
        { "%:" .. stripLicensePrefix(license) }
    ) or {}

    local characters = {}
    for _, row in ipairs(rows) do
        characters[#characters + 1] = formatCharacter(row)
    end

    return characters
end

function ZDXBridge.GetCharacterById(charId, source)
    if not charId then return nil end
    local row = MySQL.single.await("SELECT * FROM zdx_users WHERE identifier = ? LIMIT 1", { charId })
    if row then
        return formatCharacter(row)
    end
    return nil
end

function ZDXBridge.GetMaxCharacters(source)
    -- In zdx_core, you can fetch max characters from shared config if needed, or fallback
    return Config.MaxCharacters or 5
end

function ZDXBridge.GetAppearance(charId, callback)
    callback(buildAppearance(charId))
end

function ZDXBridge.PreviewCharacter(source, charId)
    local license = ServerCore.GetLicense(source)
    local owned = MySQL.scalar.await(
        "SELECT identifier FROM zdx_users WHERE identifier = ? AND identifier LIKE ? LIMIT 1",
        { charId, getLicensePattern(license) }
    )

    if not owned then
        return
    end

    ZDXBridge.GetAppearance(charId, function(appearance)
        if appearance then
            TriggerClientEvent("zdx_multichar:client:previewPed", source, appearance.model, appearance)
        end
    end)
end

function ZDXBridge.SelectCharacter(source, charId)
    local license = ServerCore.GetLicense(source)
    local owned = MySQL.scalar.await(
        "SELECT identifier FROM zdx_users WHERE identifier = ? AND identifier LIKE ? LIMIT 1",
        { charId, getLicensePattern(license) }
    )

    if not owned then
        return false
    end

    TriggerEvent("zdx_core:server:loadCharacter", source, charId)
    TriggerClientEvent("zdx_multichar:client:onPlayerLoaded", source)
    Webhooks.Send("login", "Character Selected", ("**%s** loaded character `%s`"):format(GetPlayerName(source), charId))
    return true
end

function ZDXBridge.CreateCharacter(source, data)
    local license = ServerCore.GetLicense(source)
    if not license then
        return false, "missing_license"
    end

    local maxSlots = Config.MaxCharacters or 5
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
    local playerName = GetPlayerName(source)

    local defaultAccounts = json.encode({ bank = 5000, money = 500 })
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
    
    local defaultMetadata = json.encode({
        health = 200,
        armor = 0,
        hunger = 100,
        thirst = 100,
        stress = 0,
        isdead = false,
        ishandcuffed = false,
        inlaststand = false,
        injail = 0,
    })

    -- Generate a unique citizen ID
    local citizenid = ""
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for _ = 1, 8 do
        local rand = math.random(1, #charset)
        citizenid = citizenid .. charset:sub(rand, rand)
    end
    
    while MySQL.scalar.await('SELECT 1 FROM `zdx_users` WHERE `citizenid` = ?', { citizenid }) do
        citizenid = ""
        for _ = 1, 8 do
            local rand = math.random(1, #charset)
            citizenid = citizenid .. charset:sub(rand, rand)
        end
    end

    MySQL.insert.await(
        [[INSERT INTO zdx_users
            (identifier, citizenid, name, firstname, lastname, dateofbirth, sex, height, accounts, job, job_grade, gang, gang_grade, position, metadata, skin)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            identifier,
            citizenid,
            playerName,
            firstname,
            lastname,
            data.dob or data.birthdate or "2000-01-01",
            sex,
            tonumber(data.height) or 180,
            defaultAccounts,
            "unemployed",
            0,
            "none",
            0,
            defaultPosition,
            defaultMetadata,
            json.encode({}),
        }
    )

    Webhooks.Send(
        "create",
        "Character Created",
        ("**%s** created `%s %s` (%s)"):format(playerName, firstname, lastname, identifier),
        65280
    )

    return true, identifier
end

function ZDXBridge.DeleteCharacter(source, charId)
    local license = ServerCore.GetLicense(source)
    local owned = MySQL.scalar.await(
        "SELECT identifier FROM zdx_users WHERE identifier = ? AND identifier LIKE ? LIMIT 1",
        { charId, getLicensePattern(license) }
    )

    if not owned then
        return false
    end

    for _, entry in ipairs(Config.DeleteTables.zdx or {}) do
        pcall(function()
            MySQL.update.await(
                ("DELETE FROM `%s` WHERE `%s` = ?"):format(entry.table, entry.column),
                { charId }
            )
        end)
    end

    MySQL.update.await("DELETE FROM zdx_users WHERE identifier = ?", { charId })

    Webhooks.Send("delete", "Character Deleted", ("**%s** deleted `%s`"):format(GetPlayerName(source), charId), 16711680)
    return true
end

function ZDXBridge.GetCharacterOwnerSource(charId)
    local row = MySQL.single.await("SELECT identifier FROM zdx_users WHERE identifier = ? LIMIT 1", { charId })
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

function ZDXBridge.SearchCharacters(source, query)
    local license = ServerCore.GetLicense(source)
    query = tostring(query or ""):lower()

    if query == "" then
        return {}
    end

    local rows = MySQL.query.await(
        [[SELECT identifier, firstname, lastname, citizenid FROM zdx_users
          WHERE identifier NOT LIKE ?
          AND (LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(identifier) LIKE ? OR LOWER(citizenid) LIKE ?)
          LIMIT 20]],
        {
            getLicensePattern(license),
            "%" .. query .. "%",
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
            partnerIdentifier = row.citizenid,
            name = fullName,
            partnerName = fullName,
        }
    end

    return results
end

function ZDXBridge.GetCharacterName(charId)
    local row = MySQL.single.await(
        "SELECT firstname, lastname FROM zdx_users WHERE identifier = ? LIMIT 1",
        { charId }
    )
    if not row then
        return "Unknown"
    end
    return ("%s %s"):format(row.firstname or "Unknown", row.lastname or "")
end

ServerCore.RegisterFrameworkBridge("zdx", ZDXBridge)
