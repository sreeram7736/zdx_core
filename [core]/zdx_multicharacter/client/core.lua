
Core = {}
Core.Framework = nil
Core.Obj = nil

local FrameworkResources = {
    esx = { "es_extended", "esx_core" },
    qb  = { "qb-core", "qbx_core" },
}

local ClothingResources = {
    "illenium-appearance",
    "fivem-appearance",
    "qb-clothing",
    "esx_skin",
    "skinchanger"
}

local function DetectFramework()
    if Config.Framework ~= "Auto" then
        return Config.Framework:lower()
    end

    for frameworkName, resources in pairs(FrameworkResources) do
        for _, resourceName in ipairs(resources) do
            if GetResourceState(resourceName) == "started" then
                return frameworkName
            end
        end
    end

    return nil
end

local function InitFrameworkObject(framework)
    if framework == "esx" then
        if GetResourceState("es_extended") == "started" then
            Core.Obj = exports.es_extended:getSharedObject()
        elseif GetResourceState("esx_core") == "started" then
            Core.Obj = exports.esx_core:getSharedObject()
        end
    elseif framework == "qb" then
        if GetResourceState("qb-core") == "started" then
            Core.Obj = exports["qb-core"]:GetCoreObject()
        elseif GetResourceState("qbx_core") == "started" then
            local ok, core = pcall(function()
                return exports.qbx_core:GetCoreObject()
            end)
            if ok and core then
                Core.Obj = core
            else
                Core.Obj = exports["qb-core"]:GetCoreObject()
            end
        end
    end
end

function Core.GetPlayerData()
    if Core.Framework == "esx" then
        return Core.Obj.GetPlayerData()
    elseif Core.Framework == "qb" then
        return Core.Obj.Functions.GetPlayerData()
    end
    return {}
end

function Core.TriggerCallback(callbackName, resultCallback, ...)
    if Core.Framework == "esx" then
        Core.Obj.TriggerServerCallback(callbackName, resultCallback, ...)
    elseif Core.Framework == "qb" then
        Core.Obj.Functions.TriggerCallback(callbackName, resultCallback, ...)
    end
end

function Core.OpenClothing()
    ClothingBridge.OpenMenu()
end

local function DetectClothing()
    if Config.Clothing ~= "Auto" then
        return Config.Clothing
    end

    for _, resourceName in ipairs(ClothingResources) do
        if GetResourceState(resourceName) == "started" then
            Config.Clothing = resourceName
            return resourceName
        end
    end

    return nil
end

CreateThread(function()
    Wait(500)

    Core.Framework = DetectFramework()
    if Core.Framework then
        InitFrameworkObject(Core.Framework)
        print(("[^2zdx_multichar^0] Framework detected: ^3%s^0"):format(Core.Framework))
    else
        print("[^1zdx_multichar^0] WARNING: No framework detected! Set Config.Framework manually.")
    end

    DetectClothing()
    if Config.Clothing then
        print(("[^2zdx_multichar^0] Clothing system detected: ^3%s^0"):format(Config.Clothing))
    else
        print("[^2zdx_multichar^0] No clothing system detected (optional).")
    end
end)

