#include "testApp.h"
#include "ofxCocoa.h"

static int profileIndex = 0;
bool trans = false;
string settingsFile = "config.xml";
bool bDebug = false;

//--------------------------------------------------------------
testApp::testApp( string settings ){
    settingsFile = settings;
}

//--------------------------------------------------------------
void testApp::setup(){
    [MSA::ofxCocoa::glWindow() setCollectionBehavior:NSWindowCollectionBehaviorStationary|NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary];
    
    
    ofBackground( ofColor(0,0,0,0) );
	ofSetFrameRate(60);
    
    // screen
    mesh.addVertex(ofVec2f(0,0));
    mesh.addVertex(ofVec2f(ofGetScreenWidth(),0));
    mesh.addVertex(ofVec2f(ofGetScreenWidth(),ofGetScreenHeight()));
    mesh.addVertex(ofVec2f(0,ofGetScreenHeight()));
    cout << "adding vertices 0,0 " << ofGetScreenWidth() << ",0 " << ofGetScreenWidth() << "," << ofGetScreenHeight() << ", 0," << ofGetScreenHeight() << endl;
    
    ofxXmlSettings settings;
//    
    bool bLoaded = settings.loadFile(settingsFile);
    if ( bLoaded ){
        settings.pushTag("mask"); {
            type = settings.getValue("type", "quad");
            string production = settings.getValue("production", "false");
            if (production == "true"){
                // ignore all mouse events so other apps can get them
                [MSA::ofxCocoa::glWindow() setIgnoresMouseEvents:YES];
            }
            for (int i=0; i<settings.getNumTags("point"); i++){
                settings.pushTag("point", i); {
                    maskPoints.push_back(quadPoint());
                    maskPoints.back().set(settings.getValue("x", 100.0f),settings.getValue("y", 100.0f));
                } settings.popTag();
            }
        } settings.popTag();
    } else {
        type = "quad";
        maskPoints.push_back( quadPoint() );
        maskPoints.back().set(ofGetScreenWidth()/2,ofGetScreenHeight());
        maskPoints.push_back( quadPoint() );
        maskPoints.back().set(ofGetScreenWidth(),ofGetScreenHeight()/2);
        maskPoints.push_back( quadPoint() );
        maskPoints.back().set(ofGetScreenWidth()/2,ofGetScreenHeight()/2);
    }
    
    if (type=="ellipse"){
        setupEllipse();
    } else if (type=="curve"){
        setupCurve();
    } else {//type=="quad"
        setupQuad();
    }
    
    
    for (int i=0; i<mesh.getVertices().size(); i++){
        mesh.addColor(ofFloatColor(0,0,0));
    }
    
	// background	
    //bgDots.loadImage("./dotpattern.png");
}

void testApp::setupQuad(){
    maskPoints[0].vertexIndex = 4;
    maskPoints[1].vertexIndex = 5;
    maskPoints[2].vertexIndex = 6;
    maskPoints[3].vertexIndex = 7;
    
    // add points for quad mask
    
    mesh.addVertex(maskPoints[0]);
    mesh.addVertex(maskPoints[1]);
    mesh.addVertex(maskPoints[2]);
    mesh.addVertex(maskPoints[3]);
    
    mesh.addIndex(0); mesh.addIndex(4); mesh.addIndex(1);
    mesh.addIndex(1); mesh.addIndex(4); mesh.addIndex(5);
    mesh.addIndex(1); mesh.addIndex(2); mesh.addIndex(5);
    mesh.addIndex(2); mesh.addIndex(5); mesh.addIndex(6);
    mesh.addIndex(2); mesh.addIndex(3); mesh.addIndex(6);
    mesh.addIndex(3); mesh.addIndex(6); mesh.addIndex(7);
    mesh.addIndex(3); mesh.addIndex(0); mesh.addIndex(7);
    mesh.addIndex(0); mesh.addIndex(7); mesh.addIndex(4);
}

