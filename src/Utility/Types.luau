--!strict

--=======================
-- // CORE TYPES
--=======================

export type ServerData = {
	Code: string,
	OwnerUserId: number,
	Name: string,
	Description: string,
	PlayerCount: number,
	MaxPlayers: number,
	AveragePing: number,
	CreatedAt: number,
	LastUpdate: number,
	ServerOptions: ServerOptions,

	[string]: any
}

export type ServerListEntry = {
	Code: string,
	Name: string,
	Description: string,
	PlayerCount: number,
	MaxPlayers: number,
	AveragePing: number,
	OwnerUserId: number,

	IsPrivate: boolean,
	ServerPassword: string?
}

export type ModifiableData = {
	updated_code: string?,
	updated_name: string?,
	updated_description: string?,
	updated_owner_id: number?
}

export type TeleportDataType = {
	IsReservedServer: boolean,
	ReservationCode: string
}

export type ServerOptions = {
	IsPrivate: boolean,
	ServerPassword: string?
}

export type PredicateType = {
	field: PredicateFields,
	operator: PredicateOperators,
	value: any
}

export type PredicateOperators = "==" | "~=" | ">" | "<" | ">=" | "<=" | "*="

export type PredicateFields = "Code" | "OwnerUserId" | "Name" | "Description" | "PlayerCount" | "ServerOptions.IsPrivate"

export type UpdateServerSubTypes = "PingUpdate"

--=======================
-- // OPERATION TYPES
--=======================

export type Result<T> = {
	success: boolean,
	data: T?,
	error: string?,
	errorCode: string?
}

export type ServerMessage = {
	Type: string,
	OldCode: string?, -- // ONLY for when the code updates
	Code: string,
	Timestamp: number,
	Data: ServerMessageData?
}

export type ServerMessageData =
	ServerCreatedData
| ServerUpdatedData
| PlayerCountData
| AveragePingData

export type ServerCreatedData = {
	OwnerUserId: number,
	Name: string,
	Description: string,
	CreatedAt: number,

	PlayerCount: number,
	MaxPlayers: number,

	ServerOptions: ServerOptions
}

export type ServerUpdatedData = {
	Name: string,
	Description: string,
	OwnerUserId: number,
	AveragePing: number,

	ServerOptions: ServerOptions
}

export type PlayerCountData = {
	PlayerCount: number,
	MaxPlayers: number
}

export type AveragePingData = {
	SubType: UpdateServerSubTypes,
	AveragePing: number,
	ServerOptions: ServerOptions?
}

--=======================
-- // MEMORY TYPES
--=======================

export type ServerEntry = {
	key: string,
	value: ServerData
}

return nil