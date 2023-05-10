module gui;

import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.Button;
import gdk.Event;
import gtk.Container;
import gtk.DrawingArea;
import gtk.Box;
import gtk.Layout; 
import gtk.Menu;
import gtk.MenuBar;
import gtk.MenuItem;
import gtk.ComboBoxText;
import gtk.ListStore;

/// GDK functions for grabbing window
import gdk.Window;
import gdk.X11;

import glib.Idle;

/// Import D standard libraries
import std.stdio;
import std.string;
import std.algorithm;

/// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

/// modules
import server, client;
import surfaceOperation;
import Packet : Packet;
import colors;

import std.stdio;
import std.file;

/**
    * The Gui class is responsible for handling all of the GUI
    * related functionality. This includes creating the window,
    * handling events, and drawing to the window.
*/
class Gui{

    TCPServer       server;
    TCPClient       client;
    string          windowName;

    Window          gdkWindowForSDL;
    uint            gdkWindowXID;
    Command[]       CommandQueue;
    Command[]       RedoQueue;
    SDL_Surface*    imgSurface= null;
    bool            drawing = false;
    byte red = cast(byte) colors.PaintBrushColor.BLUE[0];
    byte green = cast(byte) colors.PaintBrushColor.BLUE[1];
    byte blue = cast(byte) colors.PaintBrushColor.BLUE[2];

    this(){}
    
    /// Attach the client to the GUI
    void attachClient(TCPClient client){
        this.client = client;
        this.windowName = "client";
    }
    /// Attach the server to the GUI
    void attachServer(TCPServer server){
        this.server = server;
        this.windowName = "server";
    }

    // This function handles mouse events such as button presses and motion notifies.
    // If a button is pressed, it sets the variable "drawing" to true.
    // If there is a motion notify event and "drawing" is true, it retrieves the coordinates of the event and prints them to the console.
    bool onMousePressed(Event event, Widget widget){
        bool result = false;
        if(event.type == EventType.BUTTON_PRESS){
            // Set drawing to true so we are in a draw state
            drawing=true;
        }

        if(event.type == EventType.MOTION_NOTIFY && drawing==true){
            // Retrieve coordinates of where event happened
            double xPos,yPos;
            event.getRootCoords(xPos,yPos);
            writeln("(rootCoords) mouse pressed:",xPos,yPos);
            event.getCoords(xPos,yPos);
            writeln("(relativeCoords) mouse pressed:",xPos,yPos);
        }

        return result;
    }

    /// This function set brush colors to  red, green, blue
    void setBrushColor(byte r, byte g, byte b) {
        this.red = r;
        this.green = g;
        this.blue = b;
    }

    /// This function draws a brush on an image surface at a specified position with a specified size and color.
    /// It loops over the brush size and creates a new SurfaceOperation command for each pixel in the brush area.
    void draw(double xPos, double yPos, int brushSize, byte red, byte green, byte blue){
        for(int w=-brushSize; w < brushSize; w++){
            for(int h=-brushSize; h < brushSize; h++){
                // Create a new command
                auto command = new SurfaceOperation(imgSurface,cast(uint)(xPos+w),cast(uint)(yPos+h), red, green, blue);
                // Append to the end of our queue
                CommandQueue ~= command;
                // Execute the last command
                CommandQueue[$-1].Execute();
            }
        }
        writefln("%f, %f, %d, %d, %d", xPos, yPos, red, green, blue);

    }
    /// This function creates a Packet object with data for an 'undo' action and sends it to all clients via the server.
    /// If there is no server, the 'undo' action is executed locally.
    /// If there is a client, it sends the packet to the server for processing.
    void undo_callback(){
        Packet data;
        // The 'with' statement allows us to access an object
        // (i.e. member variables and member functions)
        // in a slightly more convenient way
        with (data){
            user = "clientName\0";
            // Just some 'dummy' data for now
            // that the 'client' will continuously send
            x = 0;
            y = 0;
            // hard code color
            r = 0;
            g = 0;
            b = 0;
            command = 1;
        }
        if(this.server !is null){
            server.broadcastPacketToAllClients(data.GetPacketAsBytes());
            undo_action();
        }
        if(this.client !is null){
            writeln("client is sending packet");
            client.sendPacketToServer(data.GetPacketAsBytes());
        }
    }

