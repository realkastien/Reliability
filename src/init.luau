local RunService = game:GetService("RunService")

local Server = require(script.Server)
local Client = require(script.Client)
local SerdeLayer = require(script.SerdeLayer)

local IS_SERVER: boolean = RunService:IsServer()

export type PacketSerde = SerdeLayer.PacketSerde

if IS_SERVER then
    return Server
else
    return Client
end