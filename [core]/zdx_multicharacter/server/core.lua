
ServerCore = ServerCore or {}
ServerCore.Framework = nil
ServerCore.Obj = nil
ServerCore.FrameworkBridge = nil

local FrameworkResources = {
    esx = { "es_extended", "esx_core" },
    qb = { "qb-core", "qbx_core" },
    zdx = { "zdx_core" },
}

function ServerCore.DetectFramework()
    local configured = Config.Framework
    if configured and configured ~= "Auto" and configured ~= "auto" then
        return configured:lower()
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

function ServerCore.InitFrameworkObject(framework)
    if framework == "esx" then
        if GetResourceState("es_extended") == "started" then
            ServerCore.Obj = exports.es_extended:getSharedObject()
        elseif GetResourceState("esx_core") == "started" then
            ServerCore.Obj = exports.esx_core:getSharedObject()
        end
    elseif framework == "qb" then
        if GetResourceState("qb-core") == "started" then
            ServerCore.Obj = exports["qb-core"]:GetCoreObject()
        elseif GetResourceState("qbx_core") == "started" then
            local ok, core = pcall(function()
                return exports.qbx_core:GetCoreObject()
            end)
            if ok and core then
                ServerCore.Obj = core
            else
                ServerCore.Obj = exports["qb-core"]:GetCoreObject()
            end
        end
    elseif framework == "zdx" then
        if GetResourceState("zdx_core") == "started" then
            ServerCore.Obj = exports["zdx_core"]:GetCoreObject()
        end
    end
end

function ServerCore.GetIdentifier(source, idType)
    if ServerCore.Framework == "qb" and ServerCore.Obj then
        return ServerCore.Obj.Functions.GetIdentifier(source, idType or "license")
    end

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find(idType or "license", 1, true) then
            return identifier
        end
    end

    return nil
end

function ServerCore.GetLicense(source)
    local license = ServerCore.GetIdentifier(source, "license")
    if license then
        return license
    end
    return ServerCore.GetIdentifier(source, "license2")
end

function ServerCore.CreateCallback(name, handler)
    if ServerCore.Framework == "qb" and ServerCore.Obj then
        ServerCore.Obj.Functions.CreateCallback(name, handler)
    elseif ServerCore.Framework == "esx" and ServerCore.Obj then
        ServerCore.Obj.RegisterServerCallback(name, handler)
    elseif ServerCore.Framework == "zdx" and ServerCore.Obj then
        ServerCore.Obj.RegisterCallback(name, handler)
    end
end

function ServerCore.RegisterFrameworkBridge(frameworkName, bridge)
    if ServerCore.Framework ~= frameworkName then
        return
    end
    ServerCore.FrameworkBridge = bridge
end

function ServerCore.GetPlayer(source)
    if ServerCore.Framework == "qb" and ServerCore.Obj then
        return ServerCore.Obj.Functions.GetPlayer(source)
    elseif ServerCore.Framework == "esx" and ServerCore.Obj then
        return ServerCore.Obj.GetPlayerFromId(source)
    elseif ServerCore.Framework == "zdx" and ServerCore.Obj then
        return ServerCore.Obj.GetPlayer(source)
    end
    return nil
end

ServerCore.Framework = ServerCore.DetectFramework()
if ServerCore.Framework then
    ServerCore.InitFrameworkObject(ServerCore.Framework)
    print(("[^2zdx Multichar^0] Server framework: ^3%s^0"):format(ServerCore.Framework))
else
    print("[^1zdx Multichar^0] No framework detected on server. Set Config.Framework manually.")
end

