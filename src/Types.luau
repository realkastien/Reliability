export type PacketSerde = {
    Serialize: (self: PacketSerde, Data: any, boolean)->(buffer, number) & (self: PacketSerde, Data: any)->buffer;
    Deserialize: (self: PacketSerde, Data: buffer, Cursor: number?, boolean)->(any, number) & (self: PacketSerde, Data: buffer, Cursor: number?)->any;
}

export type TableSerde = {
    Serialize: (self: TableSerde, Data: {[string]: any}, boolean?)->(buffer, number?) & (self: TableSerde, Data: {[string]: any})->buffer;
    Deserialize: (self: TableSerde, Data: buffer, Cursor: number?, boolean?)->({[string]: any}, number?) & (self: TableSerde, Data: buffer, Cursor: number?)->{[string]: any};

    _SerdeOrder: {string};
    _Serdes: {[string]: PacketSerde}
}

export type ArraySerde = {
    Serialize: (self: ArraySerde, Data: {any}, boolean)->(buffer, number?) & (self: ArraySerde, Data: {any})->buffer;
    Deserialize: (self: ArraySerde, Data: buffer, Cursor: number?, boolean?)->({any}, number?) & (self: ArraySerde, Data: buffer, Cursor: number?)->{any};

    _Serde: PacketSerde
}

export type TupleSerde = {
    Serialize: (self: TupleSerde, ...any)->...buffer;
    Deserialize: (self: TupleSerde, ...buffer)->...any;

    _Serdes: {PacketSerde}
}

return nil