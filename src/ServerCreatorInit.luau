--!strict

local ServerCreator = {}

--=======================
-- // SERVICES
--=======================

local Players = game:GetService("Players")

local TeleportService = game:GetService("TeleportService")
local TextService = game:GetService("TextService")

local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")

--=======================
-- // MODULES
--=======================

local ServerLoader = require("./Modules/ServerLoader")

local ServerCallbacks = require("./Modules/ServerCallbacks")

local LocalData = require("./Data/LocalData")

local Config = require("./Utility/Config")

local Types = require("./Utility/Types")

--=======================
-- // MEMORY STORES
--=======================

local ServerList = MemoryStoreService:GetSortedMap("ServerList")

--=======================
-- // PRIVATE API
--=======================

-- _validateParameters(): Validates server creation parameters
-- @param user_id: The user id to validate
-- @param server_name: The server name to validate
-- @param description: The description to validate
-- @return Types.Result<boolean>
local function _validateParameters(
	user_id: number,
	server_name: string,
	description: string
): Types.Result<boolean>
	if user_id <= 0 then
		return {
			success = false,
			data = nil,
			error = "Invalid user ID",
			errorCode = Config.ERROR_CODES.INVALID_PARAMETERS
		}
	end

	if #server_name > Config.GENERAL.MaxServerNameLength then
		return {
			success = false,
			data = nil,
			error = `Server name too long (max { Config.GENERAL.MaxServerNameLength } characters)`,
			errorCode = Config.ERROR_CODES.INVALID_PARAMETERS
		}
	end

	if #server_name == 0 then
		return {
			success = false,
			data = nil,
			error = "Server name cannot be empty",
			errorCode = Config.ERROR_CODES.INVALID_PARAMETERS
		}
	end

	if #description > Config.GENERAL.MaxDescriptionLength then
		return {
			success = false,
			data = nil,
			error = `Description too long (max { Config.GENERAL.MaxDescriptionLength } characters)`,
			errorCode = Config.ERROR_CODES.INVALID_PARAMETERS
		}
	end

	return {
		success = true,
		data = true,
		error = nil,
		errorCode = nil
	}
end

-- _filterText(): Filters text using TextService
-- @param text: The text to filter
-- @param user_id: The user id for filtering context
-- @param fallback: The fallback text if filtering fails
-- @return Types.Result<string>
local function _filterText(
	text: string,
	user_id: number,
	fallback: string
): Types.Result<string>
	local success, result = pcall(function()
		return TextService:FilterStringAsync(text, user_id)
	end)

	if not success then
		warn(`_filterText(): Text filtering failed: { result }`)

		return {
			success = false,
			data = fallback,
			error = "Failed to filter text",
			errorCode = Config.ERROR_CODES.FILTERING_FAILED
		}
	end

	local filteredSuccess, filteredText = pcall(function()
		return result:GetNonChatStringForBroadcastAsync()
	end)

	if not filteredSuccess then
		warn(`_filterText(): Text broadcast filtering failed: { filteredText }`)

		return {
			success = false,
			data = fallback,
			error = "Failed to get filtered broadcast text",
			errorCode = Config.ERROR_CODES.FILTERING_FAILED
		}
	end

	return {
		success = true,
		data = filteredText,
		error = nil,
		errorCode = nil
	}
end

-- _reserveServer(): Reserves a server using TeleportService
-- @return Types.Result<string>
local function _reserveServer(): Types.Result<string>
	local success, code = pcall(function()
		return TeleportService:ReserveServerAsync(Config.CONSTS.PlaceId)
	end)

	if not success then
		warn(`_reserveServer(): Failed to reserve server: { code }`)

		return {
			success = false,
			data = nil,
			error = "Failed to reserve server",
			errorCode = Config.ERROR_CODES.RESERVATION_FAILED
		}
	end

	return {
		success = true,
		data = code,
		error = nil,
		errorCode = nil
	}
end

-- _initializeServerData(): Creates the initial server data structure
-- @param code: The reservation code
-- @param user_id: The owner's user id
-- @param filtered_name: The filtered server name
-- @param filtered_description: The filtered description
-- @return Types.ServerData
local function _initializeServerData(
	code: string,
	user_id: number,
	filtered_name: string,
	filtered_description: string
): Types.ServerData
	local now = os.time()

	return {
		ServerId = nil,
		Code = code,
		OwnerUserId = user_id,
		Name = filtered_name,
		Description = filtered_description,
		PlayerCount = 1,
		MaxPlayers = Players.MaxPlayers,
		CreatedAt = now,
		LastUpdate = now,
		IsActive = true
	}
