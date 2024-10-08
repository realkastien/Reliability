local Types = require(script.Parent.Types)

export type PacketSerde = Types.PacketSerde

local Serde = {
    Dict = require(script:WaitForChild("Dict"));
    Array = require(script:WaitForChild("Array"));
    Tuple = require(script:WaitForChild("Tuple"));

    String = require(script:WaitForChild("String"));

    UInt8 = require(script:WaitForChild("UInt8"));
    UInt16 = require(script:WaitForChild("UInt16"));
    UInt32 = require(script:WaitForChild("UInt32"));

    Vector3 = require(script:WaitForChild("Vector3"));
    CFrame = require(script:WaitForChild("CFrame"));

    Buffer = require(script:WaitForChild("Buffer"));
}

return Serde