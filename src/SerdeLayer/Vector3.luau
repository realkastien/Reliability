local Types = require(script.Parent.Parent.Types)

export type PacketSerde = Types.PacketSerde
local Size: number = 4 * 3

local function Serialize(_, Vector3: Vector3, has: boolean?): (buffer, number?)

    local Buffer: buffer = buffer.create(Size)

    buffer.writef32(Buffer, 0, Vector3.X)
    buffer.writef32(Buffer, 4, Vector3.Y)
    buffer.writef32(Buffer, 8, Vector3.Z)

    return Buffer, has and Size or nil
end

local function Deserialize(_, Buffer: buffer, Cursor: number?, has: boolean?): (Vector3, number?)
    local LocalCursor: number = Cursor or 0;

    local BuiltVector: Vector3 = Vector3.new(
        buffer.readf32(Buffer, LocalCursor),
        buffer.readf32(Buffer, LocalCursor + 4),
        buffer.readf32(Buffer, LocalCursor + 8)
    )

    return BuiltVector, has and LocalCursor + Size or nil
end

return {
    Serialize = Serialize;
    Deserialize = Deserialize;
} :: PacketSerde