    /// This function creates a Packet object with data for a 'redo' action and sends it to all clients via the server.
    /// If there is no server, the 'redo' action is executed locally.
    /// If there is a client, it sends the packet to the server for processing.
    void redo_callback(){
        Packet data;
        // The 'with' statement allows us to access an object
        // (i.e. member variables and member functions)
        // in a slightly more convenient way
        with (data){
            user = "clientName\0";
            // Just some 'dummy' data for now
            // that the 'client' will continuously send
            x = 0;
            y = 0;
            // hard code color
            r = 0;
            g = 0;
            b = 0;
            command = 2;
        }
        if(this.server !is null){
            server.broadcastPacketToAllClients(data.GetPacketAsBytes());
            redo_action();
        }
        if(this.client !is null){
            writeln("client is sending packet");
            client.sendPacketToServer(data.GetPacketAsBytes());
        }
    }

    /// This function pop the last operation in RedoQueue and execute it and push it to CommandQueue
    void redo_action() {
        if (RedoQueue.length > min(0, 100)) {
            for(int i=0; i < min(RedoQueue.length, 100); i++) {
                RedoQueue[$-1].Execute();
                CommandQueue ~= RedoQueue[$-1];
                RedoQueue.length--;
            }
        }
    }

    /// This function pop the last operation in CommandQueue and undo it and push it to RedoQueue
    void undo_action() {
        if(CommandQueue.length > min(0,100)){
            for(int i=0; i < min(CommandQueue.length,100); i++){
                // Append to the end of our queue
                CommandQueue[$-1].Undo();
                RedoQueue ~= CommandQueue[$-1];
                CommandQueue.length--;
            }
        }
    }

    void saveSurface(string fileName){
        SDL_SaveBMP(imgSurface, fileName.ptr);
    }

    /// This function loads a saved image surface from a file.
    void loadSurface(string fileName){
        if (exists("test.bmp")) {
            imgSurface = SDL_LoadBMP(fileName.ptr);
            SDL_Surface* tempSurface = SDL_LoadBMP(fileName.ptr);
            imgSurface = SDL_ConvertSurface(tempSurface, imgSurface.format, 0);
            SDL_FreeSurface(tempSurface);
        } else {
            writeln("No saved surface found");
        }
    }

    /// Handle mouse motion after moving brush
    bool onMouseMoved(Event event, Widget widget){
        bool result=false;
        
        if(event.type == EventType.MOTION_NOTIFY && drawing==true){
            // Retrieve coordinates of where event happened
            double xPos,yPos;
            event.getCoords(xPos,yPos);

            // Loop through and update specific pixels
            // NOTE: No bounds checking performed --
            //       think about how you might fix this :)
            int brushSize=4;
            draw(xPos, yPos, brushSize, red, green, blue);
            // pack the data
            // here we need to send packet to clients
            Packet data;
            // The 'with' statement allows us to access an object
            // (i.e. member variables and member functions)
            // in a slightly more convenient way
            with (data){
                user = "clientName\0";
                // Just some 'dummy' data for now
                // that the 'client' will continuously send
                x = cast(int)xPos;
                y = cast(int)yPos;
                // hard code color
                r = cast(int)red;
                g = cast(int)green;
                b = cast(int)blue;
                writeln("demo", this.red, this.green, this.blue);
                writeln("demo", r, g, b);
                command = 0;
            }
            if(this.server !is null){
                // server.broadcastPacketToAllClients(data.GetPacketAsBytes());
                server.mServerData ~= data.GetPacketAsBytes();
                server.broadcastToAllClients();
            }
            if(this.client !is null){
                writeln("client is sending packet");
                client.sendPacketToServer(data.GetPacketAsBytes());
            }
            
            result = true;
        }

        return result;
    }

    /// Handle mouse release events
    bool onMouseReleased(Event event, Widget widget){
        bool result=false;

        if(event.type == EventType.BUTTON_RELEASE){
            drawing = false;
        }

        return result;
    }

    /// Handle mouse press events
    bool onKeyPressed(Event event, Widget widget){
        bool result=false;

        // Handle undo action triggered by Ctrl+Z
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 122 && event.key.state == ModifierType.CONTROL_MASK) {
            undo_callback();
            result = true;
        }

