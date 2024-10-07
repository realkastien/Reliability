local RunService = game:GetService("RunService")
local IS_SERVER: boolean = RunService:IsServer()

local SerdeLayer = require(script.SerdeLayer)
export type PacketSerde = SerdeLayer.PacketSerde

if IS_SERVER then
    return require(script.Server)
else
    return require(script.Client)
end
