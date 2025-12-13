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

LocalData.ServerCache = {} :: { [string]: Types.ServerCacheEntry }
LocalData.TeleportDebounces = {} :: { [number]: boolean }
LocalData.Debounces = {} :: { [number]: boolean }
LocalData.ServerEntries = {} :: { [string]: Types.ServerData }
LocalData.IDToCodeMap = {} :: { [string]: string }

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
-- // CACHE API
--=======================

-- GetCached(): Get cached server data if not expired
-- @param code: The code of the server entry to get
-- @return Types.ServerData?
function LocalData.GetCached(code: string): Types.ServerData?
	local cached = LocalData.ServerCache[code]

	if not cached then
		return nil
	end

	return cached.data
end

-- SetCached(): Store server data in cache
-- @param code: The code of the server entry to cache
-- @param data: The server data to cache
function LocalData.SetCached(code: string, data: Types.ServerData): ()
	LocalData.ServerCache[code] = {
		data = data
	}
end

-- ClearCached(): Clear from cache
-- @param code: The code of the server entry to clear
function LocalData.ClearCached(code: string): ()
	LocalData.ServerCache[code] = nil
end

-- CleanupCache(): Clear all cache entries
function LocalData.CleanupCache(): ()
	for code, cached in LocalData.ServerCache do
		LocalData.ServerCache[code] = nil
	end
end

--=======================
-- // SERVER API
--=======================

-- HasServerEntry(): Check if server entry exists
-- @param code: The code of the server entry to check
-- @return boolean
function LocalData.HasServerEntry(code: string): boolean
	return LocalData.ServerEntries[code] ~= nil
end

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

-- GetCachedCount(): Get the number of cached entries
-- @return number
function LocalData.GetCachedCount(): number
	local count = 0

	for _ in LocalData.ServerCache do
		count += 1
	end

	return count
end

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

-- GetTeleportData(): Get teleport data
-- @return { any }?
function LocalData.GetTeleportData(): { [any]: any }?
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()

	local TeleportData = player:GetJoinData().TeleportData

	return TeleportData
end

return LocalData