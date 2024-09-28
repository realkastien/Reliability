local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SerdeLayer = require(script.Parent.SerdeLayer)

local ClientReliability = {
    SerdeLayer = SerdeLayer
}

local Storage = ReplicatedStorage:WaitForChild("ReliabilityStorage")
local Reliables, Unreliables = Storage:WaitForChild("Reliables"), Storage:WaitForChild("Unreliables")

function ClientReliability.getReliable(Name: string): RemoteEvent
    return Reliables:WaitForChild(Name)
end

function ClientReliability.getUnreliable(Name: string): UnreliableRemoteEvent
    return Unreliables:FindFirstChild(Name)
end

function ClientReliability.getNetwork(Structure: {[string]: string}, Prefix: string?): {[string]: RemoteEvent | UnreliableRemoteEvent}
    local Network: {[string]: RemoteEvent | UnreliableRemoteEvent} = {}
    local RemotePrefix: string = Prefix or ""

    for Name: string, Definition: string in Structure do
        Network[Name] = ClientReliability["get"..Definition](RemotePrefix..Name)
    end

    return Network
end

return ClientReliability