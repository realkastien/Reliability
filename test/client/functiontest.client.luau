local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SerdeLayer = require(ReplicatedStorage:WaitForChild("Reliability"):WaitForChild("SerdeLayer"))
local Reliability = require(ReplicatedStorage:WaitForChild("Reliability"))

local Event = Reliability.getFunction("SomeFunction")
local Serde = SerdeLayer.Tuple(SerdeLayer.UInt8, SerdeLayer.UInt32, SerdeLayer.UInt16)

Event:InvokeServer(Serde:Serialize(15, 2123512, 3231))