end

-- _saveToMemoryStore(): Saves server data to MemoryStore
-- @param code: The reservation code
-- @param server_data: The server data to save
-- @return Types.Result<boolean>
local function _saveToMemoryStore(
	code: string,
	server_data: Types.ServerData
): Types.Result<boolean>
	local success, err = pcall(function()
		ServerList:SetAsync(code, server_data, Config.MEMORY_STORE.Expiration)

		return true
	end)

	if not success then
		warn(`_saveToMemoryStore(): Failed to save server data for { code }: { err }`)

		return {
			success = false,
			data = nil,
			error = "Failed to save server to MemoryStore",
			errorCode = Config.ERROR_CODES.MEMORYSTORE_FAILED
		}
	end

	return {
		success = true,
		data = true,
		error = nil,
		errorCode = nil
	}
end

-- _broadcastServerCreation(): Broadcasts new server to all servers via MessagingService
-- @param server_data: The server data to broadcast
-- @return Types.Result<boolean>
local function _broadcastServerCreation(
	server_data: Types.ServerData
): Types.Result<boolean>
	local message: Types.ServerMessage = {
		ServerId = nil,
		Type = Config.MESSAGE_TYPES.ServerCreated,
		Code = server_data.Code,
		Timestamp = os.time(),

		Data = {
			OwnerUserId = server_data.OwnerUserId,
			Name = server_data.Name,
			Description = server_data.Description,
			CreatedAt = server_data.CreatedAt
		}
	}

	local success, err = pcall(function()
		MessagingService:PublishAsync("ServerCreated", message)

		return true
	end)

	if not success then
		warn(`_broadcastServerCreation(): Failed to broadcast server { server_data.Code }: { err }`)

		return {
			success = false,
			data = nil,
			error = "Failed to broadcast server creation",
			errorCode = Config.ERROR_CODES.UNKNOWN_ERROR
		}
	end

	return {
		success = true,
		data = true,
		error = nil,
		errorCode = nil
	}
end

-- _teleportPlayer(): Teleports a player to the reserved server
-- @param player: The player to teleport
-- @param place_id: The place id to teleport to
-- @param reservation_code: The reservation code
-- @return Types.Result<boolean>
local function _teleportPlayer(
	player: Player,
	place_id: number,
	reservation_code: string
): Types.Result<boolean>
	local teleport_data = {
		ReservationCode = reservation_code
	}

	local success, err = pcall(function()
		TeleportService:TeleportToPrivateServer(
			place_id,
			reservation_code,
			{ player },
			nil,
			teleport_data
		)

		return true
	end)

	if not success then
		warn(`_teleportPlayer(): Failed to teleport player { player.UserId } to { reservation_code }: { err }`)

		return {
			success = false,
			data = nil,
			error = "Failed to teleport player",
			errorCode = Config.ERROR_CODES.TELEPORT_FAILED
		}
	end

	return {
		success = true,
		data = true,
		error = nil,
		errorCode = nil
	}
end

--=======================
-- // PUBLIC API
--=======================

