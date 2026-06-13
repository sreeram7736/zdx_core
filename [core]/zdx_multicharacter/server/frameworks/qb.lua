
if ServerCore.Framework ~= "qb" then
    return
end

local QBCore = ServerCore.Obj
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

local function getPlaytime(charId)
    local row = MySQL.single.await("SELECT playtime FROM zdx_playtime WHERE char_id = ?", { charId })
    return row and row.playtime or 0
end

local function getNextCitizenId()
    local unique = false
    local citizenId = nil

    while not unique do
        citizenId = QBCore.Shared.RandomStr(3) .. QBCore.Shared.RandomInt(5)
        local exists = MySQL.scalar.await("SELECT citizenid FROM players WHERE citizenid = ?", { citizenId })
        unique = not exists
    end

    return citizenId
end

local function getUsedSlots(license)
    return MySQL.scalar.await("SELECT COUNT(*) FROM players WHERE license = ?", { license }) or 0
end

local function findNextSlot(license, maxSlots)
    local rows = MySQL.query.await("SELECT cid FROM players WHERE license = ? ORDER BY cid ASC", { license }) or {}
    local used = {}

    for _, row in ipairs(rows) do
        used[tonumber(row.cid) or row.cid] = true
    end

    for slot = 1, maxSlots do
        if not used[slot] then
            return slot
        end
    end

    return nil
end

local function formatCharacter(row)
    local charinfo = decodeJson(row.charinfo, {})
    local money = decodeJson(row.money, { bank = 0, cash = 0 })
    local job = decodeJson(row.job, { name = "unemployed", label = "Unemployed", grade = { level = 0, name = "0" } })
    local position = decodeJson(row.position, nil)

    local gender = 0
    if charinfo.gender == 1 or charinfo.gender == "1" or charinfo.gender == "female" then
        gender = 1
    end

    return {
        id = row.citizenid,
        citizenid = row.citizenid,
        cid = row.cid,
        firstname = charinfo.firstname or "Unknown",
        lastname = charinfo.lastname or "Unknown",
        dob = charinfo.birthdate or charinfo.dob or "",
        gender = gender,
        nationality = charinfo.nationality or "",
        backstory = charinfo.backstory or "",
        height = charinfo.height or 180,
        job = {
            name = job.name or "unemployed",
            label = job.label or "Unemployed",
            grade = job.grade and (job.grade.level or job.grade) or 0,
        },
        money = {
            bank = money.bank or 0,
            cash = money.cash or money.crypto or 0,
        },
        position = position,
        playtime = getPlaytime(row.citizenid),
    }
end

local function getSkinRow(citizenId)
    return MySQL.single.await(
        "SELECT model, skin FROM playerskins WHERE citizenid = ? AND active = 1 LIMIT 1",
        { citizenId }
    )
end

local function buildAppearance(citizenId, genderFallback)
    local skinRow = getSkinRow(citizenId)
    local model = freemodeMale
    local skin = {}

    if skinRow then
        model = tonumber(skinRow.model) or joaat(skinRow.model or "mp_m_freemode_01")
        skin = decodeJson(skinRow.skin, {})
    elseif genderFallback == 1 then
        model = freemodeFemale
    end

    return {
        model = model,
        skin = skin,
    }
end

local function isCharacterOwned(source, charId)
    local license = ServerCore.GetLicense(source)
    if not license or not charId then
        return false
    end

    local license2 = ServerCore.GetIdentifier(source, "license2")
    if license2 and license2 ~= license then
        local owned = MySQL.scalar.await(
            "SELECT citizenid FROM players WHERE citizenid = ? AND (license = ? OR license = ?) LIMIT 1",
            { charId, license, license2 }
        )
        return owned ~= nil
    end

    local owned = MySQL.scalar.await(
        "SELECT citizenid FROM players WHERE citizenid = ? AND license = ? LIMIT 1",
        { charId, license }
    )
    return owned ~= nil
end

local function giveStarterItems(source)
    if not Config.StarterItems or type(Config.StarterItems) ~= "table" then
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return
    end

    for _, entry in ipairs(Config.StarterItems) do
        if entry.item and entry.count then
            player.Functions.AddItem(entry.item, entry.count)
        end
    end
