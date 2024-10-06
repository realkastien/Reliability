local Types = require(script.Parent.Parent.Types)

type PacketSerde = Types.PacketSerde
export type ArraySerde = Types.ArraySerde

local function Serialize(self: ArraySerde, Data: {any}, has: boolean?): (buffer, number?)
    local Buffers: {buffer} = {}
    local BufferLengths: {number} = {}
    local TotalSize: number = 2;

    for _, Value: any in Data do
        local Buffer: buffer, Size: number? = self._Serde:Serialize(Value, true)

        TotalSize += Size :: number

        table.insert(BufferLengths, Size :: number)
        table.insert(Buffers, Buffer)
    end

    local FinalBuffer: buffer = buffer.create(TotalSize)
    local Cursor: number = 0;

    buffer.writeu16(FinalBuffer, 0, TotalSize-2)
    Cursor += 2

    for Index: number, Buffer in Buffers do
        buffer.copy(FinalBuffer, Cursor, Buffer, 0)
        Cursor += BufferLengths[Index]
    end

    return FinalBuffer, has and TotalSize or nil
end

local function Deserialize(self: ArraySerde, Data: buffer, Cursor: number?, has: boolean?): ({any}, number?)
    local LocalCursor: number = Cursor or 0;
    local SerializedTable: {any} = {}

    local BufferLength: number = buffer.readu16(Data, LocalCursor)
    LocalCursor += 2

    local InitialCursor: number = LocalCursor;
    while LocalCursor - InitialCursor < BufferLength do
        local SerializedData: any, NewCursor: number? = self._Serde:Deserialize(Data, LocalCursor, true)

        table.insert(SerializedTable, SerializedData)
        LocalCursor = NewCursor :: number
    end

    return SerializedTable, has and LocalCursor or nil
end

return function(Serde: PacketSerde): ArraySerde
    return {
        Serialize = Serialize;
        Deserialize = Deserialize;

        _Serde = Serde;
    }
end
