--!strict

--=======================
-- // CORE TYPES
--=======================

export type ServerData = {
	ServerId: string?,
	Code: string,
	OwnerUserId: number,
	Name: string,
	Description: string,
	PlayerCount: number,
	MaxPlayers: number,
	CreatedAt: number,
	LastUpdate: number,
	IsActive: boolean
}

export type ServerListEntry = {
	Code: string,
	Name: string,
	PlayerCount: number,
	MaxPlayers: number,
	OwnerUserId: number
}

--=======================
-- // CACHE TYPES
--=======================

export type CacheEntry<T> = {
	data: T
}

export type ServerCacheEntry = CacheEntry<ServerData>

--=======================
-- // OPERATION TYPES
--=======================

export type Result<T> = {
	success: boolean,
	data: T?,
	error: string?,
	errorCode: string?
}

--=======================
-- // MESSAGING TYPES
--=======================

export type MessageType =
	"ServerCreated"
| "ServerUpdated"
| "ServerRemoved"
| "PlayerCountChanged"
| "ServerShutdown"

export type ServerMessage = {
	ServerId: string?,
	Type: MessageType,
	Code: string,
	Timestamp: number,
	Data: ServerMessageData?
}

export type ServerMessageData =
	ServerCreatedData
| ServerUpdatedData
| PlayerCountData

export type ServerCreatedData = {
	OwnerUserId: number,
	Name: string,
	Description: string,
	CreatedAt: number
}

export type ServerUpdatedData = {
	Name: string?,
	Description: string?
}

export type PlayerCountData = {
	PlayerCount: number,
	MaxPlayers: number
}

--=======================
-- // ERROR CODES
--=======================

export type ErrorCode =
	"DEBOUNCE_ACTIVE"
| "INVALID_PARAMETERS"
| "FILTERING_FAILED"
| "RESERVATION_FAILED"
| "MEMORYSTORE_FAILED"
| "TELEPORT_FAILED"
| "SERVER_NOT_FOUND"
| "PERMISSION_DENIED"
| "RATE_LIMIT_EXCEEDED"
| "MISC_ERROR"
| "UNKNOWN_ERROR"

--=======================
-- // MEMORY TYPES
--=======================

export type ServerEntry = {
	key: string,
	value: ServerData
}

return nil