void testApp::setupEllipse(){
    int linkTo = 0;
    bool first = true;
    int currIndex = 4;
    bool incrementLinkTo = false;
    double x,y;
    double xOffset = maskPoints[2].x;
    double yOffset = maskPoints[2].y;
    int width = maskPoints[1].x - maskPoints[2].x;
    int height = maskPoints[0].y - maskPoints[2].y;
    for(double i = 0; i < PI*2; i+=.1){
        y=-sin(i)*height+yOffset;
        x=-cos(i)*width+xOffset;
        mesh.addVertex(ofVec2f(x, y));
        if (!first){
            mesh.addIndex(linkTo);
            mesh.addIndex(currIndex - 1);
            mesh.addIndex(currIndex);
            if (linkTo == 0 && -cos(i) > 0){
                incrementLinkTo = true;
            } else if (linkTo == 1 && -sin(i) > 0){
                incrementLinkTo = true;
            } else if (linkTo == 2 && -cos(i) < 0){
                incrementLinkTo = true;
            }
            if (incrementLinkTo){
                mesh.addIndex(linkTo);
                mesh.addIndex(currIndex);
                linkTo = (linkTo + 1) % 4;
                mesh.addIndex(linkTo);
                incrementLinkTo = false;
            }
        }
        currIndex++;
        first=false;
    }
    mesh.addIndex(linkTo);
    mesh.addIndex(currIndex - 1);
    mesh.addIndex(4);
    mesh.addIndex(linkTo);
    mesh.addIndex(4);
    mesh.addIndex(0);
}

void testApp::updateEllipse(){
    //re-generate positions for all points
    int currIndex = 4;
    double x,y;
    double xOffset = maskPoints[2].x;
    double yOffset = maskPoints[2].y;
    int width = maskPoints[1].x - maskPoints[2].x;
    int height = maskPoints[0].y - maskPoints[2].y;
    for(double i = 0; i < PI*2; i+=.1){
        y=-sin(i)*height+yOffset;
        x=-cos(i)*width+xOffset;
        mesh.setVertex(currIndex, ofVec2f(x, y));
        currIndex++;
    }
}

