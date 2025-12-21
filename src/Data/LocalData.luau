--!strict

local LocalData = {}

--=======================
-- // SERVICES
--=======================

local Players = game:GetService("Players")

--=======================
-- // TYPES
--=======================

local Types = require("../Utility/Types")

--=======================
-- // PUBLIC DATA
--=======================

LocalData.ServerEntries = {} :: { [string]: Types.ServerData }
LocalData.TeleportDebounces = {} :: { [number]: boolean }
LocalData.Debounces = {} :: { [number]: boolean }

LocalData.AttachmentsInitialized = false
LocalData.SyncActive = false

--=======================
-- // DEBOUNCE API
--=======================

-- IsDebounced(): Checks if the user is debounced
-- @param user_id: The user id to check
-- @return boolean
function LocalData.IsDebounced(user_id: number): boolean
	return LocalData.Debounces[user_id] == true
end

-- SetDebounce(): Sets the user debounce
-- @param user_id: The user id to set debounce for
-- @param duration: The duration of the debounce in seconds
function LocalData.SetDebounce(user_id: number, duration: number): ()
	LocalData.Debounces[user_id] = true
	task.delay(duration, function()
		LocalData.Debounces[user_id] = nil
	end)
end

-- ClearDebounce(): Clear debounce for user
-- @param user_id: The user id to clear debounce for
function LocalData.ClearDebounce(user_id: number): ()
	LocalData.Debounces[user_id] = nil
end

--=======================
-- // SERVER API
--=======================

-- GetServerEntry(): Get server entry
-- @param code: The code of the server entry to get
-- @return Types.ServerData?
function LocalData.GetServerEntry(code: string): Types.ServerData?
	return LocalData.ServerEntries[code]
end

-- SetServerEntry(): Store server entry
-- @param code: The code of the server entry
-- @param data: The server data to store
function LocalData.SetServerEntry(code: string, data: Types.ServerData): ()
	LocalData.ServerEntries[code] = data
end

-- RemoveServerEntry(): Remove server entry
-- @param code: The code of the server entry to remove
function LocalData.RemoveServerEntry(code: string): ()
	LocalData.ServerEntries[code] = nil
end

-- ClearAllServerEntries(): Clear all server entries
function LocalData.ClearAllServerEntries(): ()
	LocalData.ServerEntries = {}
end

--=======================
-- // UTILITY API
--=======================

-- GetServerEntryCount(): Get the number of server entries
-- @return number
function LocalData.GetServerEntryCount(): number
	local count = 0

	for _ in LocalData.ServerEntries do
		count += 1
	end

	return count
end

-- GetDebounceCount(): Get the number of active debounces
-- @return number
function LocalData.GetDebounceCount(): number
	local count = 0

	for _ in LocalData.Debounces do
		count += 1
	end

	return count
end

-- IsPlayerInServer(): Checks if a user id is in the current server
-- @param user_id: The user id to check
-- @return boolean
function LocalData.IsPlayerInServer(user_id: number): boolean
	for _, player in Players:GetPlayers() do
		if player.UserId == user_id then
			return true
		end
	end

	return false
end

-- GetFirstPlayer(): Gets the first player
-- @return Player
function LocalData.GetFirstPlayer(): Player
	return Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
end

-- GetTeleportData(): Get teleport data
-- @return Types.TeleportDataType
function LocalData.GetTeleportData(): Types.TeleportDataType
	local FirstPlayer = LocalData.GetFirstPlayer()
	local TeleportData = FirstPlayer:GetJoinData().TeleportData

	return TeleportData :: Types.TeleportDataType
end

return LocalData