        // Handle undo action triggered by Ctrl+Z
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 121 && event.key.state == ModifierType.CONTROL_MASK) {
            // redo_callback();
            result = true;
        }

        // Handle color change for red
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 114) {
            byte r = cast(byte) colors.PaintBrushColor.RED[0];
            byte g = cast(byte) colors.PaintBrushColor.RED[1];
            byte b = cast(byte) colors.PaintBrushColor.RED[2];
            setBrushColor(r, g, b);
            result = true;
        }

        // Handle color change for blue
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 98) {
            byte r = cast(byte) colors.PaintBrushColor.BLUE[0];
            byte g = cast(byte) colors.PaintBrushColor.BLUE[1];
            byte b = cast(byte) colors.PaintBrushColor.BLUE[2];
            setBrushColor(r, g, b);
            result = true;
        }

        // Handle color change for green
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 103) {
            byte r = cast(byte) colors.PaintBrushColor.GREEN[0];
            byte g = cast(byte) colors.PaintBrushColor.GREEN[1];
            byte b = cast(byte) colors.PaintBrushColor.GREEN[2];
            setBrushColor(r, g, b);
            result = true;
        }

        // Handle color change for white
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 119) {
            byte r = cast(byte) colors.PaintBrushColor.WHITE[0];
            byte g = cast(byte) colors.PaintBrushColor.WHITE[1];
            byte b = cast(byte) colors.PaintBrushColor.WHITE[2];
            setBrushColor(r, g, b);
            result = true;
        }

        // Save image
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 115) {
            if(this.server !is null){
                saveSurface("test.bmp");
                server.saveBuffer();
            }
            result = true;
        }

        // Load image
        if (event.type == EventType.KEY_PRESS && event.key.keyval == 108) {
            if(this.server !is null){
                loadSurface("test.bmp");
                void[] bufferData = server.loadBuffer("buffer.bin");
                writeln(bufferData);
                char[40][] bufferDataChar = cast(char[40][])bufferData;
                server.setServerData(bufferDataChar);
            }
            
            result = true;
        }

        return result;
    }

    /// SDL Portion of the program 
    bool RunSDL()
    {
        static SDL_Window* window=null;
        // Flag for determing if we are running the main application loop
        static bool runApplication = true;
        // Flag for determining if we are 'drawing' (i.e. mouse has been pressed
        //                                                but not yet released)

        if(window==null){
            window = SDL_CreateWindowFrom(cast(const(void)*)gdkWindowXID);
            // Do some error checking to see if we retrieve a window
            if(window==null){
                writeln("window-SDL_GetError()",SDL_GetError());
            }
            // Load the bitmap surface
            imgSurface = SDL_CreateRGBSurface(0,640,480,32,0,0,0,0);
            if(imgSurface==null){
                writeln("imgSurface-SDL_GetError()",SDL_GetError());
            }
        }

        if(window!=null){
                // Blit the surace (i.e. update the window with another surfaces pixels
                //                       by copying those pixels onto the window).
                SDL_BlitSurface(imgSurface,null,SDL_GetWindowSurface(window),null);
                // Update the window surface
                SDL_UpdateWindowSurface(window);
                // Delay for 16 milliseconds
                // Otherwise the program refreshes too quickly
            //}
        }

        // Free the image
        scope(exit) {
        }
        return true;
    }


    /// Exit from the application
    void QuitApp(){
        writeln("Terminating application");

        Main.quit();
    }

    /// Main entry point for the application
    void GuiRun(){
        string[] args;
        // Initialize GTK
        Main.init(args);
        // Setup our window
        MainWindow myWindow = new MainWindow("Luminate");
        myWindow.setTitle(windowName);
        // Position our window
        myWindow.setDefaultSize(640,480);
        int w,h;
        myWindow.getSize(w,h);
        writeln("width   : ",w);
        writeln("height  : ",h);
        myWindow.move(100,120);
        
        // Delegate to call when we destroy our application
        myWindow.addOnDestroy(delegate void(Widget w) { QuitApp(); });

        // Create a new Box
        const int globalPadding=2;
        const int localPadding= 2;
        auto myBox = new Box(Orientation.VERTICAL,globalPadding);

        // Create a menu bar and menu items
        auto menuBar = new MenuBar;
        auto menuItem1 = new MenuItem("File");
        menuBar.append(menuItem1);

        // Create a menu for our menu item
        auto menu1 = new Menu;
        auto menuNew  = new MenuItem("New");
        auto menuExit = new MenuItem("Exit");

        // Add some functions to our menu 
        // We use a delagate, and observe this time that we are
        // using 'MenuItem m' as our parameter because that is the type.
        menuNew.addOnActivate(delegate void (MenuItem m){writeln("pressed new");}); 

        // Append menu items to our menu
        menu1.append(menuNew);
        menu1.append(menuExit);
        // Attach this menu item as a submenu
        menuItem1.setSubmenu(menu1);
            
        // Add menu and do not expand or fill or pad 
        myBox.packStart(menuBar,false,false,0);

        // Create a new drawing area
        auto gtkDrawingArea = new DrawingArea;
        gtkDrawingArea.setSizeRequest(640,480);
        myBox.packStart(gtkDrawingArea,true,true,localPadding);

        
        // Add a dropdown
        auto colorDropdown = new ComboBoxText;
        colorDropdown.appendText("Blue");
        colorDropdown.appendText("Green");
        colorDropdown.appendText("Red");
        colorDropdown.appendText("White");
        colorDropdown.setActive(0); // Set the default selection to "Blue"
        myBox.packStart(colorDropdown, false, false, 0);

        writeln(colorDropdown.getActiveText());

        colorDropdown.addOnChanged(delegate void(ComboBoxText t) {
            writeln(colorDropdown.getActiveText());
            if (colorDropdown.getActiveText() == "Blue") {
                setBrushColor(cast(byte) colors.PaintBrushColor.BLUE[0], cast(byte) colors.PaintBrushColor.BLUE[1], cast(byte) colors.PaintBrushColor.BLUE[2]);
            } else if(colorDropdown.getActiveText() == "Green") {
                setBrushColor(cast(byte) colors.PaintBrushColor.GREEN[0], cast(byte) colors.PaintBrushColor.GREEN[1], cast(byte) colors.PaintBrushColor.GREEN[2]);
            } else if(colorDropdown.getActiveText() == "Red") {
                setBrushColor(cast(byte) colors.PaintBrushColor.RED[0], cast(byte) colors.PaintBrushColor.RED[1], cast(byte) colors.PaintBrushColor.RED[2]);
            } else if(colorDropdown.getActiveText() == "White") {
                setBrushColor(cast(byte) colors.PaintBrushColor.WHITE[0], cast(byte) colors.PaintBrushColor.WHITE[1], cast(byte) colors.PaintBrushColor.WHITE[2]);
            }
        });

        // We'll now create a 'button' to add to our aplication.
        Button undo_button = new Button("Undo");
        Button redo_button = new Button("Redo");
        Button myButton3 = new Button("Button3 Text");

        Layout myLayout = new Layout(null,null);
        myLayout.put(myButton3,0,0);

        // button    expand fill padding
        myBox.packStart(undo_button,true,true,localPadding);
        myBox.packStart(redo_button,true,true,localPadding);
        myBox.packStart(myLayout,true,true,localPadding);

        // Action for when we click a button

    	undo_button.addOnClicked(delegate void(Button b) {
							    undo_callback();
						    });

        redo_button.addOnClicked(delegate void(Button b) {
							    redo_callback();
						    });

        // colorDropdown.onChange(&onColorChange);
        // Action for when mouse is released
    
        // Add to our window the box
        // as a child widget
        myWindow.add(myBox);

        // Create a container to store the drawing area
        auto myContainer = new GtkContainer;
        //myContainer.add(gtkDrawingArea);
        //myWindow.add(myContainer);
        
        // Show our window
        myWindow.showAll();

        // Useful information for SDL within a GTK window
        // https://stackoverflow.com/questions/47284284/how-to-render-sdl2-texture-into-gtk3-window
        gtkDrawingArea.realize(); // May not be necessary, but forces component to be built first
        gdkWindowForSDL = gtkDrawingArea.getWindow(); 
        gdkWindowXID = gdkWindowForSDL.getXid();
    
        // Creating a new idle event will fire whenever there is not anything
        // else to do -- effectively this is where we will draw in SDL
        auto idle = new Idle(delegate bool(){ return RunSDL();});

        // Handle events on our main window
        // Essentially hook up a bunch of functions to handle input/output
        // events in our program.
        myWindow.addOnButtonPress(delegate bool(Event e,Widget w){ return onMousePressed(e,w);});
        myWindow.addOnButtonRelease(delegate bool(Event e,Widget w){ return onMouseReleased(e,w);});
        myWindow.addOnMotionNotify(delegate bool(Event e,Widget w){ return onMouseMoved(e,w);});
        myWindow.addOnKeyPress(delegate bool(Event e,Widget w){ return onKeyPressed(e,w);});

        // Run our main gtk+3 loop
        Main.run();
    }
}