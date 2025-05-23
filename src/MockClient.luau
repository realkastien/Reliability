local SerdeLayer = {}
local DEBUG: boolean = true

-- Mock RemoteEvent: Only supports FireServer as on the client.
local MockRemoteEvent = {
    OnClientEvent = {},
}
MockRemoteEvent.__index = MockRemoteEvent
function MockRemoteEvent.new(name)
    local self = setmetatable({}, MockRemoteEvent)
    self.Name = name
    return self
end
function MockRemoteEvent:FireServer(...)
    if DEBUG then print("FireServer called on RemoteEvent", self.Name, ...) end
end

function MockRemoteEvent.OnClientEvent:Connect(Callback: (...any)->()): ()
    if DEBUG then print("Connected to Remote",self.Name) end
end

function MockRemoteEvent.OnClientEvent:Once(Callback: (...any)->()): ()
    if DEBUG then print("Connected once to Remote",self.Name) end
end

-- Mock RemoteFunction: Only supports InvokeServer.
local MockRemoteFunction = {}
MockRemoteFunction.__index = MockRemoteFunction
function MockRemoteFunction.new(name)
    local self = setmetatable({}, MockRemoteFunction)
    self.Name = name
    return self
end
function MockRemoteFunction:InvokeServer(...)
    if DEBUG then print("InvokeServer called on RemoteFunction", self.Name, ...) end
    return nil
end

local ClientReliability = {
    SerdeLayer = SerdeLayer
}

function ClientReliability.getReliable(Name)
    return MockRemoteEvent.new(Name)
end

function ClientReliability.getUnreliable(Name)
    return MockRemoteEvent.new(Name)
end

function ClientReliability.getFunction(Name)
    return MockRemoteFunction.new(Name)
end

function ClientReliability.getNetwork(Structure, Prefix)
    local Network = {}
    local RemotePrefix = Prefix or ""
    for Name, Definition in pairs(Structure) do
        Network[Name] = ClientReliability["get" .. Definition](RemotePrefix .. Name)
    end
    return Network
end

return ClientReliability
