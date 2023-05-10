import Packet: Packet;
import core.stdc.string;

char[Packet.sizeof] MockPacketInBytes(){
    char[16] user = "test user\0";
    char[Packet.sizeof] payload;
    int x = 0;
    int y = 0;
    int r = 0;
    int g = 10;
    int b = 12;
    int command = 4;
    // Populate the payload with some bits
    // I used memmove for this to move the bits.
    memmove(&payload,&user,user.sizeof);
    // Populate the color with some bytes
    import std.stdio;
    memmove(&payload[16],&x,x.sizeof);
    memmove(&payload[20],&y,y.sizeof);
    memmove(&payload[24],&r, r.sizeof);
    memmove(&payload[28],&g, g.sizeof);
    memmove(&payload[32],&b, b.sizeof);
    memmove(&payload[36],&command, command.sizeof);

    return payload;
}

@("Packet payload testing")
unittest {
    Packet data;
    with (data) {
        x = 0;
        y = 0;
        r = 0;
        g = 10;
        b = 12;
        command = 4;
    }

    char[40] recv_packet_Bytes = data.GetPacketAsBytes();
    // char[40] mock_packet_bytes = MockPacketInBytes();
    assert(recv_packet_Bytes == MockPacketInBytes());
}

