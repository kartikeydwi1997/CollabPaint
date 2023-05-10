module utils;
import std.stdio;
import std.socket;

string getIP(){
    string ip = "";

    // A bit of a hack, but we'll create a connection from google to
    // our current ip.
    // Use a well known port (i.e. google) to do this
    auto r = getAddress("8.8.8.8",53); // NOTE: This is effetively getAddressInfo
    // writeln(r); // See 1 or more 'ips'
    // Create a socket
    auto sockfd = new Socket(AddressFamily.INET,  SocketType.STREAM);
    // Connect to the google server
    import std.conv;
    const char[] address = r[0].toAddrString().dup;
    ushort port = to!ushort(r[0].toPortString());
    sockfd.connect(new InternetAddress(address,port));
    // Obtain local sockets name and address
    ip = sockfd.localAddress.toAddrString();
    // writeln(sockfd.hostName);
    // writeln("Our ip address    : ",sockfd.localAddress);
    // writeln("the remote address: ",sockfd.remoteAddress);

    // Close our socket
    sockfd.close();
    return ip;
}