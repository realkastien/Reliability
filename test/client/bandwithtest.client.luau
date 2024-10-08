local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Reliability = require(ReplicatedStorage:WaitForChild("Reliability"))
local SerdeLayer = require(ReplicatedStorage.Reliability.SerdeLayer)

local SomeRemote: RemoteEvent = Reliability.getReliable("SomeRemote")
local Serde = SerdeLayer.String

local NumberOfPackets: number = 0;

SomeRemote.OnClientEvent:Connect(function(): ()
    NumberOfPackets += 1
    print("Received packet", NumberOfPackets)
end)