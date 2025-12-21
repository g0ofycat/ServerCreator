--!strict

local ServerLoader = {}

--=======================
-- // MODULES
--=======================

local LocalData = require("../Data/LocalData")

local Config = require("../Utility/Config")

local Types = require("../Utility/Types")

--=======================
-- // SERVICES
--=======================

local MemoryStoreService = game:GetService("MemoryStoreService")

--=======================
-- // MEMORY STORES
--=======================

local ServerList = MemoryStoreService:GetSortedMap("ServerList")

--=======================
-- // PRIVATE API
--=======================

-- _processServerEntry(): Processes a single hashmap entry
-- @param entry: The server entry to process
-- @return boolean: Whether the entry was valid and processed
local function _processServerEntry(entry: Types.ServerEntry): boolean
	local server_data = entry.value

	if not server_data or type(server_data) ~= "table" then
		warn(`_processServerEntry(): Invalid server data for code { entry.key }`)
		return false
	end

	if server_data.PlayerCount <= 0 then
		return false
	end

	LocalData.SetServerEntry(entry.key, server_data)

	return true
end

-- _cleanupStaleServers(): Removes servers that no longer exist in MemoryStore
-- @param valid_codes: Table of valid server codes
local function _cleanupStaleServers(valid_codes: { [string]: boolean }): ()
	local removed_count = 0

	for code, _ in LocalData.ServerEntries do
		if not valid_codes[code] then
			LocalData.RemoveServerEntry(code)
			removed_count += 1
		end
	end

	if removed_count > 0 then
		print(`ServerLoader(): Cleaned up { removed_count } stale servers`)
	end
end

--=======================
-- // PUBLIC API
--=======================

-- LoadAllServers(): Loads all servers from MemoryStore
-- @return Types.Result<{Types.ServerData}>
function ServerLoader.LoadAllServers(): Types.Result<{ Types.ServerData }>
	local success, entries = pcall(function()
		return ServerList:GetRangeAsync(Enum.SortDirection.Ascending, Config.MEMORY_STORE.BatchSize)
	end)

	if not success then
		warn(`LoadAllServers(): Failed to load servers from MemoryStore: { entries }`)

		return {
			success = false,
			data = nil,
			error = "Failed to load servers from MemoryStore",
			errorCode = Config.ERROR_CODES.MEMORYSTORE_FAILED
		}
	end

	local servers: { Types.ServerData } = {}
	local valid_codes: { [string]: boolean } = {}

	for _, entry in entries do
		if _processServerEntry(entry) then
			local server_data = entry.value :: Types.ServerData

			table.insert(servers, server_data)
			valid_codes[entry.key] = true
		end
	end

	_cleanupStaleServers(valid_codes)

	print(`ServerLoader(): Loaded { #servers } servers`)

	return {
		success = true,
		data = servers,
		error = nil,
		errorCode = nil
	}
end

-- LoadServerByCode(): Loads a specific server by code
-- @param code: The reservation code to load
-- @return Types.Result<Types.ServerData>
function ServerLoader.LoadServerByCode(code: string): Types.Result<Types.ServerData>
	local entry = LocalData.GetServerEntry(code)

	if entry then
		return {
			success = true,
			data = entry,
			error = nil,
			errorCode = nil
		}
	end

	local success, server_data = pcall(function()
		return ServerList:GetAsync(code)
	end)

	if not success then
		warn(`LoadServerByCode(): Failed to load server { code }: { server_data }`)

		return {
			success = false,
			data = nil,
			error = "Failed to load server from MemoryStore",
			errorCode = Config.ERROR_CODES.MEMORYSTORE_FAILED
		}
	end

	if not server_data then
		return {
			success = false,
			data = nil,
			error = "Server not found",
			errorCode = Config.ERROR_CODES.SERVER_NOT_FOUND
		}
	end

	LocalData.SetServerEntry(code, server_data)

	return {
		success = true,
		data = server_data,
		error = nil,
		errorCode = nil
	}
end

-- RefreshServerList(): Refreshes the server list from MemoryStore
-- @return Types.Result<boolean>
function ServerLoader.RefreshServerList(): Types.Result<boolean>
	local result = ServerLoader.LoadAllServers()

	if not result.success then
		return {
			success = false,
			data = nil,
			error = result.error,
			errorCode = result.errorCode
		}
	end

	return {
		success = true,
		data = true,
		error = nil,
		errorCode = nil
	}
end

-- SyncWithMemoryStore(): Syncs local state with MemoryStore
-- @return Types.Result<number>: Returns count of servers synced
function ServerLoader.SyncWithMemoryStore(): Types.Result<number>
	local result = ServerLoader.LoadAllServers()

	if not result.success then
		return {
			success = false,
			data = nil,
			error = result.error,
			errorCode = result.errorCode
		}
	end

	local synced_count = #(result.data or {})

	return {
		success = true,
		data = synced_count,
		error = nil,
		errorCode = nil
	}
end

-- GetServerList(): Gets lightweight server list for UI
-- @return Types.Result<{Types.ServerListEntry}>
function ServerLoader.GetServerList(): Types.Result<{ Types.ServerListEntry }>
	local entries: { Types.ServerListEntry } = {}

	for code, server_data in LocalData.ServerEntries do
		table.insert(entries, {
			Code = code,
			Name = server_data.Name,
			Description = server_data.Description,
			PlayerCount = server_data.PlayerCount,
			MaxPlayers = server_data.MaxPlayers,
			OwnerUserId = server_data.OwnerUserId
		})
	end

	return {
		success = true,
		data = entries,
		error = nil,
		errorCode = nil
	}
end

-- GetServerCount(): Gets the total number of loaded servers
-- @return number
function ServerLoader.GetServerCount(): number
	return LocalData.GetServerEntryCount()
end

-- GetTotalPlayerCount(): Gets total players across all servers
-- @return number
function ServerLoader.GetTotalPlayerCount(): number
	local total = 0

	for _, server_data in LocalData.ServerEntries do
		total += server_data.PlayerCount
	end

	return total
end

-- SyncInit(): Initializes syncing with MemoryStore
function ServerLoader.SyncInit(): ()
	LocalData.SyncActive = true

	task.spawn(function()
		while LocalData.SyncActive do
			task.wait(Config.GENERAL.SyncRate)

			local synced_result = ServerLoader.SyncWithMemoryStore()

			if synced_result.success then
				print(`SyncInit(): Synced { synced_result.data } servers`)
			else
				warn(`SyncInit(): Sync failed - { synced_result.error }`)
			end
		end
	end)
end

--=======================
-- // UTILITY API
--=======================

-- CheckIfReserved(): Checks if the server is reserved
-- @return boolean: true if reserved, false otherwise
function ServerLoader.CheckIfReserved(): boolean
	local PlayerTeleportData = LocalData.GetTeleportData()

	if not PlayerTeleportData then
		return false
	end

	return PlayerTeleportData.IsReservedServer
end

return ServerLoader