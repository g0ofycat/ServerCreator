--!strict

local ServerCallbacks = {}

--=======================
-- // SERVICES
--=======================

local MessagingService = game:GetService("MessagingService")

--=======================
-- // MODULES
--=======================

local Types = require("../Utility/Types")

local Config = require("../Utility/Config")

local LocalData = require("../Data/LocalData")

--=======================
-- // PUBLIC API
--=======================

-- Init(): Initializes the server signals and subscribes
function ServerCallbacks.Init(): ()
	MessagingService:SubscribeAsync("ServerCreated", function(packet)
		local msg = packet.Data

		LocalData.SetServerEntry(msg.Code, msg.Data)

		Config.SIGNALS.OnServerCreated:Fire(msg)

		print(`ServerCreated(): { msg.Code }`)
	end)

	MessagingService:SubscribeAsync("ServerUpdated", function(packet)
		local msg = packet.Data
		local server_id = msg.ServerId

		local existing = LocalData.GetServerEntry(msg.Code)

		if not existing or not msg then return end

		if msg.Name then
			existing.Name = msg.Name
		end

		if msg.Description then
			existing.Description = msg.Description
		end

		if server_id then
			existing.ServerId = server_id

			LocalData.IDToCodeMap[server_id] = msg.Code
		end

		Config.SIGNALS.OnServerIdChanged:Fire(msg.Code)

		Config.SIGNALS.OnServerUpdated:Fire(msg)

		print(`ServerUpdated(): { msg.Code }`)
	end)

	MessagingService:SubscribeAsync("PlayerCountChanged", function(packet)
		local msg = packet.Data
		local existing = LocalData.GetServerEntry(msg.Code)

		if not existing or not msg then return end

		existing.PlayerCount = msg.Data.PlayerCount

		Config.SIGNALS.OnPlayerCountChanged:Fire(msg)

		print(`PlayerCountChanged(): { msg.Code }`)
	end)

	MessagingService:SubscribeAsync("ServerRemoved", function(packet)
		local msg = packet.Data
		local server_id = msg.ServerId

		LocalData.RemoveServerEntry(msg.Code)

		Config.SIGNALS.OnServerRemoved:Fire(msg)

		if server_id then
			LocalData.IDToCodeMap[server_id] = nil
		end

		print(`ServerRemoved(): { msg.Code }`)
	end)

	MessagingService:SubscribeAsync("ServerShutdown", function(packet)
		local msg = packet.Data
		local server_id = msg.ServerId

		LocalData.RemoveServerEntry(msg.Code)

		Config.SIGNALS.OnServerShutdown:Fire(msg)

		if server_id then
			LocalData.IDToCodeMap[server_id] = nil
		end

		print(`ServerShutdown(): { msg.Code }`)
	end)
end

return ServerCallbacks