--!strict

--=======================
-- // MODULES
--=======================

local Signal = require("./Signal")

--=======================
-- // CONFIG
--=======================

return {
	--=======================
	-- // GENERAL
	--=======================

	GENERAL = {
		DebounceTime = 10, -- // number: TIME IN SECONDS FOR PLAYER SERVER CREATION DEBOUNCE
		MaxServerNameLength = 50, -- // number: MAXIMUM LENGTH OF SERVER NAME
		MaxDescriptionLength = 200, -- // number: MAXIMUM LENGTH OF SERVER DESCRIPTION

		TeleportDebounce = 5, -- // number: TELEPORT DEBOUNCE

		SyncRate = 30, -- // number: TIME IN SECONDS FOR SERVER INFO SYNC

		ServerPlaceId = game.PlaceId -- // number: PLACE ID FOR RESERVED SERVERS
	},

	--=======================
	-- // SIGNALS
	--=======================

	SIGNALS = {
		OnServerCreated = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
		OnServerUpdated = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
		OnServerRemoved = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
		OnPlayerCountChanged = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
		OnServerShutdown = Signal.new() :: Signal.Signal -- // Types.ServerMessage
	},

	--=======================
	-- // MEMORY STORE
	--=======================

	MEMORY_STORE = {
		Expiration = 86400, -- // number: TIME IN SECONDS FOR SERVER INFO TO EXPIRE IN MEMORY STORE
		BatchSize = 200 -- // number: "GetRangeAsync" BATCH SIZE FOR MEMORY STORE
	},

	--=======================
	-- // VALIDATION
	--=======================

	VALIDATION = {
		FilterFallbackName = "[No Name]", -- // string: DEFAULT NAME IF FILTERING FAILS
		FilterFallbackDescription = "[No Description]" -- // string: DEFAULT DESCRIPTION IF FILTERING FAILS
	},

	--=======================
	-- // ERROR CODES
	--=======================

	ERROR_CODES = {
		DEBOUNCE_ACTIVE = "DEBOUNCE_ACTIVE",
		INVALID_PARAMETERS = "INVALID_PARAMETERS",
		FILTERING_FAILED = "FILTERING_FAILED",
		RESERVATION_FAILED = "RESERVATION_FAILED",
		MEMORYSTORE_FAILED = "MEMORYSTORE_FAILED",
		TELEPORT_FAILED = "TELEPORT_FAILED",
		SERVER_NOT_FOUND = "SERVER_NOT_FOUND",
		PERMISSION_DENIED = "PERMISSION_DENIED",
		UNKNOWN_ERROR = "UNKNOWN_ERROR"
	},

	--=======================
	-- // MESSAGE TYPES
	--=======================

	MESSAGE_TYPES = {
		ServerCreated = "ServerCreated",
		ServerUpdated = "ServerUpdated",
		PlayerCountChanged = "PlayerCountChanged",
		ServerRemoved = "ServerRemoved",
		ServerShutdown = "ServerShutdown"
	}
}