local Types = require(script.Parent.Parent.Types)

export type PacketSerde = Types.PacketSerde

local function Serialize(_, Buffer: buffer, has: boolean?): (buffer, number?)
    local BufferLength: number = buffer.len(Buffer)

    local Size: number = BufferLength + 2

    local NewBuffer: buffer = buffer.create(Size)
    buffer.writeu16(NewBuffer, 0, BufferLength)

    buffer.copy(NewBuffer, 2, Buffer)

    return NewBuffer, has and Size or nil
end

local function Deserialize(_, Buffer: buffer, Cursor: number?, has: boolean?): (buffer, number?)
    local LocalCursor: number = Cursor or 0;

    local BufferLength: number = buffer.readu16(Buffer, LocalCursor)
    local NewBuffer: buffer = buffer.create(BufferLength)

    LocalCursor += 2
    buffer.copy(NewBuffer, 0, Buffer, LocalCursor, BufferLength)

    return NewBuffer, has and LocalCursor + BufferLength or nil
end

return {
    Serialize = Serialize;
    Deserialize = Deserialize;
} :: PacketSerde
