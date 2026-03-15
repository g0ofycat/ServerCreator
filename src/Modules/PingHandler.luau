--!strict

local PingHandler = {}

--=======================
-- // SERVICES
--=======================

local Players = game:GetService("Players")

--=======================
-- // PUBLIC API
--=======================

-- GetAveragePing(): Get the average ping of the current server (ms)
-- @return: number
function PingHandler.GetAveragePing(): number
    local all_players = Players:GetPlayers()
    if #all_players == 0 then
        return 0
    end

    local total_ping = 0

    for _, player in all_players do
        total_ping += player:GetNetworkPing()
    end

    return math.round((total_ping / #all_players) * 1000)
end

return PingHandler