local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Reliability = require(ReplicatedStorage.Reliability)
local SerdeLayer = require(ReplicatedStorage.Reliability.SerdeLayer)

local Event = Reliability.getFunction("SomeFunction")
local Serde = SerdeLayer.Tuple(SerdeLayer.UInt8, SerdeLayer.UInt32, SerdeLayer.UInt16)

local NumberOfPackets: number = 0;

Event.OnServerInvoke = function(_Player, ...)
    NumberOfPackets += 1
    print("Received packet", NumberOfPackets, Serde:Deserialize(...))
end
