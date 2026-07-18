-- ══════════════════════════════════════════════════════════════
-- ZDX Framework: Player Class (Server)
-- Full RPG player with money, job, gang, metadata.
-- All events are ZDX-native. Bridges translate to ESX/QB.
-- ══════════════════════════════════════════════════════════════

ZDX = ZDX or {}
ZDX.Players = {}

--- Build a job object from config
---@param jobName string
---@param grade number
---@return table
local function buildJobObject(jobName, grade)
    local jobData = Config.Jobs[jobName]
    if not jobData then
        jobData = Config.Jobs[Config.DefaultJob]
        jobName = Config.DefaultJob
        grade = Config.DefaultJobGrade
    end
    local gradeData = jobData.grades[grade]
    if not gradeData then
        grade = 0
        gradeData = jobData.grades[0]
    end
    return {
        name = jobName,
        label = jobData.label,
        type = jobData.type or 'none',
        onduty = jobData.defaultDuty or false,
        isboss = gradeData.isboss or false,
        payment = gradeData.payment or 0,
        grade = {
            name = gradeData.name,
            label = gradeData.label,
            level = grade,
        }
    }
end

--- Build a gang object from config
---@param gangName string
---@param grade number
---@return table
local function buildGangObject(gangName, grade)
    local gangData = Config.Gangs[gangName]
    if not gangData then
        gangData = Config.Gangs[Config.DefaultGang]
        gangName = Config.DefaultGang
        grade = Config.DefaultGangGrade
    end
    local gradeData = gangData.grades[grade]
    if not gradeData then
        grade = 0
        gradeData = gangData.grades[0]
    end
    return {
        name = gangName,
        label = gangData.label,
        isboss = gradeData.isboss or false,
        grade = {
            name = gradeData.name,
            label = gradeData.label,
            level = grade,
        }
    }
end

