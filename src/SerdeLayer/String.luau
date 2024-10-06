local Types = require(script.Parent.Parent.Types)

export type PacketSerde = Types.PacketSerde

local function Serialize(_, String: string, has: boolean?): (buffer, number?)
    local Size: number = String:len() + 2

    local Buffer: buffer = buffer.create(Size)

    buffer.writeu16(Buffer, 0, Size-2)
    buffer.writestring(Buffer, 2, String)

    return Buffer, has and Size or nil
end

local function Deserialize(_, Buffer: buffer, Cursor: number?, has: boolean?): (string, number?)
    local LocalCursor: number = Cursor or 0;
    local StringLength: number = buffer.readu16(Buffer, LocalCursor)

    LocalCursor += 2
    return buffer.readstring(Buffer, LocalCursor, StringLength), has and LocalCursor+StringLength or nil
end

return {
    Serialize = Serialize;
    Deserialize = Deserialize;
} :: PacketSerde
