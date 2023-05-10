module app;


import std.socket;
import std.stdio;
import core.thread.osthread;
import std.string;
import std.getopt;

/// modules
import gui;
import server,client;
import utils;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;
SDLSupport ret;

 /// This is the main function of the application.
 /// It is responsible for initializing SDL, and then
 /// creating the main window and running the application.
 ///
shared static this(){
	/// Load the SDL libraries from bindbc-sdl
	/// on the appropriate operating system
	version(Windows){
		writeln("Searching for SDL on Windows");
		ret = loadSDL("SDL2.dll");
	}
	version(OSX){
		writeln("Searching for SDL on Mac");
		ret = loadSDL();
	}
	version(linux){ 
		writeln("Searching for SDL on Linux");
		ret = loadSDL();
	}

	// Error if SDL cannot be loaded
	if(ret != sdlSupport){
		writeln("error loading SDL library");
		
		foreach( info; loader.errors){
			writeln(info.error,':', info.message);
		}
	}
	if(ret == SDLSupport.noLibrary){
		writeln("error no library found");    
	}
	if(ret == SDLSupport.badLibrary){
		writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
	}

	// Initialize SDL
	if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
		writeln("SDL_Init: ", fromStringz(SDL_GetError()));
	}
}

/// At the module level, when we terminate, we make sure to 
/// terminate SDL, which is initialized at the start of the application.
shared static ~this(){
	// Quit the SDL Application 
	SDL_Quit();
	writeln("Ending application--good bye!");
}

/**
 * This is the main function of the application.
 * It is responsible for initializing SDL, and then
 * creating the main window and running the application.
 * It parses the command line arguments to determine whether to run in server or client mode, and to specify the IP 
 * address and port number to use. If running in client mode, it creates a TCPClient object and a Gui object, attaches 
 * them to each other, and starts two threads to run the client and GUI logic. If running in server mode, it creates a 
 * TCPServer object and a Gui object, attaches them to each other, and starts two threads to run the server and GUI logic.
 */
void main(string[] args){

	TCPServer server;
	TCPClient client;
	Gui myGui;
	string address = "127.0.0.1";
	auto ip = getIP();
	ushort port = 3030;
	string mode = "server";

    auto helpInformation = getopt(
        args,
        "mode",  &mode,   
        "ip",    &ip,
		"port",  &port
      );

    if (helpInformation.helpWanted)
    {
        defaultGetoptPrinter("Please use --mode server --port 5164 for server, --mode client --ip <ip> --port <port> for client",
        helpInformation.options);
    }	

	if(mode == "client"){
		client = new TCPClient(ip, port); //bug it will occupy the port

		myGui = new Gui();

		myGui.attachClient(client);
		client.attachGui(myGui);

		Thread t1 = new Thread({
			client.run();
		});
		Thread t2 = new Thread({
			myGui.GuiRun();
		});
		t1.start();
		t2.start();
		t1.join();
		t2.join();
	} else if(mode == "server"){
		writefln("Please inform users to join %s at %d", ip, port);

		server = new TCPServer(ip, port);

		myGui = new Gui();

		myGui.attachServer(server);
		server.attachGui(myGui);


		Thread t1 = new Thread({
			server.run();
		});
		Thread t2 = new Thread({
			myGui.GuiRun();
		});
		t1.start();
		t2.start();
		t1.join();
		t2.join();
	}
	// important!
	scope(exit){
		if(server !is null){
			server.mListeningSocket.close();
		}
		if(client !is null){
			client.mSocket.close();
		}
		writeln("Succeed exit");
	}

}