-- CreateServer(): Creates a new server in the sorted map
-- @param user_id: The user id of the server owner
-- @param server_name: The name of the server
-- @param description: The description of the server
-- @param player: The player to teleport (optional, if called from server)
-- @return Types.Result<string>
function ServerCreator.CreateServer(
	user_id: number,
	server_name: string,
	description: string,
	player: Player?
): Types.Result<string>
	if LocalData.IsDebounced(user_id) then
		return {
			success = false,
			data = nil,
			error = "Please wait before creating another server",
			errorCode = Config.ERROR_CODES.DEBOUNCE_ACTIVE
		}
	end

	LocalData.SetDebounce(user_id, Config.GENERAL.DebounceTime)

	local validationResult = _validateParameters(user_id, server_name, description)

	if not validationResult.success then
		return {
			success = false,
			data = nil,
			error = validationResult.error,
			errorCode = validationResult.errorCode
		}
	end

	local nameResult = _filterText(
		server_name,
		user_id,
		Config.VALIDATION.FilterFallbackName
	)

	local filtered_name = nameResult.data or Config.VALIDATION.FilterFallbackName

	local descResult = _filterText(
		description,
		user_id,
		Config.VALIDATION.FilterFallbackDescription
	)

	local filtered_description = descResult.data or Config.VALIDATION.FilterFallbackDescription

	local reservationResult = _reserveServer()

	if not reservationResult.success then
		return {
			success = false,
			data = nil,
			error = reservationResult.error,
			errorCode = reservationResult.errorCode
		}
	end

	local reservation_code = reservationResult.data :: string

	local server_data = _initializeServerData(
		reservation_code,
		user_id,
		filtered_name,
		filtered_description
	)

	local saveResult = _saveToMemoryStore(reservation_code, server_data)

	if not saveResult.success then
		return {
			success = false,
			data = nil,
			error = saveResult.error,
			errorCode = saveResult.errorCode
		}
	end

	LocalData.SetCached(reservation_code, server_data)
	LocalData.SetServerEntry(reservation_code, server_data)

	task.spawn(function()
		_broadcastServerCreation(server_data)
	end)

	if player then
		local teleportResult = _teleportPlayer(player, Config.GENERAL.ServerPlaceId, reservation_code)

		if not teleportResult.success then
			LocalData.RemoveServerEntry(reservation_code)
			LocalData.ClearCached(reservation_code)

			pcall(function()
				ServerList:RemoveAsync(reservation_code)
			end)

			return {
				success = false,
				data = nil,
				error = teleportResult.error,
				errorCode = teleportResult.errorCode
			}
		end
	end

	return {
		success = true,
		data = reservation_code,
		error = nil,
		errorCode = nil
	}
end

-- UpdateServer(): Updates an existing server's information
-- @param code: The reservation code of the server to update
-- @param updated_id: Optional new server id
-- @param updated_name: Optional new server name
-- @param updated_description: Optional new description
-- @return Types.Result<Types.ServerData>
function ServerCreator.UpdateServer(
	code: string,
	updated_id: string?,
	updated_name: string?,
	updated_description: string?
): Types.Result<Types.ServerData>
	local existing_data = LocalData.GetServerEntry(code)

	if not existing_data then
		existing_data = LocalData.GetCached(code)

		if not existing_data then
			local success, result = pcall(function()
				return ServerList:GetAsync(code)
			end)

			if not success or not result then
				return {
					success = false,
					data = nil,
					error = "Server not found",
					errorCode = Config.ERROR_CODES.SERVER_NOT_FOUND
				}
			end

			existing_data = result
		end
	end

	local filtered_name = existing_data.Name
	local filtered_description = existing_data.Description

	local new_id = existing_data.ServerId

	if updated_name then
		local nameResult = _filterText(
			updated_name,
			existing_data.OwnerUserId,
			Config.VALIDATION.FilterFallbackName
		)
		filtered_name = nameResult.data or existing_data.Name
	end

	if updated_description then
		local descResult = _filterText(
			updated_description,
			existing_data.OwnerUserId,
			Config.VALIDATION.FilterFallbackDescription
		)
		filtered_description = descResult.data or existing_data.Description
	end

	if updated_id then
		new_id = updated_id
	end

	local updated_data: Types.ServerData = {
		ServerId = new_id,
		Code = existing_data.Code,
		OwnerUserId = existing_data.OwnerUserId,
		Name = filtered_name,
		Description = filtered_description,
		PlayerCount = existing_data.PlayerCount,
		MaxPlayers = existing_data.MaxPlayers,
		CreatedAt = existing_data.CreatedAt,
		LastUpdate = os.time(),
		IsActive = existing_data.IsActive
	}

	local saveResult = _saveToMemoryStore(code, updated_data)

	if not saveResult.success then
		return {
			success = false,
			data = nil,
			error = saveResult.error,
			errorCode = saveResult.errorCode
		}
	end

	LocalData.SetCached(code, updated_data)
	LocalData.SetServerEntry(code, updated_data)

	task.spawn(function()
		local message: Types.ServerMessage = {
			ServerId = new_id,
			Type = Config.MESSAGE_TYPES.ServerUpdated,
			Code = code,
			Timestamp = os.time(),

			Data = {
				Name = updated_name and filtered_name or nil,
				Description = updated_description and filtered_description or nil
			}
		}

		pcall(function()
			MessagingService:PublishAsync("ServerUpdated", message)
		end)
	end)

	return {
		success = true,
		data = updated_data,
		error = nil,
		errorCode = nil
	}
