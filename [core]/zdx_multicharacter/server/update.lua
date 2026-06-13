
local function runQuery(query)
    local ok, err = pcall(function()
        MySQL.query.await(query)
    end)

    if not ok and Config.Debug then
        print(("[ZDX Multichar] SQL migration warning: %s"):format(err))
    end
end

CreateThread(function()
    Wait(1000)

    runQuery([[
        CREATE TABLE IF NOT EXISTS `zdx_playtime` (
            `char_id` VARCHAR(60) NOT NULL,
            `playtime` INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`char_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    if Config.Debug then
        print("[^2ZDX Multichar^0] Database tables verified.")
    end
end)

local function trackPlaytime()
    CreateThread(function()
        while true do
            Wait(60000)

            if ServerCore.Framework ~= "qb" or not ServerCore.Obj then
                goto continue
            end

            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                local player = ServerCore.Obj.Functions.GetPlayer(src)
                if player and player.PlayerData and player.PlayerData.citizenid then
                    local charId = player.PlayerData.citizenid
                    MySQL.update.await(
                        [[INSERT INTO zdx_playtime (char_id, playtime) VALUES (?, 1)
                          ON DUPLICATE KEY UPDATE playtime = playtime + 1]],
                        { charId }
                    )
                end
            end

            ::continue::
        end
    end)
end

CreateThread(function()
    while not ServerCore.Framework do
        Wait(500)
    end
    trackPlaytime()
end)

