
ClothingBridge = ClothingBridge or {}

function ClothingBridge.GetAppearanceForCharacter(charId, callback)
    if ServerCore and ServerCore.FrameworkBridge and ServerCore.FrameworkBridge.GetAppearance then
        ServerCore.FrameworkBridge.GetAppearance(charId, callback)
        return
    end

    callback(nil)
end

