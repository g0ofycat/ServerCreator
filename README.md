# ServerCreator

A better alternative to public server lists, allowing for **server owners**, **names**, **descriptions**, and more

## Main API

1. **Creating Servers**

```lua
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
```

2. **Joining Servers**

```lua
-- JoinServer(): Teleport to a server
-- @param player: The player to teleport
-- @param code: UID of the reserved server
-- @return Types.Result<boolean>
function ServerCreator.JoinServer(player: Player, code: string): Types.Result<boolean>
```

3. **Update Servers**

```lua
-- UpdateServer(): Updates an existing server's information
-- @param code: The reservation code of the server to update
-- @param updated_table: Table of updated data
-- @return Types.Result<Types.ServerData>
function ServerCreator.UpdateServer(code: string, updated_table: Types.ModifiableData): Types.Result<Types.ServerData>
```

4. **Filter Servers**

```lua
-- FilterServer(): Checks the servers that meet the predicate
-- @param predicate: The predicates
-- @return Types.Result<{ string }>; A table of codes that meet the predicate
function ServerCreator.FilterServer(predicate: Types.PredicateType): Types.Result<{ string }>
```

5. **Removing Servers**

```lua
-- RemoveServer(): Removes a server from the system
-- @param code: The reservation code of the server to remove
-- @param user_id: The user id requesting removal (for permission check)
-- @return Types.Result<boolean>
function ServerCreator.RemoveServer(
	code: string,
	user_id: number
): Types.Result<boolean>
```

6. **Signals**

Located in **Config.luau**. Refer to **Signal.luau** for the actual API. Use these to hook up *UI events*.

```lua
SIGNALS = {
	OnServerCreated = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
	OnServerUpdated = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
	OnServerRemoved = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
	OnPlayerCountChanged = Signal.new() :: Signal.Signal, -- // Types.ServerMessage
	OnServerShutdown = Signal.new() :: Signal.Signal, -- // Types.ServerMessage

	OnServerCodeChanged = Signal.new() :: Signal.Signal -- // Code: string
}
```