end

-- RemoveServer(): Removes a server from the system
-- @param code: The reservation code of the server to remove
-- @param user_id: The user id requesting removal (for permission check)
-- @return Types.Result<boolean>
function ServerCreator.RemoveServer(
	code: string,
	user_id: number
): Types.Result<boolean>
	local existing_data = LocalData.GetServerEntry(code)

	if not existing_data then
		existing_data = LocalData.GetCached(code)

		if not existing_data then
			local success, result = pcall(function()
				return ServerList:GetAsync(code)
			end)

			if not success or not result then
				return {
					success = false,
					data = nil,
					error = "Server not found",
					errorCode = Config.ERROR_CODES.SERVER_NOT_FOUND
				}
			end

			existing_data = result
		end
	end

	if existing_data.OwnerUserId ~= user_id then
		return {
			success = false,
			data = nil,
			error = "You don't have permission to remove this server",
			errorCode = Config.ERROR_CODES.PERMISSION_DENIED
		}
	end

	local success, err = pcall(function()
		ServerList:RemoveAsync(code)
		return true
	end)

	if not success then
		warn(`RemoveServer(): Failed to remove server { code } from MemoryStore: { err }`)

		return {
			success = false,
			data = nil,
			error = "Failed to remove server from MemoryStore",
			errorCode = Config.ERROR_CODES.MEMORYSTORE_FAILED
		}
	end

	LocalData.RemoveServerEntry(code)
	LocalData.ClearCached(code)

	task.spawn(function()
		local message: Types.ServerMessage = {
			ServerId = nil,
			Type = Config.MESSAGE_TYPES.ServerRemoved,
			Code = code,
			Timestamp = os.time(),
			Data = nil
		}

		pcall(function()
			MessagingService:PublishAsync("ServerRemoved", message)
		end)
	end)

	return {
		success = true,
		data = true,
		error = nil,
		errorCode = nil
	}
end

-- ShutdownServer(): Shuts down a server
-- @param code: The reservation code of the server to shutdown
-- @return Types.Result<boolean>
function ServerCreator.ShutdownServer(code: string): Types.Result<boolean>
	local existing_data = LocalData.GetServerEntry(code)

	if not existing_data then
		existing_data = LocalData.GetCached(code)

		if not existing_data then
			local success, result = pcall(function()
				return ServerList:GetAsync(code)
			end)

			if not success or not result then
				return {
					success = false,
					data = nil,
					error = "Server not found",
					errorCode = Config.ERROR_CODES.SERVER_NOT_FOUND
				}
			end

			existing_data = result
		end
	end

	local success, err = pcall(function()
		ServerList:RemoveAsync(code)
		return true
	end)

	if not success then
		warn(`ShutdownServer(): Failed to shutdown server { code } from MemoryStore: { err }`)

		return {
			success = false,
			data = nil,
			error = "Failed to remove server from MemoryStore",
			errorCode = Config.ERROR_CODES.MEMORYSTORE_FAILED
		}
	end

	LocalData.RemoveServerEntry(code)
	LocalData.ClearCached(code)

	task.spawn(function()
		local message: Types.ServerMessage = {
			ServerId = nil,
			Type = Config.MESSAGE_TYPES.ServerShutdown,
			Code = code,
			Timestamp = os.time(),
			Data = nil
		}

		pcall(function()
			MessagingService:PublishAsync("ServerShutdown", message)
		end)
	end)

	return {
		success = true,
		data = true,
		error = nil,
		errorCode = nil
	}
end

