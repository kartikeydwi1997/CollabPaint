import std.socket;
import std.stdio;
import std.conv;
import std.file;
import core.time;
import core.thread;
import gui;
import std.string;

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;
SDLSupport ret;

/**
 * This is the main function of the application.
 * It is responsible for initializing SDL, and then
 * creating the main window and running the application.
 */
shared static this(){
	// Load the SDL libraries from bindbc-sdl
	// on the appropriate operating system
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

@("Save Surface - Extra feature")
unittest
{
    Gui test = new Gui();
    Thread t1 = new Thread({
        test.GuiRun();
    });
    Thread t2 = new Thread({
        test.saveSurface("testtt.bmp");
        test.QuitApp();
    });
    t1.start();
    t1.sleep(dur!"msecs"(2000));
    t2.start();
    
    assert(exists("testtt.bmp"));
}

@("Load Surface - Extra feature")
unittest
{
    Gui test = new Gui();
    Thread t1 = new Thread({
        test.GuiRun();
    });
    Thread t2 = new Thread({
        test.loadSurface("test.bmp");
        test.QuitApp();
    });
    t1.start();
    t1.sleep(dur!"msecs"(2000));
    t2.start();
    
    assert(exists("test.bmp"));
}