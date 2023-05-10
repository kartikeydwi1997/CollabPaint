module server;
import std.socket;
import std.stdio;
import core.thread.osthread;
import std.file;

// modules
import Packet : Packet;
import gui;
import colors;


/** The server will listen for connections from clients.
 *  When a client connects, the server will spawn a new thread
 *  to handle the client.
 *  The server will then listen for more connections.
 *  The server will also listen for data from clients.
 *  When data is received from a client, the server will
 *  broadcast that data to all other clients.
 *  The server will also listen for data from the GUI.
 *  When data is received from the GUI, the server will
 *  broadcast that data to all other clients.
 */
class TCPServer{

    Gui         myGui;
    /// The listening socket is responsible for handling new client connections.
    Socket 		mListeningSocket;
    /// Stores the clients that are currently connected to the server.
    Socket[] 	mClientsConnectedToServer;

    /// Stores all of the data on the server. Ideally, we'll 
    /// use this to broadcast out to clients connected.
    char[Packet.sizeof][] mServerData;
    /// Keeps track of the last message that was broadcast out to each client.
    uint[] 			mCurrentMessageToSend;
    
    /// Constructor
    /// By default I have choosen localhost and a port that is likely to
    /// be free.
    this(string host = "localhost", ushort port=50000, ushort maxConnectionsBacklog=4){
        writeln("Starting server...");
        writeln("Server must be started before clients may join");
        // Note: AddressFamily.INET tells us we are using IPv4 Internet protocol
        // Note: SOCK_STREAM (SocketType.STREAM) creates a TCP Socket
        //       If you want UDPClient and UDPServer use 'SOCK_DGRAM' (SocketType.DGRAM)
        mListeningSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
        // Set the hostname and port for the socket
        // NOTE: It's possible the port number is in use if you are not able
        //  	 to connect. Try another one.
        // When we 'bind' we are assigning an address with a port to a socket.
        mListeningSocket.bind(new InternetAddress(host,port));
        // 'listen' means that a socket can 'accept' connections from another socket.
        // Allow 4 connections to be queued up in the 'backlog'
        mListeningSocket.listen(maxConnectionsBacklog);
    }

    /// Destructor
    ~this(){
        // Close our server listening socket
        // TODO: If it was never opened, no need to call close
        mListeningSocket.close();
    }
    /// Attach the GUI to the server
    void attachGui(Gui myGui){
        this.myGui = myGui;
    }

    /// write the buffer to a file
    void storeBuffer(string filePath) {
        std.file.write(filePath, mServerData);
    }

    /// load the buffer from a file
    void[] loadBuffer(string filePath) {
        return std.file.read(filePath);
    }

    /// set the server data
    void setServerData(char[Packet.sizeof][] bufferData) {
        mServerData = bufferData;
    }

    /**
    * Call this after the server has been created
    * to start running the server
    */
    void run(){
        bool serverIsRunning=true;
        while(serverIsRunning){
            // The servers job now is to just accept connections
            writeln("Waiting to accept more connections");
            /// accept is a blocking call.
            auto newClientSocket = mListeningSocket.accept();
            // After a new connection is accepted, let's confirm.
            writeln("Hey, a new client joined!");
            writeln("(me)",newClientSocket.localAddress(),"<---->",newClientSocket.remoteAddress(),"(client)");
            // Now pragmatically what we'll do, is spawn a new
            // thread to handle the work we want to do.
            // Per one client connection, we will create a new thread
            // in which the server will relay messages to clients.
            mClientsConnectedToServer ~= newClientSocket;
            // Set the current client to have '0' total messages received.
            // NOTE: You may not want to start from '0' here if you do not
            //       want to send a client the whole history.
            mCurrentMessageToSend ~= 0;

            writeln("Friends on server = ",mClientsConnectedToServer.length);
            // Let's send our new client friend a welcome message
            newClientSocket.send("Hello friend\0");
            // call here to let client force get history
            // Now we'll spawn a new thread for the client that
            // has recently joined.
            // The server will now be running multiple threads and
            // handling a chat here with clients.
            //
            // NOTE: The index sent indicates the connection in our data structures,
            //       this can be useful to identify different clients.
            new Thread({
                    clientLoop(newClientSocket);
                }).start();

            // new Thread({
			// 		// receiveDataFromServer();
			// 		receivePacketFromClient();
			// 	}).start();
            // After our new thread has spawned, our server will now resume 
            // listening for more client connections to accept.
        }
    }

