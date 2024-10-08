> [!WARNING]
> This library is in early development and it is not intended to be used for large productions.

# Reliability
A lightweight networking library with buffers, extremely friendly syntax and focused on giving you high control over your Remote behavior.

### from Wally
```
reliability = "realkastien/reliability@0.0.4"
```

## Getting Started

> [!NOTE]
> Reliability is intended to give you close contact to raw RemoteEvent | UnreliableRemoteEvent usage.

### Referencing a RemoteEvent

+ Client & Server:
```lua
local YourRemote: RemoteEvent = Reliability.getReliable("NameOfYourRemote")
```

### Referencing an UnreliableRemoteEvent

+ Client & Server:
```lua
local YourRemote: UnreliableRemoteEvent = Reliability.getUnreliable("NameOfYourRemote")
```

### Referencing multiple remotes

+ Client & Server:
```lua
-- The prefix is completely optional
local PREFIX: string = "PrefixAppliedToAllRemotes"

-- Define all of your remotes at once
local YourRemotes = {
    YourUnreliableRemoteEvent = "Unreliable";
    YourRemoteEvent = "Reliable";

    YouNameIt = "Reliable";
    MultipleRemotesAtOnce = "Unreliable";
}

-- Returns a dictionary containing your remotes
local YourRemotes = Reliability.getNetwork(YourRemotes, PREFIX)

YourRemotes.YouNameIt:FireAllClients()
```

### Using SerdeLayer

Serde layers are responsible for serializing and deserializing data, using Reliability you can do that pretty easily:
```lua
type PacketSerde = Reliability.PacketSerde

local SerdeLayer = Reliability.SerdeLayer
local StringSerde: PacketSerde = SerdeLayer.String

local YourNewBuffer: buffer = StringSerde:Serialize("I am a string")
local YourStringBack: string = StringSerde:Deserialize(YourNewBuffer)

print(YourStringBack) -- I am a string
```

All Serdes available:
| Type | Description |
| --- | --- |
| Tuple(...) | For tuples of other serdes |
| Dict({[string]: PacketSerde}) | For tables with string-only indexes |
| Array({PacketSerde}) | For tables with numeric indexes |
| String | Any string |
| UInt8 | Numbers between 0 and 255 |
| UInt16 | Numbers between 0 and 65,536 |
| UInt32 | Numbers between 0 and 4,294,967,295 |
| Vector3 | For Vector3 or any structure that contains X,Y,Z values |
| CFrame | For any CFrame, storing both position and orientation information |