void testApp::setupCurve(){
    int linkTo = 0;
    int stepNumber = 1;
    bool first = true;
    int currIndex = 4;
    bool incrementLinkTo = false;
    double x,y;
    int xOffset, xDiff, yOffset, yDiff;
    //part a,   cos(0) = 1 -> maskPoints[0].x
    //          sin(0) = 0 -> maskPoints[0].y
    //          cos(PI/2) = 0 -> maskPoints[1].x
    //          sin(PI/2) = 1 -> maskPoints[1].y
    //part b,   cos(PI) = -1 -> maskPoints[2].x
    //          sin(PI) = 0 -> maskPoints[2].y
    //part c,   cos(3PI/4) = 0 -> maskPoints[3].x
    //          sin(3PI/4) = -1 -> maskPoints[3].y
    //part d,   cos(2PI) = 1 -> maskPoints[0].x
    //          sin(2PI) = 0 -> maskPoints[0].y
    for(double i = 0; i < PI*2; i+=.1){
        switch (stepNumber){
            case 1:
                if (i < PI/2.0){
                    xDiff = maskPoints[1].x - maskPoints[0].x;//we assume 0 is to the left of 1
                    xOffset = maskPoints[1].x;
                    yDiff = maskPoints[0].y - maskPoints[1].y;//we assume 0 is below 1
                    yOffset = maskPoints[0].y;
                    break;
                } else {
                    stepNumber++;
                    //we want to fall through
                }
            case 2:
                if (i < PI){
                    xDiff = maskPoints[2].x - maskPoints[1].x;//we assume 1 is left of 2
                    xOffset = maskPoints[1].x;
                    yDiff = maskPoints[2].y - maskPoints[1].y;//we assume 2 is below 1
                    yOffset = maskPoints[2].y;
                    break;
                } else {
                    stepNumber++;
                    //we want to fall through
                }
            case 3:
                if (i < 3.0*PI/2.0){
                    xDiff = maskPoints[2].x - maskPoints[3].x;//we assume 3 is left of 2
                    xOffset = maskPoints[3].x;
                    yDiff = maskPoints[3].y - maskPoints[2].y;//we assume 3 is below 2
                    yOffset = maskPoints[2].y;
                    break;
                } else {
                    stepNumber++;
                    //we want to fall through
                }
            default:
                xDiff = maskPoints[3].x - maskPoints[0].x;//we assume 0 is left of 3
                xOffset = maskPoints[3].x;
                yDiff = maskPoints[3].y - maskPoints[0].y;//we assume 3 is below 0
                yOffset = maskPoints[0].y;
                break;
        }
        x = xOffset - cos(i) * xDiff;
        y = yOffset - sin(i) * yDiff;
        mesh.addVertex(ofVec2f(x, y));
        if (!first){
            mesh.addIndex(linkTo);
            mesh.addIndex(currIndex - 1);
            mesh.addIndex(currIndex);
            if (linkTo == 0 && -cos(i) > 0){
                incrementLinkTo = true;
            } else if (linkTo == 1 && -sin(i) > 0){
                incrementLinkTo = true;
            } else if (linkTo == 2 && -cos(i) < 0){
                incrementLinkTo = true;
            }
            if (incrementLinkTo){
                mesh.addIndex(linkTo);
                mesh.addIndex(currIndex);
                linkTo = (linkTo + 1) % 4;
                mesh.addIndex(linkTo);
                incrementLinkTo = false;
            }
        }
        currIndex++;
        first=false;
    }
    mesh.addIndex(linkTo);
    mesh.addIndex(currIndex - 1);
    mesh.addIndex(4);
    mesh.addIndex(linkTo);
    mesh.addIndex(4);
    mesh.addIndex(0);
}

void testApp::updateCurveForPoint(int index){
    int stepNumber = 1;
    int currIndex = 3;
    double x,y;
    int xOffset, xDiff, yOffset, yDiff;
    //part a,   cos(0) = 1 -> maskPoints[0].x
    //          sin(0) = 0 -> maskPoints[0].y
    //          cos(PI/2) = 0 -> maskPoints[1].x
    //          sin(PI/2) = 1 -> maskPoints[1].y
    //part b,   cos(PI) = -1 -> maskPoints[2].x
    //          sin(PI) = 0 -> maskPoints[2].y
    //part c,   cos(3PI/4) = 0 -> maskPoints[3].x
    //          sin(3PI/4) = -1 -> maskPoints[3].y
    //part d,   cos(2PI) = 1 -> maskPoints[0].x
    //          sin(2PI) = 0 -> maskPoints[0].y
    for(double i = 0; i < PI*2; i+=.1){
        currIndex++;
        switch (stepNumber){
            case 1:
                if (i < PI/2.0){
                    if (index != 0 && index != 1){
                        continue;
                    }
                    xDiff = maskPoints[1].x - maskPoints[0].x;//we assume 0 is to the left of 1
                    xOffset = maskPoints[1].x;
                    yDiff = maskPoints[0].y - maskPoints[1].y;//we assume 0 is below 1
                    yOffset = maskPoints[0].y;
                    break;
                } else {
                    stepNumber++;
                    //we want to fall through
                }
            case 2:
                if (i < PI){
                    if (index != 1 && index != 2){
                        continue;
                    }
                    xDiff = maskPoints[2].x - maskPoints[1].x;//we assume 1 is left of 2
                    xOffset = maskPoints[1].x;
                    yDiff = maskPoints[2].y - maskPoints[1].y;//we assume 2 is below 1
                    yOffset = maskPoints[2].y;
                    break;
                } else {
                    stepNumber++;
                    //we want to fall through
                }
            case 3:
                if (i < 3.0*PI/2.0){
                    if (index != 2 && index != 3){
                        continue;
                    }
                    xDiff = maskPoints[2].x - maskPoints[3].x;//we assume 3 is left of 2
                    xOffset = maskPoints[3].x;
                    yDiff = maskPoints[3].y - maskPoints[2].y;//we assume 3 is below 2
                    yOffset = maskPoints[2].y;
                    break;
                } else {
                    stepNumber++;
                    //we want to fall through
                }
            default:
                if (index != 3 && index != 0){
                    continue;
                }
                xDiff = maskPoints[3].x - maskPoints[0].x;//we assume 0 is left of 3
                xOffset = maskPoints[3].x;
                yDiff = maskPoints[3].y - maskPoints[0].y;//we assume 3 is below 0
                yOffset = maskPoints[0].y;
                break;
        }
        x = xOffset - cos(i) * xDiff;
        y = yOffset - sin(i) * yDiff;
        mesh.setVertex(currIndex, ofVec2f(x, y));
        cout << "updated vertex in stepNumber " << stepNumber << endl;
    }
}

