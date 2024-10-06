local Types = require(script.Parent.Parent.Types)

type PacketSerde = Types.PacketSerde
export type TableSerde = Types.TableSerde
export type ArraySerde = Types.ArraySerde

type Serdes = PacketSerde | TableSerde | ArraySerde

local function Serialize(self: TableSerde, Data: {[string]: any}, has: boolean?): (buffer, number?)
    local Buffers: {buffer} = {}
    local BufferLengths: {number} = {}
    local TotalSize: number = 0;
    
    for _, Key: string in self._SerdeOrder do
        local Buffer: buffer, Size: number = self._Serdes[Key]:Serialize(Data[Key], true)
        TotalSize += Size

        table.insert(BufferLengths, Size)
        table.insert(Buffers, Buffer)
    end

    local FinalBuffer: buffer = buffer.create(TotalSize)
    local Cursor: number = 0;

    for Index: number, Buffer in Buffers do
        buffer.copy(FinalBuffer, Cursor, Buffer, 0)
        Cursor += BufferLengths[Index]
    end

    return FinalBuffer, has and TotalSize or nil
end

local function Deserialize(self: TableSerde, Data: buffer, Cursor: number?, has: boolean?): ({[string]: any}, number?)
    local LocalCursor: number = Cursor or 0;

    local SerializedTable: {[string]: any} = {}

    for _, Key: string in self._SerdeOrder do
        local Serde: PacketSerde = self._Serdes[Key]
        SerializedTable[Key], LocalCursor = Serde:Deserialize(Data, LocalCursor, true)
    end

    return SerializedTable, has and LocalCursor or nil
end

return function(Structure: {[string]: Serdes}): PacketSerde
    if type(Structure) ~= "table" then
        return error("Dictionary type must be a table")
    end

    local Serdes: { [string]: any } = {}
    local SerdeOrder: {string} = {};

    for Index: any, Serde: Serdes in Structure do
        if type(Index) ~= "string" then
            return error("Index values must be strings")
        end

        Serdes[Index] = Serde

        table.insert(SerdeOrder,Index)
    end

    return {
        Serialize = Serialize;
        Deserialize = Deserialize;

        _Serdes = Serdes;
        _SerdeOrder = SerdeOrder;
    } :: any
end
