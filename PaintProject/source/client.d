// @file chat/client.d
//
// After starting server (rdmd server.d)
// then start as many clients as you like with "rdmd client.d"
//
module client;

import std.socket;
import std.stdio;
import core.thread.osthread;
// modules
import gui;
import Packet : Packet;
import colors;

/** 
* The purpose of the TCPClient class is to 
* connect to a server and send messages.
*/
class TCPClient{

	/// The client socket connected to a server
	Socket mSocket;
	Gui myGui;
	
	/// Constructor
	this(string host = "localhost", ushort port=50002){
		writeln("Starting client...attempt to create socket");
		/// Create a socket for connecting to a server
		/// Note: AddressFamily.INET tells us we are using IPv4 Internet protocol
		/// Note: SOCK_STREAM (SocketType.STREAM) creates a TCP Socket
		///       If you want UDPClient and UDPServer use 'SOCK_DGRAM' (SocketType.DGRAM)
		mSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
		/// Socket needs an 'endpoint', so we determine where we
		/// are going to connect to.
		/// NOTE: It's possible the port number is in use if you are not
		///       able to connect. Try another one.
		mSocket.connect(new InternetAddress(host, port));
		writeln("client conncted to server");
		/// Our client waits until we receive at least one message
		/// confirming that we are connected
		/// This will be something like "Hello friend\0"
		char[80] buffer;
		auto received = mSocket.receive(buffer);
		writeln("(incoming from server) ", buffer[0 .. received]);
	}

	/// Destructor 
	~this(){
		// Close the socket
		mSocket.close();
	}

	///attach gui to current instance
	void attachGui(Gui myGui){
		this.myGui = myGui;
	}
	/// Purpose here is to run the client thread to constantly send data to the server.
	/// This is your 'main' application code.
	/// 
	/// In order to make life a little easier, I will also spin up a new thread that constantly
	/// receives data from the server.
	void run(){
		writeln("Preparing to run client");
		writeln("(me)",mSocket.localAddress(),"<---->",mSocket.remoteAddress(),"(server)");
		// Buffer of data to send out
		// Choose '80' bytes of information to be sent/received

		bool clientRunning=true;
		
		// Spin up the new thread that will just take in data from the server
		new Thread({
					receivePacketFromServer();
				}).start();
	
	}
	/// Purpose of this function is to send data to the server as it is broadcast out.
    void sendPacketToServer(char[] data){
        writeln("Server is broadcasting packet");
        mSocket.send(data);
    }

	/// Purpose of this function is to receive data from the server as it is broadcast out.
	void receiveDataFromServer(){
		while(true){	
			// Note: It's important to recreate or 'zero out' the buffer so that you do not
			// 			 get previous data leftover in the buffer.
			char[80] buffer;
			auto fromServer = buffer[0 .. mSocket.receive(buffer)];
			if(fromServer.length > 0){
				writeln("(from server)>",fromServer);
			}
		}
	}
	/// Purpose of this function is to receive data from the server as it is broadcast out.
	void receivePacketFromServer(){
		while(true){
			char[Packet.sizeof] buffer;
			auto fromServer = buffer[0 .. mSocket.receive(buffer)];
			writeln("sizeof fromServer:",fromServer.length);
			writeln("sizeof Packet    :", Packet.sizeof);
			writeln("buffer length    :", buffer.length);
			writeln("fromServer (raw bytes): ",fromServer);
			writeln();	
			Packet formattedPacket;
			char[16] field0        = fromServer[0 .. 16].dup;
			formattedPacket.user = cast(char[])(field0);

			// Get some of the fields
			char[4] field1        = fromServer[16 .. 20].dup;
			char[4] field2        = fromServer[20 .. 24].dup;
			int f1 = *cast(int*)&field1;
			int f2 = *cast(int*)&field2;
			formattedPacket.x = f1;
			formattedPacket.y = f2;
			char[4] red = fromServer[24 .. 28].dup;
			char[4] green = fromServer[28 .. 32].dup;
			char[4] blue = fromServer[32 .. 36].dup;
            int r = *cast(int*)&red;
            int g = *cast(int*)&green;
            int b = *cast(int*)&blue;
			// char[64] message_client = fromServer[27 .. 91].dup;
            char[4] command_char = fromServer[36 .. 40].dup;
			int command = *cast(int*)&command_char;
            writeln("Undo status writing from Client", command);
			if (command == 0) {
				this.myGui.draw(formattedPacket.x, formattedPacket.y , 4, cast(byte) r, cast(byte) g, cast(byte) b);
			} else if(command == 1) {
				writefln("Performing undo from Clinet");
				this.myGui.undo_action();
			} else if(command == 2) {
				writefln("Performing Redo from Clinet");
				this.myGui.redo_action();
			}

		}
	}

	
}