//--------------------------------------------------------------
void testApp::exit(){
}

//--------------------------------------------------------------
void testApp::update(){
}

//--------------------------------------------------------------
void testApp::draw(){
    mesh.draw();
    if ( bDebug ){
        ofSetRectMode(OF_RECTMODE_CENTER);
        ofSetColor(255,0,0);
        for (int i=0; i<maskPoints.size(); i++){
            ofRect(maskPoints[i].x, maskPoints[i].y, 10, 10);
        }
        ofSetColor(255);
        ofSetRectMode(OF_RECTMODE_CORNER);
    }
}

//--------------------------------------------------------------
void testApp::keyPressed(int key){
    if ( key == 'd' ){
        bDebug = !bDebug;
    }
}

//--------------------------------------------------------------
void testApp::keyReleased(int key){	
}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y ){
}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){
    for ( int i=0; i<maskPoints.size(); i++){
        if ( maskPoints[i].bPressed ){
            if (type == "ellipse") {
                if (i == 0){
                    maskPoints[0].y = y;
                } else if (i == 1){
                    maskPoints[1].x = x;
                } else if (i == 2){
                    int changeX = maskPoints[2].x - x;
                    int changeY = maskPoints[2].y - y;
                    maskPoints[2].x = x;
                    maskPoints[2].y = y;
                    maskPoints[0].x = x;
                    maskPoints[1].y = y;
                    maskPoints[0].y -= changeY;
                    maskPoints[1].x -= changeX;
                } else {
                    maskPoints[i].x = x;
                    maskPoints[i].y = y;
                }
                updateEllipse();
            } else if (type == "curve"){
                maskPoints[i].x = x;
                maskPoints[i].y = y;
                updateCurveForPoint(i);
            } else {//type == "quad"
                maskPoints[i].x = x;
                maskPoints[i].y = y;
                mesh.setVertex(maskPoints[i].vertexIndex, maskPoints[i]);
            }
        }
    }
}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){
    for ( int i=0; i<maskPoints.size(); i++){
        if ( maskPoints[i].hitTest(x, y) ){
            maskPoints[i].bPressed = true;
            break;
        }
    }
}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){
    bool bNeedToSave = false;
    
    for ( int i=0; i<maskPoints.size(); i++){
        if (maskPoints[i].bPressed) bNeedToSave = true;
        maskPoints[i].bPressed = false;
    }
    if ( bNeedToSave ){
        ofxXmlSettings settings;
        settings.addTag("mask");
        settings.pushTag("mask"); {
            settings.addValue("type", type);
            for (int i=0; i<maskPoints.size(); i++){
                settings.addTag("point");
                settings.pushTag("point", i); {
                    settings.addValue("x", maskPoints[i].x);
                    settings.addValue("y", maskPoints[i].y);
                } settings.popTag();
            }
        } settings.popTag();
        settings.saveFile(settingsFile);
    }
}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){
	
}