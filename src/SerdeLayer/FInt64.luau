--!native

local Types = require(script.Parent.Parent.Types)

export type PacketSerde = Types.PacketSerde
local Size: number = 8

local function Serialize(_, Integer: number, has: boolean?): (buffer, number?)
    local Buffer: buffer = buffer.create(Size)
    buffer.writef64(Buffer, 0, Integer)

    return Buffer, has and Size or nil
end

local function Deserialize(_, Buffer: buffer, Cursor: number?, has: boolean?): (number, number?)
    local LocalCursor: number = Cursor or 0;
    return buffer.readf64(Buffer, LocalCursor), has and LocalCursor+Size or nil
end

return {
    Serialize = Serialize;
    Deserialize = Deserialize;
} :: PacketSerde
