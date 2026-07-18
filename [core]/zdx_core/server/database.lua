-- ══════════════════════════════════════════════════════════════
-- ZDX Core: Database Layer (oxmysql)
-- ══════════════════════════════════════════════════════════════

ZDX_DB = {}

--- Generate a unique citizen ID
---@return string
function ZDX_DB.GenerateCitizenId()
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = ''
    for _ = 1, 8 do
        local rand = math.random(1, #charset)
        id = id .. charset:sub(rand, rand)
    end
    return id
end

--- Ensure the zdx_users table exists
function ZDX_DB.EnsureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `zdx_users` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `citizenid` VARCHAR(50) DEFAULT NULL,
            `name` VARCHAR(50) NOT NULL DEFAULT 'Unknown',
            `firstname` VARCHAR(50) NOT NULL DEFAULT 'John',
            `lastname` VARCHAR(50) NOT NULL DEFAULT 'Doe',
            `dateofbirth` VARCHAR(20) NOT NULL DEFAULT '2000-01-01',
            `sex` VARCHAR(10) NOT NULL DEFAULT 'm',
            `height` INT(11) NOT NULL DEFAULT 170,
            `accounts` LONGTEXT DEFAULT NULL,
            `job` VARCHAR(50) NOT NULL DEFAULT 'unemployed',
            `job_grade` INT(11) NOT NULL DEFAULT 0,
            `gang` VARCHAR(50) NOT NULL DEFAULT 'none',
            `gang_grade` INT(11) NOT NULL DEFAULT 0,
            `position` LONGTEXT DEFAULT NULL,
            `metadata` LONGTEXT DEFAULT NULL,
            `skin` LONGTEXT DEFAULT NULL,
            `last_logged_out` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print('^2[ZDX-CORE]^0 Database table verified.')
end

--- Load player data from the database
---@param identifier string
---@return table|nil
function ZDX_DB.LoadPlayer(identifier)
    local result = MySQL.single.await(
        'SELECT * FROM `zdx_users` WHERE `identifier` = ?',
        { identifier }
    )
    if result then
        -- Decode JSON fields
        result.accounts = result.accounts and json.decode(result.accounts) or {}
        result.position = result.position and json.decode(result.position) or nil
        result.metadata = result.metadata and json.decode(result.metadata) or {}
        result.skin = result.skin and json.decode(result.skin) or {}
    end
    return result
end

--- Create a new player entry in the database
---@param identifier string
---@param playerName string
---@return table
function ZDX_DB.CreatePlayer(identifier, playerName)
    local citizenid = ZDX_DB.GenerateCitizenId()
    -- Ensure uniqueness
    while MySQL.scalar.await('SELECT 1 FROM `zdx_users` WHERE `citizenid` = ?', { citizenid }) do
        citizenid = ZDX_DB.GenerateCitizenId()
    end

    local accounts = json.encode(Config.StartingAccounts)
    local metadata = json.encode({
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

    MySQL.insert.await(
        'INSERT INTO `zdx_users` (`identifier`, `citizenid`, `name`, `accounts`, `job`, `job_grade`, `gang`, `gang_grade`, `metadata`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { identifier, citizenid, playerName, accounts, Config.DefaultJob, Config.DefaultJobGrade, Config.DefaultGang, Config.DefaultGangGrade, metadata }
    )

    return ZDX_DB.LoadPlayer(identifier)
end

--- Save player data to the database
---@param playerData table
function ZDX_DB.SavePlayer(playerData)
    MySQL.update.await(
        'UPDATE `zdx_users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `gang` = ?, `gang_grade` = ?, `position` = ?, `metadata` = ?, `skin` = ?, `firstname` = ?, `lastname` = ?, `name` = ?, `last_logged_out` = NOW() WHERE `identifier` = ?',
        {
            json.encode(playerData.accounts),
            playerData.job.name,
            playerData.job.grade.level,
            playerData.gang.name,
            playerData.gang.grade.level,
            json.encode(playerData.position),
            json.encode(playerData.metadata),
            json.encode(playerData.skin or {}),
            playerData.charinfo.firstname,
            playerData.charinfo.lastname,
            playerData.name,
            playerData.identifier,
        }
    )
end

--- Save a player's skin data specifically
---@param identifier string
---@param skinData table
function ZDX_DB.SaveSkin(identifier, skinData)
    MySQL.update.await(
        'UPDATE `zdx_users` SET `skin` = ? WHERE `identifier` = ?',
        { json.encode(skinData), identifier }
    )
end

--- Check if a player has skin data saved
---@param identifier string
---@return boolean
function ZDX_DB.HasSkin(identifier)
    local result = MySQL.scalar.await('SELECT `skin` FROM `zdx_users` WHERE `identifier` = ?', { identifier })
    if result and result ~= '' and result ~= '[]' and result ~= '{}' then
        return true
    end
    return false
end

