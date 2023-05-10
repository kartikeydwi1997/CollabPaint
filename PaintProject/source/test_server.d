import std.socket;
import std.stdio;
import std.conv;
import std.file;
import std.parallelism;
import core.thread;

import server;
import Packet : Packet;

@("Server test - Single clients")
unittest {
    // Create a TCPServer instance
    TCPServer server = new TCPServer("localhost", 5021);

    // Run the server in a separate thread
    Thread serverThread = new Thread({ 
        bool serverIsRunning=true;
        while(serverIsRunning){
            // The servers job now is to just accept connections
            writeln("Waiting to accept more connections");
            /// accept is a blocking call.
            auto newClientSocket = server.mListeningSocket.accept();
            // After a new connection is accepted, let's confirm.
            writeln("Hey, a new client joined!");
            writeln("(me)",newClientSocket.localAddress(),"<---->",newClientSocket.remoteAddress(),"(client)");
            // Now pragmatically what we'll do, is spawn a new
            // thread to handle the work we want to do.
            // Per one client connection, we will create a new thread
            // in which the server will relay messages to clients.
            server.mClientsConnectedToServer ~= newClientSocket;
            // Set the current client to have '0' total messages received.
            // NOTE: You may not want to start from '0' here if you do not
            //       want to send a client the whole history.
            server.mCurrentMessageToSend ~= 0;

            writeln("Friends on server = ",server.mClientsConnectedToServer.length);
            // Let's send our new client friend a welcome message
            newClientSocket.send("Hello friend\0");
            // Thread.sleep(dur!"msecs"(milliseconds))
            serverIsRunning = false;
        }
    });
    serverThread.start();

    serverThread.sleep(dur!"msecs"(3000));
    // Create a client socket and connect to the server
    auto clientSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
    clientSocket.connect(new InternetAddress("localhost", 5021));

    // Receive the welcome message from the server
    char[80] welcomeMessage;
    clientSocket.receive(welcomeMessage);
    assert(to!string(welcomeMessage[0..12]) == "Hello friend");

    // Send a message from the client to the server
    Packet packet;
    packet.x = 10;
    packet.y = 10;
    packet.r = 255;
    packet.g = 255;
    packet.b = 255;
    // packet.message.senderName = "client1";
    // packet.message.body = "Hello server";
    // clientSocket.send(packet.toBytes());

    // Receive the message from the server
    char[Packet.sizeof] buffer;
    // auto numBytesReceived = clientSocket.receive(buffer);
    // assert(numBytesReceived == Packet.sizeof);
    // Packet receivedPacket = Packet.fromBytes(buffer);
    // assert(receivedPacket.type == PacketType.MESSAGE);
    // assert(receivedPacket.message.senderName == "client1");
    // assert(receivedPacket.message.body == "Hello server");

    // Close the client socket
    // clientSocket.shutdown(SocketShutdown.both);
    clientSocket.close();

    // Stop the server thread
    serverThread.join();
}

@("Server test - Multiple clients")
unittest {
    // Create a TCPServer instance
    TCPServer server = new TCPServer("localhost", 5022);

    // Run the server in a separate thread
    Thread serverThread = new Thread({ 
        bool serverIsRunning=true;
        while(serverIsRunning){
            // The servers job now is to just accept connections
            writeln("Waiting to accept more connections");
            /// accept is a blocking call.
            auto newClientSocket = server.mListeningSocket.accept();
            auto newClientSocket1 = server.mListeningSocket.accept();
            
            // After a new connection is accepted, let's confirm.
            writeln("Hey, a new client joined!");
            writeln("(me)",newClientSocket.localAddress(),"<---->",newClientSocket.remoteAddress(),"(client)");
            writeln("(me)",newClientSocket.localAddress(),"<---->",newClientSocket1.remoteAddress(),"(client)");

            // Now pragmatically what we'll do, is spawn a new
            // thread to handle the work we want to do.
            // Per one client connection, we will create a new thread
            // in which the server will relay messages to clients.
            server.mClientsConnectedToServer ~= newClientSocket;
            server.mClientsConnectedToServer ~= newClientSocket1;

            // Set the current client to have '0' total messages received.
            // NOTE: You may not want to start from '0' here if you do not
            //       want to send a client the whole history.
            server.mCurrentMessageToSend ~= 0;

            writeln("Friends on server = ",server.mClientsConnectedToServer.length);
            // Let's send our new client friend a welcome message
            newClientSocket.send("Hello friend\0");
            newClientSocket1.send("Hello friend\0");
            // Thread.sleep(dur!"msecs"(milliseconds))
            serverIsRunning = false;
        }
    });
    serverThread.start();

    serverThread.sleep(dur!"msecs"(3000));
    // Create a client socket and connect to the server
    auto clientSocket = new Socket(AddressFamily.INET, SocketType.STREAM);
    clientSocket.connect(new InternetAddress("localhost", 5022));

    auto clientSocket1 = new Socket(AddressFamily.INET, SocketType.STREAM);
    clientSocket1.connect(new InternetAddress("localhost", 5022));


    // Receive the welcome message from the server
    char[80] welcomeMessage;
    char[80] welcomeMessage1;
    clientSocket.receive(welcomeMessage);
    clientSocket1.receive(welcomeMessage1);
    assert(to!string(welcomeMessage[0..12]) == "Hello friend");
    assert(to!string(welcomeMessage1[0..12]) == "Hello friend");

    // Send a message from the client to the server
    Packet packet;
    packet.x = 10;
    packet.y = 10;
    packet.r = 255;
    packet.g = 255;
    packet.b = 255;
    // packet.message.senderName = "client1";
    // packet.message.body = "Hello server";
    // clientSocket.send(packet.toBytes());

    // Receive the message from the server
    char[Packet.sizeof] buffer;
    // auto numBytesReceived = clientSocket.receive(buffer);
    // assert(numBytesReceived == Packet.sizeof);
    // Packet receivedPacket = Packet.fromBytes(buffer);
    // assert(receivedPacket.type == PacketType.MESSAGE);
    // assert(receivedPacket.message.senderName == "client1");
    // assert(receivedPacket.message.body == "Hello server");

    // Close the client socket
    // clientSocket.shutdown(SocketShutdown.both);
    clientSocket.close();
    clientSocket1.close();

    // Stop the server thread
    serverThread.join();
}