    /// Function to spawn from a new thread for the client.
    /// The purpose is to listen for data sent from the client 
    /// and then rebroadcast that information to all other clients.
    /// NOTE: passing 'clientSocket' by value so it should be a copy of 
    ///       the connection.
    void clientLoop(Socket clientSocket){
            writeln("\t Starting clientLoop:(me)",clientSocket.localAddress(),"<---->",clientSocket.remoteAddress(),"(client)");
        
        bool runThreadLoop = true;

        while(runThreadLoop){
            // Check if the socket isAlive
            if(!clientSocket.isAlive){
                // Then remove the socket
                runThreadLoop=false;
                break;
            }

            // Message buffer will be 80 bytes 
            char[Packet.sizeof] buffer;
            // Server is now waiting to handle data from specific client
            // We'll block the server awaiting to receive a message. 	
            auto got = clientSocket.receive(buffer);
            auto fromClient = buffer[0 .. clientSocket.receive(buffer)];					
            writeln("Received some data (bytes): ",got);


            writeln("sizeof fromServer:",fromClient.length);
			writeln("sizeof Packet    :", Packet.sizeof);
			writeln("buffer length    :", buffer.length);
			writeln("fromServer (raw bytes): ",fromClient);
			writeln();	
			Packet formattedPacket;
			char[16] field0        = fromClient[0 .. 16].dup;
			formattedPacket.user = cast(char[])(field0);
			writeln("Server echos back user: ", formattedPacket.user);

			// Get some of the fields
			char[4] field1        = fromClient[16 .. 20].dup;
			char[4] field2        = fromClient[20 .. 24].dup;
			int f1 = *cast(int*)&field1;
			int f2 = *cast(int*)&field2;
			formattedPacket.x = f1;
			formattedPacket.y = f2;
            char[4] red = fromClient[24 .. 28].dup;
			char[4] green = fromClient[28 .. 32].dup;
			char[4] blue = fromClient[32 .. 36].dup;
            writeln("server received rgb: ", red, green, blue);
            int r = *cast(int*)&red;
            int g = *cast(int*)&green;
            int b = *cast(int*)&blue;
            
            // char[64] message_client = fromClient[27 .. 91].dup;
            char[4] command_char = fromClient[36 .. 40].dup;
			int command = *cast(int*)&command_char;
            writeln("Undo status writing from server", command);

            if(command == 0) {
                writeln("server is drawing!!!!!!!");
			    this.myGui.draw(formattedPacket.x, formattedPacket.y , 4, cast(byte) r, cast(byte) g, cast(byte) b);
            } else if(command == 1) {
                this.myGui.undo_action();
            } else if(command == 2) {
				writefln("Performing Redo from Server");
				this.myGui.redo_action();
			}

            // Store data that we receive in our server.
            // We append the buffer to the end of our server
            // data structure.
            // NOTE: Probably want to make this a ring buffer,
            //       so that it does not grow infinitely.
            mServerData ~= buffer;

            /// After we receive a single message, we'll just 
            /// immedietely broadcast out to all clients some data.
            broadcastToAllClients();
        }
                        
    }

    /// Function to store the buffer to a file.
    void saveBuffer() {
        string filePath = "buffer.bin";
        storeBuffer(filePath);
    }

    /// The purpose of this function is to broadcast
    /// messages to all of the clients that are currently
    /// connected.
    void broadcastToAllClients(){
        writeln("Server is broadcasting");
        writeln("Broadcasting to :", mClientsConnectedToServer.length);
        foreach(idx,serverToClient; mClientsConnectedToServer){
            // Send whatever the latest data was to all the 
            // clients.
            while(mCurrentMessageToSend[idx] <= mServerData.length-1){
                writefln("current Message to send to %d client is %d", idx, mCurrentMessageToSend[idx]);
                char[Packet.sizeof] msg = mServerData[mCurrentMessageToSend[idx]];
                serverToClient.send(msg[0 .. Packet.sizeof]);	
                // Important to increment the message only after sending
                // the previous message to as many clients as exist.
                mCurrentMessageToSend[idx]++;
            }
        }
    }

    /// The purpose of this function is to broadcast a packet to all the clients
    void broadcastPacketToAllClients(char[] data){
        writeln("Server is broadcasting packet");
        foreach(idx,serverToClient; mClientsConnectedToServer){
            // Send whatever the latest data was to all the 
            // clients.
            
            // char[80] msg = mServerData[mCurrentMessageToSend[idx]];
            // serverToClient.send(msg[0 .. 80]);	
            serverToClient.send(data);
            // Important to increment the message only after sending
            // the previous message to as many clients as exist.
        }
    }
}