end

local QBBridge = {}

function QBBridge.GetCharacters(source)
    local license = ServerCore.GetLicense(source)
    if not license then
        return {}
    end

    local license2 = ServerCore.GetIdentifier(source, "license2")
    local rows

    if license2 and license2 ~= license then
        rows = MySQL.query.await(
            "SELECT * FROM players WHERE license = ? OR license = ? ORDER BY cid ASC",
            { license, license2 }
        ) or {}
    else
        rows = MySQL.query.await("SELECT * FROM players WHERE license = ? ORDER BY cid ASC", { license }) or {}
    end

    local characters = {}

    for _, row in ipairs(rows) do
        characters[#characters + 1] = formatCharacter(row)
    end

    return characters
end

function QBBridge.GetCharacterById(citizenId, source)
    if not citizenId then
        return nil
    end

    local license = ServerCore.GetLicense(source)
    local row

    if license then
        row = MySQL.single.await(
            "SELECT * FROM players WHERE citizenid = ? AND license = ? LIMIT 1",
            { citizenId, license }
        )
    end

    if not row then
        row = MySQL.single.await("SELECT * FROM players WHERE citizenid = ? LIMIT 1", { citizenId })
    end

    if row then
        return formatCharacter(row)
    end

    return nil
end

function QBBridge.GetMaxCharacters(source)
    local license = ServerCore.GetLicense(source)
    return GetMaxCharactersForLicense(license)
end

function QBBridge.GetAppearance(charId, callback)
    local row = MySQL.single.await("SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1", { charId })
    local gender = 0

    if row then
        local charinfo = decodeJson(row.charinfo, {})
        if charinfo.gender == 1 or charinfo.gender == "1" or charinfo.gender == "female" then
            gender = 1
        end
    end

    callback(buildAppearance(charId, gender))
end

function QBBridge.PreviewCharacter(source, charId)
    if not isCharacterOwned(source, charId) then
        if Config.Debug then
            print(("[zdx Multichar] PreviewCharacter rejected for %s (ownership check failed)"):format(tostring(charId)))
        end
        TriggerClientEvent("zdx_multichar:client:previewFailed", source)
        return
    end

    QBBridge.GetAppearance(charId, function(appearance)
        if appearance then
            TriggerClientEvent("zdx_multichar:client:previewPed", source, appearance.model, appearance)
        end
    end)
end

function QBBridge.SelectCharacter(source, charId)
    if not isCharacterOwned(source, charId) then
        if Config.Debug then
            print(("[zdx Multichar] SelectCharacter rejected for %s (ownership check failed)"):format(tostring(charId)))
        end
        return false
    end

    local loggedIn = QBCore.Player.Login(source, charId)
    if loggedIn then
        QBCore.Commands.Refresh(source)

        local player = QBCore.Functions.GetPlayer(source)
        if player and player.PlayerData.metadata and player.PlayerData.metadata.isNewChar then
            giveStarterItems(source)
            player.Functions.SetMetaData("isNewChar", nil)
        end

        TriggerClientEvent("zdx_multichar:client:onPlayerLoaded", source)
        Webhooks.Send("login", "Character Selected", ("**%s** loaded character `%s`"):format(GetPlayerName(source), charId))
    end

    return loggedIn
end

function QBBridge.CreateCharacter(source, data)
    local license = ServerCore.GetLicense(source)
    if not license then
        return false, "missing_license"
    end

    local maxSlots = GetMaxCharactersForLicense(license)
    local usedSlots = getUsedSlots(license)
    if usedSlots >= maxSlots then
        return false, "max_characters"
    end

    local slot = findNextSlot(license, maxSlots)
    if not slot then
        return false, "no_slot"
    end

    local gender = 0
    if data.gender == 1 or data.gender == "1" or data.gender == "female" or data.gender == "Female" then
        gender = 1
    end

    local charinfo = {
        firstname = data.firstname,
        lastname = data.lastname,
        birthdate = data.dob or data.birthdate,
        gender = gender,
        nationality = data.nationality or "American",
        backstory = data.backstory or "",
        height = tonumber(data.height) or 180,
        phone = QBCore.Functions.CreatePhoneNumber and QBCore.Functions.CreatePhoneNumber() or tostring(math.random(1000000, 9999999)),
        account = QBCore.Functions.CreateAccountNumber and QBCore.Functions.CreateAccountNumber() or tostring(math.random(100000, 999999)),
    }

    local citizenId = getNextCitizenId()
    local spawnCoords = Config.FirstSpawnLocation or vector3(-1037.93, -2738.13, 20.17)
    local position = {
        x = spawnCoords.x,
        y = spawnCoords.y,
        z = spawnCoords.z,
        w = 0.0,
    }

    MySQL.insert.await(
        [[INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            citizenId,
            slot,
            license,
            charinfo.firstname .. " " .. charinfo.lastname,
            json.encode({ cash = 500, bank = 5000, crypto = 0 }),
            json.encode(charinfo),
            json.encode({
                name = "unemployed",
                label = "Civilian",
                payment = 10,
                onduty = true,
                isboss = false,
                grade = { name = "Freelancer", level = 0 },
            }),
            json.encode({
                name = "none",
                label = "No Gang Affiliation",
                isboss = false,
                grade = { name = "none", level = 0 },
            }),
            json.encode(position),
            json.encode({ isNewChar = true }),
        }
    )

    Webhooks.Send(
        "create",
        "Character Created",
        ("**%s** created `%s %s` (%s)"):format(GetPlayerName(source), charinfo.firstname, charinfo.lastname, citizenId),
        65280
    )

    return true, citizenId
end

function QBBridge.DeleteCharacter(source, charId)
    local license = ServerCore.GetLicense(source)
    local owned = MySQL.scalar.await(
        "SELECT citizenid FROM players WHERE citizenid = ? AND license = ? LIMIT 1",
        { charId, license }
    )

    if not owned then
        return false
    end

    for _, entry in ipairs(Config.DeleteTables.qb or {}) do
        pcall(function()
            MySQL.update.await(
                ("DELETE FROM `%s` WHERE `%s` = ?"):format(entry.table, entry.column),
                { charId }
            )
        end)
    end

    MySQL.update.await("DELETE FROM players WHERE citizenid = ?", { charId })

    Webhooks.Send("delete", "Character Deleted", ("**%s** deleted `%s`"):format(GetPlayerName(source), charId), 16711680)
    return true
end

function QBBridge.GetCharacterOwnerSource(charId)
    local row = MySQL.single.await("SELECT license FROM players WHERE citizenid = ? LIMIT 1", { charId })
    if not row or not row.license then
        return nil
    end

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if ServerCore.GetLicense(src) == row.license then
            return src
        end
    end

    return nil
end

function QBBridge.SearchCharacters(source, query)
    local license = ServerCore.GetLicense(source)
    query = tostring(query or ""):lower()

    if query == "" then
        return {}
    end

    local rows = MySQL.query.await(
        [[SELECT citizenid, charinfo FROM players
          WHERE license <> ?
          AND (LOWER(charinfo) LIKE ? OR LOWER(citizenid) LIKE ?)
          LIMIT 20]],
        { license, "%" .. query .. "%", "%" .. query .. "%" }
    ) or {}

    local results = {}
    for _, row in ipairs(rows) do
        local charinfo = decodeJson(row.charinfo, {})
        local fullName = ("%s %s"):format(charinfo.firstname or "", charinfo.lastname or "")
        if fullName:lower():find(query, 1, true) or tostring(row.citizenid):lower():find(query, 1, true) then
            results[#results + 1] = {
                id = row.citizenid,
                targetId = row.citizenid,
                partnerIdentifier = row.citizenid,
                name = fullName,
                partnerName = fullName,
            }
        end
    end

    return results
end

function QBBridge.GetCharacterName(charId)
    local row = MySQL.single.await("SELECT charinfo FROM players WHERE citizenid = ? LIMIT 1", { charId })
    if not row then
        return "Unknown"
    end
    local charinfo = decodeJson(row.charinfo, {})
    return ("%s %s"):format(charinfo.firstname or "Unknown", charinfo.lastname or "")
end

ServerCore.RegisterFrameworkBridge("qb", QBBridge)

