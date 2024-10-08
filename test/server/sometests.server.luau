local TEST_LENGTH: number = 100

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Reliability = require(ReplicatedStorage.Reliability)
local SerdeLayer = require(ReplicatedStorage.Reliability.SerdeLayer)

local SomeRemote = Reliability.getReliable("SomeRemote")
local Serde = SerdeLayer.UInt32

Players.PlayerAdded:Connect(function(Player: Player)
    task.wait(5)
    print("Starting bandwith test")
    local started: number = os.clock()

    local SerializedString = Serde:Serialize(1239234788)
    for _=1, TEST_LENGTH do
        SomeRemote:FireClient(Player, SerializedString)
    end

    local finished: number = os.clock()
    print(`Serialization + call time: {finished - started}`)
end)

