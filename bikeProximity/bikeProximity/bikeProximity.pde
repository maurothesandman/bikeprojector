// Car Proximity Detection
// Output video if car too close
// Code for serial started from https://github.com/Illutron/AdvancedTouchSensing

import processing.serial.*;
import cc.arduino.*;
import processing.video.*;
import ddf.minim.*;

/*   =================================================================================       
 Constants
 =================================================================================*/

boolean DEBUG = true;
int SENSOR_MAX = 100;
int SELECTED_CAMERA = 0;
int SERIAL_PORT_NUMBER=2;
int PORT_SELECTED=0;
int AUDIO_BUF_SIZE = 512;
int SENSER_THRESHOLD = 100;

float EASING = 0.15;


int numReadings = 20;
int[] readingsA = new int[numReadings];     // the readings from the analog input
int indexA = 0;                  // the index of the current reading
int totalA = 0;                  // the running total
int averageA = 0;                // the averageA

/*   =================================================================================       
 Global variables
 =================================================================================*/

Arduino arduino;
Serial arduinoPort;
Capture camera;
Minim minim;
AudioPlayer dangerSiren, warningBeep;
AudioInput input;
int sensorData = 0;
float arcValue = 0;


/*   =================================================================================       
 Setup
 =================================================================================*/

void setup(){
  size(960,720);
  
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600);

//  serialPortSetup();
  cameraSetup();
  audioSetup();

  dangerSiren.play();
  warningBeep.play();
  dangerSiren.loop();
  warningBeep.loop();

}

/*   =================================================================================       
 Draw
 =================================================================================*/

void draw() {
  // Arduino interface and smoothing
  int sensorRaw = arduino.analogRead(0);
  sensorData = averaged(sensorRaw);
  
  
  // Draw a black background on top of everything every frame. Acts as a clean slate
  background(0);


  // camera
  if (camera.available() == true) {
    camera.read();
  }

  image(camera, 0, 0);

  // distance based response
  
  if ( objectDanger(sensorData) ) {
    println("Object danger");
    
    //dangerResponse();
    dangerSiren.unmute();
    warningBeep.mute();

  } else if ( objectCaution(sensorData) ) {
    println("Object caution");
    
    //cautionResponse();
    dangerSiren.mute();
    warningBeep.unmute();
    
  } else if ( objectDetected(sensorData) ) {
    println("Object detected");
    
    //detectionResponse();
    dangerSiren.mute();
    warningBeep.mute();

  } else {
    println("Object NOT detected");
    
    // regularResponse();
    dangerSiren.mute();
    warningBeep.mute();
    
  }

// Proximity visualization
pushStyle();
pushMatrix();
  arcValue += ((float)sensorData-arcValue) * EASING;
  float arcSize = map(arcValue, 0, SENSOR_MAX, 180, 0);
  ellipseMode(CENTER);
  noFill();
  color from = color(0,255,0);
  color to = color(255,0,0);
  color strokeColor = lerpColor(from,to,map(arcSize,0, 180, 0,1));
  stroke(strokeColor);
  strokeWeight(20);
  strokeCap(SQUARE);
  translate(width/2, height/2);
  arc(0,0,700,700, PI*.75-radians(arcSize), PI*.75+radians(arcSize));
popMatrix();
popStyle();

  if (DEBUG) {
    print( "#### Sensor Data" );
    print( ", " + Integer.toString(sensorRaw) );
    print(", " + "Averaged Data: " + Integer.toString(sensorData));
    println();
  }
}


/*   =================================================================================       
 Sensor
 =================================================================================*/

boolean objectDetected( int data ) { 
  return data < SENSOR_MAX;
}

boolean objectCaution( int data ) { 
  return data < (SENSOR_MAX/2);
}

boolean objectDanger( int data ) { 
  return data < (SENSOR_MAX/6);
}

/*   =================================================================================       
 Camera
 =================================================================================*/

void cameraSetup() {

  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      print(Integer.toString(i) + "\t");
      println(cameras[i]);
    }
  } 

  camera = new Capture(this, cameras[SELECTED_CAMERA]);
  camera.start();   
}

/*   =================================================================================       
 Audio
 =================================================================================*/


void audioSetup() {
  minim = new Minim(this);
  dangerSiren = minim.loadFile("siren.mp3");
  warningBeep = minim.loadFile("beep.mp3");

  if ( dangerSiren == null || warningBeep == null ) println("Didn't get audio");
}

void keyPressed() {
  if (key == '+') {
    sensorData += 25;
  } else if (key == '-') {
    sensorData -= 25;
  }
  
}

/*   =================================================================================       
 Averaging
 =================================================================================*/
int averaged(int data){

  
  // subtract the last reading:
    totalA = totalA - readingsA[indexA];         
    // read from the sensor:  
    readingsA[indexA] = data;
    // add the reading to the total:
    totalA = totalA + readingsA[indexA];       
    // advance to the next position in the array:  
    indexA = indexA + 1;                    

    // if we're at the end of the array...
    if (indexA >= numReadings) 
    {
        // ...wrap around to the beginning: 
        indexA = 0;                           
    }

    // calculate the average:
    averageA = totalA / numReadings;  
    return averageA;
}

