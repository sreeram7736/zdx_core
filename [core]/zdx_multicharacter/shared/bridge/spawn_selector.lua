

SpawnBridge = SpawnBridge or {}

function IsDirectSpawnMode()
    local mode = Config.SpawnSelector
    return mode == false or mode == "false" or mode == 0 or mode == "0"
end

function IsBuiltinSpawnMode()
    return Config.SpawnSelector == "builtin"
end

local spawnSelectorHandlers = {
    { name = "qs-spawn",          handler = function(charData, isNew) exports["qs-spawn"]:openSpawnSelector(true) end },
    { name = "cd_spawnselect",    handler = function(charData, isNew) Wait(1500); TriggerEvent("cd_spawnselect:OpenUI") end },
    { name = "um-spawn",          handler = function(charData, isNew) TriggerEvent("um-spawn:client:startSpawnUI") end },
    { name = "vms_spawnselector", handler = function(charData, isNew) TriggerEvent("vms_spawnselector:open") end },
    { name = "renzu_spawn",       handler = function(charData, isNew) exports.renzu_spawn:Selector(nil, nil) end },
    { name = "qbx_spawn",         handler = function(charData, isNew) TriggerEvent("qb-spawn:client:setupSpawns", charData and charData.id) end },
    { name = "qb-spawn",          handler = function(charData, isNew)
        TriggerEvent("qb-spawn:client:setupSpawns", charData and charData.id)
        TriggerEvent("qb-spawn:client:openUI", true)
    end },
    { name = "okokSpawnSelector", handler = function(charData, isNew)
        TriggerEvent("okokSpawnSelector:spawnMenu", false, json.decode(charData.position) or charData.position)
    end },
}

local apartmentHandlers = {
    { name = "ps-housing",      handler = function(charData)
        if GetResourceState("qbx_properties") ~= "missing" then
            TriggerEvent("apartments:client:setupSpawnUI")
        else
            TriggerEvent("ps-housing:client:setupSpawnUI", charData, true, true)
        end
    end },
    { name = "qbx_properties",  handler = function(charData) TriggerEvent("apartments:client:setupSpawnUI") end },
    { name = "qb-apartments",   handler = function(charData) TriggerEvent("apartments:client:setupSpawnUI", charData, true, true) end },
    { name = "qbx_apartments",  handler = function(charData) TriggerEvent("apartments:client:setupSpawnUI", charData) end },
    { name = "0r-apartment",    handler = function(charData) TriggerEvent("apartments:client:setupSpawnUI", charData, true, true) end },
    { name = "bcs_housing",     handler = function(charData) TriggerEvent("Housing:client:SetupSpawnUI", charData) end },
    { name = "vms_spawnselector",handler = function(charData) TriggerEvent("vms_spawnselector:open", true) end },
    { name = "okokSpawnSelector",handler = function(charData) TriggerEvent("okokSpawnSelector:spawnMenu", true) end },
}

local function isRunning(name)
    local s = GetResourceState(name)
    return s == "started" or s == "starting"
end

local function resolveSpawnLoc(charData, isNew)
    if charData.position and not isNew then
        return charData.position
    end
    if Config.FirstSpawnLocation then
        return Config.FirstSpawnLocation
    end
    local first = Config.SpawnLocations and Config.SpawnLocations[1]
    return first and vector3(first.coords.x, first.coords.y, first.coords.z)
end

function SpawnBridge.TriggerExternalSpawn(charData, isNew)
    if type(charData) ~= "table" then
        print("^1[ZDX Multichar] TriggerExternalSpawn: charData is nil or invalid â€” aborting.^0")
        return
    end

    if IsDirectSpawnMode() then
        local loc = resolveSpawnLoc(charData, isNew)
        if loc and SpawnBridge.FinishSpawn then
            SpawnBridge.FinishSpawn(loc, 0.0, isNew, charData)
        end
        return
    end

    local cfg    = Config.SpawnSelector or "builtin"
    local aptCfg = Config.SpawnWithApartment
    if aptCfg == nil then aptCfg = "Auto" end

    local shouldCheckApt = aptCfg ~= false and
        (not Config.ApartmentOnlyForNew or (Config.ApartmentOnlyForNew and isNew))

    if shouldCheckApt then
        if aptCfg ~= "Auto" then
            
            for _, tbl in ipairs(apartmentHandlers) do
                if tbl.name == aptCfg or tbl.name:gsub("_", "-") == aptCfg then
                    if isRunning(tbl.name) then
                        tbl.handler(charData)
                        return
                    end
                    print(("^3[ZDX Multichar] SpawnWithApartment = '%s' is configured but not running â€” skipping.^0"):format(aptCfg))
                    break
                end
            end
        else
            
            for _, tbl in ipairs(apartmentHandlers) do
                if isRunning(tbl.name) then
                    tbl.handler(charData)
                    return
                end
            end
        end
    end

    if cfg ~= "builtin" and cfg ~= "Auto" and cfg ~= "custom" then
        for _, tbl in ipairs(spawnSelectorHandlers) do
            if tbl.name == cfg or tbl.name:gsub("_", "-") == cfg or tbl.name:gsub("-", "_") == cfg then
                if isRunning(tbl.name) then
                    tbl.handler(charData, isNew)
                    return
                end
                print(("^3[ZDX Multichar] SpawnSelector = '%s' is configured but not running â€” falling back.^0"):format(cfg))
                break
            end
        end
    end

    if cfg == "Auto" or cfg == "builtin" or cfg == "custom" then
        for _, tbl in ipairs(spawnSelectorHandlers) do
            if isRunning(tbl.name) then
                tbl.handler(charData, isNew)
                return
            end
        end
    end

    if cfg == "custom" and SpawnBridge.OnCharacterSelected then
        SpawnBridge.OnCharacterSelected(charData.id, isNew)
        return
    end

    print("^3[ZDX Multichar] No spawn selector found â€” using fallback spawn location.^0")
    local loc = resolveSpawnLoc(charData, isNew)
    if not loc then
        print("^1[ZDX Multichar] Fallback failed: Config.SpawnLocations is empty. Player may be stuck.^0")
        return
    end
    if not SpawnBridge.FinishSpawn then
        print("^1[ZDX Multichar] Fallback failed: SpawnBridge.FinishSpawn not ready. Player may be stuck.^0")
        return
    end
    SpawnBridge.FinishSpawn(loc, 0.0, isNew, charData)
end

function SpawnBridge.OnCharacterSelected(charId, isNew)
    
end

function SpawnBridge.OnSpawnFinished(coords, heading)
    
end