-- IncrementPlayerCount(): Increments the player count for a server
-- @param code: The reservation code of the server
-- @return Types.Result<number>
function ServerCreator.IncrementPlayerCount(
	code: string
): Types.Result<number>
	local success, result = pcall(function()
		return ServerList:UpdateAsync(code, function(server_data: Types.ServerData)
			if not server_data then
				return nil
			end

			server_data.PlayerCount = server_data.PlayerCount + 1
			server_data.LastUpdate = os.time()

			return server_data :: any
		end, Config.MEMORY_STORE.Expiration)
	end)

	if not success or not result then
		warn(`IncrementPlayerCount(): Failed to increment player count for { code }: { result }`)

		return {
			success = false,
			data = nil,
			error = "Failed to update player count",
			errorCode = Config.ERROR_CODES.MEMORYSTORE_FAILED
		}
	end

	local updated_count = result.PlayerCount

	LocalData.SetCached(code, result)
	LocalData.SetServerEntry(code, result)

	task.spawn(function()
		local message: Types.ServerMessage = {
			ServerId = nil,
			Type = Config.MESSAGE_TYPES.PlayerCountChanged,
			Code = code,
			Timestamp = os.time(),

			Data = {
				PlayerCount = updated_count,
				MaxPlayers = result.MaxPlayers
			} :: Types.PlayerCountData
		}

		pcall(function()
			MessagingService:PublishAsync("PlayerCountChanged", message)
		end)
	end)

	return {
		success = true,
		data = updated_count,
		error = nil,
		errorCode = nil
	}
end

-- DecrementPlayerCount(): Decrements the player count for a server
-- @param code: The reservation code of the server
-- @return Types.Result<number>
function ServerCreator.DecrementPlayerCount(
	code: string
): Types.Result<number>
	local success, result = pcall(function()
		return ServerList:UpdateAsync(code, function(server_data: Types.ServerData)
			if not server_data then
				return nil
			end

			server_data.PlayerCount = math.max(0, server_data.PlayerCount - 1)
			server_data.LastUpdate = os.time()

			return server_data :: any
		end, Config.MEMORY_STORE.Expiration)
	end)

	if not success or not result then
		warn(`DecrementPlayerCount(): Failed to decrement player count for { code }: { result }`)

		return {
			success = false,
			data = nil,
			error = "Failed to update player count",
			errorCode = Config.ERROR_CODES.MEMORYSTORE_FAILED
		}
	end

	local updated_count = result.PlayerCount

	LocalData.SetCached(code, result)
	LocalData.SetServerEntry(code, result)

	task.spawn(function()
		local message: Types.ServerMessage = {
			ServerId = nil,
			Type = Config.MESSAGE_TYPES.PlayerCountChanged,
			Code = code,
			Timestamp = os.time(),

			Data = {
				PlayerCount = updated_count,
				MaxPlayers = result.MaxPlayers
			} :: Types.PlayerCountData
		}

		pcall(function()
			MessagingService:PublishAsync("PlayerCountChanged", message)
		end)
	end)

	return {
		success = true,
		data = updated_count,
		error = nil,
		errorCode = nil
	}
end

-- JoinServer(): Teleport to a server
-- @param player: The player to teleport
-- @param code: UID of the reserved server
-- @return Types.Result<boolean>
function ServerCreator.JoinServer(player: Player, code: string): Types.Result<boolean>
	if not player then
		return {
			success = false,
			data = nil,
			error = "Player not found",
			errorCode = Config.ERROR_CODES.INVALID_PARAMETERS
		}
	end

	_teleportPlayer(player, Config.GENERAL.ServerPlaceId, code)

	return {
		success = true,
		data = nil,
		error = nil,
		errorCode = nil
	}
end

-- UpdateServerID(): Updates the server ID
function ServerCreator.UpdateServerID(): ()
	if not ServerLoader.CheckIfReserved() then return end

	local TeleportData = LocalData.GetTeleportData()

	if not TeleportData or not TeleportData.ReservationCode then return end

	ServerCreator.UpdateServer(TeleportData.ReservationCode :: string, Config.CONSTS.PrivateServerId)
end

-- AttachListeners(): Attach all listeners
-- @param code: The code of the server
function ServerCreator.AttachListeners(code: string): ()
	if not ServerLoader.CheckIfReserved() or LocalData.AttachmentsInitialized then return end

	Players.PlayerAdded:Connect(function()
		ServerCreator.IncrementPlayerCount(code)
	end)

	Players.PlayerRemoving:Connect(function()
		ServerCreator.DecrementPlayerCount(code)
	end)

	game:BindToClose(function()
		LocalData.SyncActive = false

		ServerCreator.ShutdownServer(code)
	end)

	LocalData.AttachmentsInitialized = true
end

--=======================
-- // INIT
--=======================

ServerCallbacks.Init()

ServerLoader.LoadAllServers()

ServerLoader.SyncInit()

ServerCreator.UpdateServerID()

Config.SIGNALS.OnServerIdChanged:Connect(function(code)
	ServerCreator.AttachListeners(code)
end)

return ServerCreator