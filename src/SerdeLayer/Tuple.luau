local Types = require(script.Parent.Parent.Types)

type PacketSerde = Types.PacketSerde
type TupleSerde = Types.TupleSerde
export type TableSerde = Types.TableSerde
export type ArraySerde = Types.ArraySerde

type Serdes = PacketSerde | TableSerde | ArraySerde

local function Serialize(self: TupleSerde, ...:any): ...buffer
    local Buffers: {buffer} = {}

    for Index: number, Value: any in {...} do
        table.insert(Buffers,self._Serdes[Index]:Serialize(Value) :: buffer)
    end

    return table.unpack(Buffers)
end

local function Deserialize(self: TupleSerde, ...: buffer): ...any
    local Values: {any} = {}

    for Index: number, Buffer: buffer in {...} do
        table.insert(Values, self._Serdes[Index]:Deserialize(Buffer) :: any)
    end

    return table.unpack(Values)
end

return function(...:Serdes): TupleSerde
    local SerdeOrder: {PacketSerde} = {};

    for _, Serde: PacketSerde in {...} do
        table.insert(SerdeOrder,Serde)
    end

    return {
        Serialize = Serialize;
        Deserialize = Deserialize;

        _Serdes = SerdeOrder;
    } :: any
end
