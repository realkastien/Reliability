local LOOK_UP_THRESHOLD: number = 24

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SerdeLayer = require(script.Parent.SerdeLayer)

local ServerReliability = {
    SerdeLayer = SerdeLayer
}

local ReliabilityStorage: Folder = ReplicatedStorage:FindFirstChild("ReliabilityStorage") or Instance.new("Folder")
ReliabilityStorage.Name = "ReliabilityStorage"
ReliabilityStorage.Parent = ReplicatedStorage

local Reliables: Folder = ReliabilityStorage:FindFirstChild("Reliables") :: Folder or Instance.new("Folder")
Reliables.Name = "Reliables"
Reliables.Parent = ReliabilityStorage

local Unreliables: Folder = ReliabilityStorage:FindFirstChild("Unreliables") :: Folder or Instance.new("Folder")
Unreliables.Name = "Unreliables"
Unreliables.Parent = ReliabilityStorage

local function NewRemote(Name: string, Unreliable: boolean?): UnreliableRemoteEvent | RemoteEvent
    local Remote: Instance = Instance.new((Unreliable and "Unreliable" or "").."RemoteEvent")
    Remote.Name = Name
    Remote.Parent = Unreliable and Unreliables or Reliables

    return Remote :: UnreliableRemoteEvent | RemoteEvent
end

function ServerReliability.getReliable(Name: string): RemoteEvent
    return (Reliables:FindFirstChild(Name) or NewRemote(Name)) :: RemoteEvent
end

function ServerReliability.getUnreliable(Name: string): RemoteEvent
    return (Unreliables:FindFirstChild(Name) or NewRemote(Name, true)) :: RemoteEvent
end

function ServerReliability.getNetwork(Structure: {[string]: string}, Prefix: string?): {[string]: RemoteEvent}
    local Network: {[string]: RemoteEvent} = {}
    local RemotePrefix: string = Prefix or ""

    for Name: string, Definition: string in Structure do
        Network[Name] = ServerReliability["get"..Definition](RemotePrefix..Name)
    end

    return Network
end

function ServerReliability.fireSelected(Remote: any & (RemoteEvent | UnreliableRemoteEvent), Selected: {Player}, ...: any): ()
    for _, Player in Selected do
        Remote:FireClient(Player, ...)
    end
end

function ServerReliability.fireExcept(Remote: any & (RemoteEvent | UnreliableRemoteEvent), Except: {Player}, ...: any): ()
    local AllPlayers: {Player} = Players:GetPlayers()
    local ExceptSize: number = #Except

    if ExceptSize > LOOK_UP_THRESHOLD then
        local ExceptLookUp: { [Player]: boolean } = {}
        for _, Player in Except do
            ExceptLookUp[Player] = true
        end

        for _, Player in AllPlayers do
            if ExceptLookUp[Player] then
                continue
            end
    
            Remote:FireClient(Player, ...)
        end

        return
    end

    for _, Player in AllPlayers do
        if table.find(Except, Player) then
            continue
        end

        Remote:FireClient(Player, ...)
    end
end

return ServerReliability