--- Create a ZDX Player object with full RPG data
---@param source number
---@param identifier string
---@param dbData table
---@return table
function CreateZDXPlayer(source, identifier, dbData)
    local self = {}
    self.Functions = {}
    self.Offline = false

    -- ── Core Identifiers ──
    self.source = source
    self.identifier = identifier
    self.citizenid = dbData.citizenid
    self.name = dbData.name or GetPlayerName(source)
    self.license = identifier

    -- ── Character Info ──
    self.charinfo = {
        firstname = dbData.firstname or 'John',
        lastname = dbData.lastname or 'Doe',
        birthdate = dbData.dateofbirth or '2000-01-01',
        gender = (dbData.sex == 'f') and 1 or 0,
        nationality = 'USA',
        phone = tostring(math.random(1000000000, 9999999999)),
        account = 'US0' .. math.random(1, 9) .. 'ZDX' .. math.random(1111, 9999),
        cid = 1,
    }

    -- ── PlayerData (unified table) ──
    self.PlayerData = {}

    -- ── Money / Accounts ──
    self.accounts = {}
    for accountName, startAmount in pairs(Config.StartingAccounts) do
        self.accounts[accountName] = dbData.accounts and dbData.accounts[accountName] or startAmount
    end

    -- ── Job ──
    self.job = buildJobObject(dbData.job or Config.DefaultJob, dbData.job_grade or Config.DefaultJobGrade)

    -- ── Gang ──
    self.gang = buildGangObject(dbData.gang or Config.DefaultGang, dbData.gang_grade or Config.DefaultGangGrade)

    -- ── Position ──
    self.position = dbData.position or Config.DefaultSpawn

    -- ── Metadata ──
    self.metadata = dbData.metadata or {
        health = 200,
        armor = 0,
        hunger = 100,
        thirst = 100,
        stress = 0,
        isdead = false,
        ishandcuffed = false,
        inlaststand = false,
        injail = 0,
    }

    -- ── Skin ──
    self.skin = dbData.skin or {}

    -- ── Inventory (placeholder for ox_inventory or similar) ──
    self.items = {}
    self.inventory = {}
    self.loadout = {}
    self.weight = 0
    self.maxWeight = 120000

    -- ══════════════════════════════════════════════════════════
    -- PLAYER FUNCTIONS
    -- ══════════════════════════════════════════════════════════

    -- ── Money Functions ──
    function self.Functions.AddMoney(moneyType, amount, reason)
        if not self.accounts[moneyType] then return false end
        amount = tonumber(amount)
        if not amount or amount <= 0 then return false end
        self.accounts[moneyType] = self.accounts[moneyType] + amount
        self.Functions.UpdatePlayerData()
        TriggerEvent('zdx:moneyChange', self.source, moneyType, amount, 'add', reason or 'unknown')
        TriggerClientEvent('zdx:client:moneyChange', self.source, moneyType, amount, 'add', reason or 'unknown')
        return true
    end

    function self.Functions.RemoveMoney(moneyType, amount, reason)
        if not self.accounts[moneyType] then return false end
        amount = tonumber(amount)
        if not amount or amount <= 0 then return false end
        if self.accounts[moneyType] < amount then return false end
        self.accounts[moneyType] = self.accounts[moneyType] - amount
        self.Functions.UpdatePlayerData()
        TriggerEvent('zdx:moneyChange', self.source, moneyType, amount, 'remove', reason or 'unknown')
        TriggerClientEvent('zdx:client:moneyChange', self.source, moneyType, amount, 'remove', reason or 'unknown')
        return true
    end

    function self.Functions.SetMoney(moneyType, amount, reason)
        if not self.accounts[moneyType] then return false end
        amount = tonumber(amount)
        if not amount or amount < 0 then return false end
        self.accounts[moneyType] = amount
        self.Functions.UpdatePlayerData()
        return true
    end

    function self.Functions.GetMoney(moneyType)
        if moneyType then
            return self.accounts[moneyType] or 0
        end
        return self.accounts
    end

    -- ── Job Functions ──
    function self.Functions.SetJob(jobName, grade)
        local newJob = buildJobObject(jobName, grade or 0)
        local oldJob = self.job
        self.job = newJob
        self.Functions.UpdatePlayerData()
        TriggerEvent('zdx:jobUpdate', self.source, self.job, oldJob)
        TriggerClientEvent('zdx:client:jobUpdate', self.source, self.job)
        return true
    end

    function self.Functions.SetJobDuty(onDuty)
        self.job.onduty = onDuty
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.GetJob()
        return {
            id = 0,
            name = self.job.name,
            label = self.job.label,
            type = self.job.type,
            grade = self.job.grade.level,
            grade_name = self.job.grade.name,
            grade_label = self.job.grade.label or self.job.grade.name,
            grade_salary = self.job.payment,
        }
    end

    -- ── Gang Functions ──
    function self.Functions.SetGang(gangName, grade)
        self.gang = buildGangObject(gangName, grade or 0)
        self.Functions.UpdatePlayerData()
        TriggerEvent('zdx:gangUpdate', self.source, self.gang)
        TriggerClientEvent('zdx:client:gangUpdate', self.source, self.gang)
        return true
    end

    -- ── Metadata ──
    function self.Functions.SetMetaData(meta, val)
        self.metadata[meta] = val
        self.Functions.UpdatePlayerData()
    end

    function self.Functions.GetMetaData(meta)
        if meta then return self.metadata[meta] end
        return self.metadata
    end

    -- ── Skin ──
    function self.Functions.SetSkin(skinData)
        self.skin = skinData
        self.Functions.UpdatePlayerData()
        ZDX_DB.SaveSkin(self.identifier, self.skin)
    end

    function self.Functions.GetSkin()
        return self.skin
    end

    -- ── Notify ──
    function self.Functions.Notify(msg, nType, duration)
        TriggerClientEvent('zdx:showNotification', self.source, msg, nType or 'info', duration or 5000)
    end

    -- ── Account Functions ──
    function self.Functions.GetAccount(accountName)
        for name, money in pairs(self.accounts) do
            if name == accountName then
                return { name = name, money = money, label = name:sub(1, 1):upper() .. name:sub(2) }
            end
        end
        return nil
    end

    function self.Functions.GetAccounts()
        local result = {}
        for name, money in pairs(self.accounts) do
            result[#result + 1] = { name = name, money = money, label = name:sub(1, 1):upper() .. name:sub(2) }
        end
        return result
    end

    function self.Functions.AddAccountMoney(accountName, amount, reason)
        return self.Functions.AddMoney(accountName, amount, reason)
    end

    function self.Functions.RemoveAccountMoney(accountName, amount, reason)
        return self.Functions.RemoveMoney(accountName, amount, reason)
    end

    function self.Functions.SetAccountMoney(accountName, amount, reason)
        return self.Functions.SetMoney(accountName, amount, reason)
    end

    -- ── Identity ──
    function self.Functions.GetName()
        return self.charinfo.firstname .. ' ' .. self.charinfo.lastname
    end

    function self.Functions.GetIdentifier()
        return self.identifier
    end

    -- ── Coords ──
    function self.Functions.GetCoords(useVector)
        local ped = GetPlayerPed(self.source)
        if ped and ped > 0 then
            local coords = GetEntityCoords(ped)
            if useVector then
                return coords
            end
            return { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) }
        end
        return self.position
    end

    -- ── Notification ──
    function self.Functions.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
        TriggerClientEvent('zdx:showNotification', self.source, msg)
    end

    -- ── Inventory stubs (routes to ox_inventory if available) ──
    function self.Functions.AddItem(item, count, slot, metadata)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:AddItem(self.source, item, count, metadata, slot)
        end
        return false
    end

    function self.Functions.RemoveItem(item, count, slot)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:RemoveItem(self.source, item, count, nil, slot)
        end
        return false
    end

    function self.Functions.GetItemByName(itemName)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:GetSlotWithItem(self.source, itemName)
        end
        return nil
    end

    function self.Functions.GetItemsByName(itemName)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:GetSlotsWithItem(self.source, itemName)
        end
        return {}
    end

    function self.Functions.ClearInventory()
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:ClearInventory(self.source)
        end
    end

    function self.Functions.GetInventory()
        return self.inventory
    end

    function self.Functions.GetLoadout()
        return self.loadout
    end

    function self.Functions.GetMaxWeight()
        return self.maxWeight
    end

    -- ── Save Player ──
    function self.Functions.Save()
        local ped = GetPlayerPed(self.source)
        if ped and ped > 0 then
            local coords = GetEntityCoords(ped)
            self.position = { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) }
        end
        self.Functions.BuildPlayerData()
        ZDX_DB.SavePlayer(self.PlayerData)
    end

    -- ── Build the unified PlayerData table ──
    function self.Functions.BuildPlayerData()
        self.PlayerData = {
            source = self.source,
            citizenid = self.citizenid,
            license = self.license,
            name = self.name,
            charinfo = self.charinfo,
            money = self.accounts,
            job = self.job,
            gang = self.gang,
            position = self.position,
            metadata = self.metadata,
            skin = self.skin,
            items = self.items,
            identifier = self.identifier,
            accounts = self.accounts,
        }
        return self.PlayerData
    end

    -- ── Sync PlayerData to client ──
    function self.Functions.UpdatePlayerData()
        self.Functions.BuildPlayerData()
        TriggerEvent('zdx:playerDataUpdate', self.source, self.PlayerData)
        TriggerClientEvent('zdx:client:playerDataUpdate', self.source, self.PlayerData)
    end

    -- ── Kick ──
    function self.Functions.Kick(reason)
        DropPlayer(tostring(self.source), reason or 'Kicked')
    end

    -- ── Initialize PlayerData ──
    self.Functions.BuildPlayerData()

    -- ── Register in global table ──
    ZDX.Players[source] = self
    return self
end

--- Get a player by source
---@param source number
---@return table|nil
function GetZDXPlayer(source)
    if tonumber(source) then
        return ZDX.Players[tonumber(source)]
    end
    return nil
end

--- Get a player by identifier
---@param identifier string
---@return table|nil
function GetZDXPlayerByIdentifier(identifier)
    for _, player in pairs(ZDX.Players) do
        if player.identifier == identifier then
            return player
        end
    end
    return nil
end

--- Get a player by citizenid
---@param citizenid string
---@return table|nil
function GetZDXPlayerByCitizenId(citizenid)
    for _, player in pairs(ZDX.Players) do
        if player.citizenid == citizenid then
            return player
        end
    end
    return nil
end

--- Get all players
---@return table
function GetZDXPlayers()
    return ZDX.Players
end

-- ── Exports ──
exports('GetPlayer', GetZDXPlayer)
exports('GetPlayerByIdentifier', GetZDXPlayerByIdentifier)
exports('GetPlayerByCitizenId', GetZDXPlayerByCitizenId)
exports('GetPlayers', GetZDXPlayers)
