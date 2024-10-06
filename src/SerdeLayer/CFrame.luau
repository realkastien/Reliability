local Types = require(script.Parent.Parent.Types)

export type PacketSerde = Types.PacketSerde
local Size: number = 24

local function Serialize(_, CFrame: CFrame, has: boolean?): (buffer, number?)
    local Buffer: buffer = buffer.create(Size)

    local RX: number, RY: number, RZ: number = CFrame:ToEulerAnglesXYZ()

    buffer.writef32(Buffer, 0, CFrame.X)
    buffer.writef32(Buffer, 4, CFrame.Y)
    buffer.writef32(Buffer, 8, CFrame.Z)
    buffer.writef32(Buffer, 12, RX)
    buffer.writef32(Buffer, 16, RY)
    buffer.writef32(Buffer, 20, RZ)

    return Buffer, has and Size or nil
end

local function Deserialize(_, Buffer: buffer, Cursor: number?, has: boolean?): (CFrame, number?)
    local LocalCursor: number = Cursor or 0;

    local BuiltCFrame: CFrame = CFrame.new(
        buffer.readf32(Buffer, LocalCursor),
        buffer.readf32(Buffer, LocalCursor + 4),
        buffer.readf32(Buffer, LocalCursor + 8)
    ) * CFrame.Angles(
        buffer.readf32(Buffer, LocalCursor + 12),
        buffer.readf32(Buffer, LocalCursor + 16),
        buffer.readf32(Buffer, LocalCursor + 20)
    )

    return BuiltCFrame, has and LocalCursor + Size or nil
end

return {
    Serialize = Serialize;
    Deserialize = Deserialize;
} :: PacketSerde
