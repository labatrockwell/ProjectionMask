#ifndef _TEST_APP
#define _TEST_APP

/****************************************************
	OF + ADDONS
****************************************************/

#include "ofMain.h"
#include "ofxXmlSettings.h"

/****************************************************
	TESTAPP
****************************************************/

class quadPoint : public ofVec2f {
public:
    bool    bPressed;
    int     hitTolerance;
    int     vertexIndex;
    
    quadPoint(){
        bPressed = false;
        hitTolerance = 10;
        vertexIndex  = 0;
    }
    
    bool hitTest( int _x, int _y ){
        if ( _x > (x - hitTolerance) && _x < x + hitTolerance
            && _y > (y - hitTolerance) && _y < y + hitTolerance){
            return true;
        }
        return false;
    }
};

class testApp : public ofBaseApp{

public:    
    testApp( string settings );
    void exit();
    
	void setup();
	void update();
	void draw();
	
	void keyPressed  (int key);
	void keyReleased(int key);
	void mouseMoved(int x, int y );
	void mouseDragged(int x, int y, int button);
	void mousePressed(int x, int y, int button);
	void mouseReleased(int x, int y, int button);
	void windowResized(int w, int h);
    
    ofMesh mesh;
    vector<quadPoint>   maskPoints;
    string type;
    
private:
    void setupQuad();
    void setupEllipse();
    void setupCurve();
    void updateCurveForPoint(int i);
    void updateEllipse();
};

#endif
