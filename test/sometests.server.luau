local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Reliability = require(ReplicatedStorage.Reliability)
local SerdeLayer = require(ReplicatedStorage.Reliability.SerdeLayer)
local Dict = Reliability.SerdeLayer.Dict({somedict = Reliability.SerdeLayer.Dict({a=SerdeLayer.String})})

local a = Dict:Serialize({somedict = {a="oi"}})
print(Dict:Deserialize(a))