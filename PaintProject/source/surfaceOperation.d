module surfaceOperation;
// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;


/**
	The following in the interface of commands that can be implemented in this project
*/
interface Command{
	
	int Execute(); /// Execute operation
	int Undo();	   /// Undo Operation
}

/**
	 The following is a class that implements the Command interface.
	 This class is used to change the color of a pixel in a surface.
	 The class is used to demonstrate the command pattern.
*/
class SurfaceOperation : Command{
	SDL_Surface* mSurface;
	int mXPosition;
	int mYPosition;
	byte red, green, blue;
	
	/// Constructor for the class
	this(SDL_Surface* surface, int xPos, int yPos, byte r, byte g, byte b){
		mSurface = surface;
		mXPosition = xPos;
		mYPosition = yPos;
		red = r;
		green = g;
		blue = b;
	}

	///	Deconstructor for the class
	~this(){

	}
	
	/// The following function is used to execute the command
	int Execute(){
		// When we modify pixels, we need to lock the surface first
		SDL_LockSurface(mSurface);
		// Make sure to unlock the mSurface when we are done.
		scope(exit) SDL_UnlockSurface(mSurface);

		// Retrieve the pixel arraay that we want to modify
		ubyte* pixelArray = cast(ubyte*)mSurface.pixels;
		// Change the 'blue' component of the pixels
		pixelArray[mYPosition*mSurface.pitch + mXPosition*mSurface.format.BytesPerPixel+0] = red;
			// Change the 'green' component of the pixels
		pixelArray[mYPosition*mSurface.pitch + mXPosition*mSurface.format.BytesPerPixel+1] = green;
			// Change the 'red' component of the pixels
		pixelArray[mYPosition*mSurface.pitch + mXPosition*mSurface.format.BytesPerPixel+2] = blue;

		return 0;
	}

	/** The following function is used to undo the command */
	int Undo(){
		// When we modify pixels, we need to lock the surface first
		SDL_LockSurface(mSurface);
		// Make sure to unlock the mSurface when we are done.
		scope(exit) SDL_UnlockSurface(mSurface);

		// Retrieve the pixel arraay that we want to modify
		ubyte* pixelArray = cast(ubyte*)mSurface.pixels;
		// Change the 'blue' component of the pixels
		pixelArray[mYPosition*mSurface.pitch + mXPosition*mSurface.format.BytesPerPixel+0] = 0;
			// Change the 'green' component of the pixels
		pixelArray[mYPosition*mSurface.pitch + mXPosition*mSurface.format.BytesPerPixel+1] = 0;
			// Change the 'red' component of the pixels
		pixelArray[mYPosition*mSurface.pitch + mXPosition*mSurface.format.BytesPerPixel+2] = 0;
		return 0;
	}
}