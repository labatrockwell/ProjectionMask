#include "ofMain.h"
#include "testApp.h"

#include "ofxCocoa.h"
#include <Cocoa/Cocoa.h>

//========================================================================
int main( int argc, char * const argv[] )
{
    
	// SETUP COCOA WINDOW
	
	MSA::ofxCocoa::InitSettings			initSettings;
	initSettings.isOpaque				= false;
	initSettings.windowLevel			= NSScreenSaverWindowLevel;
	initSettings.hasWindowShadow		= false;
	initSettings.numFSAASamples			= 4;
    
    // change these vars to adjust the width and height
	initSettings.initRect.size.width	= 960;
	initSettings.initRect.size.height	= 540;
    
    //leave these unless you don't want it centered
    // might have to change it to something other than rectForAllScreens() if there is > 1 screen (e.g. with a KVM?)
    initSettings.initRect.origin.x      = MSA::ofxCocoa::rectForAllScreens().size.width / 2.0f - initSettings.initRect.size.width/2.0f;
    initSettings.initRect.origin.y      = MSA::ofxCocoa::rectForAllScreens().size.height / 2.0f - initSettings.initRect.size.height/2.0f;
	initSettings.windowMode				= OF_WINDOW;
	initSettings.windowStyle			= NSBorderlessWindowMask;
	initSettings.initRect				= MSA::ofxCocoa::rectForAllScreens();
	
	MSA::ofxCocoa::AppWindow		cocoaWindow(initSettings);
    
	ofSetupOpenGL(&cocoaWindow, 0, 0, 0);		// all other parameters are ignored, use initSettings above
	
    // command line args
    string  settings = "config.xml";
    int c;
    
    opterr = 0;
    
    while ((c = getopt (argc, argv, "x:")) != -1){
        fprintf (stderr, "Option -%c %s.\n", optopt, optarg);
        switch (c){
            case 'x':                      
                settings = optarg;
                break;
            case '?':
                if (optopt == 'p' || optopt == 'h')
                    fprintf (stderr, "Option -%c requires an argument.\n", optopt);
                else if (isprint (optopt))
                    fprintf (stderr, "Unknown option `-%c'.\n", optopt);
                else
                    fprintf (stderr,
                             "Unknown option character `\\x%x'.\n",
                             optopt);
                break;
        }
    }

    
	
    // START TEST APP
	
	testApp* app = new testApp(settings);
	ofRunApp( app );
}
