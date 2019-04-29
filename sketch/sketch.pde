boolean recording = true;
float speed = 10;
String inputFile = "../trip_table.csv";
String minDateTimeString = "2019-04-22 03:00:00";
String maxDateTimeString = "2019-04-24 19:10:00";

// Import Unfolding Maps
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.core.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.events.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.interactions.*;
import de.fhpotsdam.unfolding.mapdisplay.*;
import de.fhpotsdam.unfolding.mapdisplay.shaders.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.texture.*;
import de.fhpotsdam.unfolding.tiles.*;
import de.fhpotsdam.unfolding.ui.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.utils.*;

// Import Java utilities
import java.util.Date;
import java.text.SimpleDateFormat;

// Declare Global Variables
float t;
UnfoldingMap map;
DebugDisplay debugDisplay;
Table tripTable;
ArrayList<Trip> trips = new ArrayList<Trip>();
ScreenPosition startPos;
ScreenPosition endPos;
Location startLoc;
Location endLoc;
Location mapCenter;
float firstLat;
float firstLon;
float minTime;
float maxTime;
float totalSeconds;
float totalFrames;
int zoom;
color c;
SimpleDateFormat myDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
Date minDateTime;
Date maxDateTime;
PImage clock;
PImage calendar;
PImage basemap;
PFont raleway;
PFont ralewayBold;

void setup() {
  size(1600, 1000, P3D);
  pixelDensity(2);
  smooth();
  try {
    minDateTime = myDateFormat.parse(minDateTimeString);
    maxDateTime = myDateFormat.parse(maxDateTimeString);
  }
  catch (Exception e) {
    print(e);
  }
  loadData();
  //map = new UnfoldingMap(this, new StamenMapProvider.TonerBackground());
  map = new UnfoldingMap(this, new EsriProvider.WorldStreetMap());
  MapUtils.createDefaultEventDispatcher(this, map);
  
  // Toronto regional zoom:
  mapCenter = new Location(43.725,-79.458);
  zoom = 9;
  
  // Toronto urban zoom:
  // mapCenter = new Location(43.704,-79.413);
  // zoom = 11;
  
  map.zoomAndPanTo(zoom, mapCenter);
  debugDisplay = new DebugDisplay(this, map, 10, 200);
  clock = loadImage("clock_icon.png");
  clock.resize(0, 35);
  calendar = loadImage("calendar_icon.png");
  calendar.resize(0, 35);
  raleway  = createFont("Raleway-Heavy", 32);
  ralewayBold  = createFont("Raleway-Bold", 28);
  //basemap = loadImage("basemap.tiff");
}

void draw() {
  map.draw();
  //debugDisplay.draw();
  //image(basemap,0,0,width,height);
  noStroke();
  fill(0,140);
  rect(0,0,width,height);
  
  // Plot trips
  for (int i=0; i < trips.size(); i++) {
    Trip trip = trips.get(i);
    trip.plot();
  }

  textFont(ralewayBold, 32);
  
  push();
  translate(-120,40);
  //translate(820,740);
  textSize(20);
  fill(0, 173, 253,220);
  rect(144,146,60, 30,8);
  fill(255);
  text("Bus", 148, 168);
  
  fill(255, 215, 0,220);
  rect(214,146,66, 30,8);
  fill(0);
  text("Train", 218, 168);
  
  fill(255,0, 0,220);
  rect(288,146,85, 30,8);
  fill(255);
  text("Subway", 292, 168);
  
  fill(124, 252, 0,220);
  rect(382,146,100, 30,8);
  fill(0);
  text("Light Rail", 386, 168);
  
  // No GTFS for ferries available
  //fill(255, 105, 180,220);
  //rect(492,146,60, 30,8);
  //fill(255);
  //text("Ferry", 496, 168);
  
  fill(0,200);
  rect(144, 14, 520, 120, 8);
  fill(255);
  textSize(36);
  text("Toronto Regional\nTransit Flows", 345, 60);
  textSize(20);
  text("Visualizaton by Will Geary @wgeary", 148, 210);

  // Calculate current time
  float epoch_float = map(t, minTime, maxTime, minDateTime.getTime()/1000L, maxDateTime.getTime()/1000L);
  int epoch = int(epoch_float);
  String time = new java.text.SimpleDateFormat("h:mm a").format(new java.util.Date(epoch * 1000L));
  String day = new java.text.SimpleDateFormat("EEEE").format(new java.util.Date(epoch * 1000L));
  fill(255, 255, 255, 255);
  image(clock, 160, 25);
  stroke(255, 255, 255, 255);
  line(160, 70, 330, 70);
  image(calendar, 160, 80 );
  textSize(28);
  text(time, 205, 55);
  textSize(22);
  text(day, 205, 108);
  pop();
  
  
  
  
  t += speed;
  
  if (recording) {
    saveFrame("frames/######.png");
  }
}

void loadData() {
  tripTable = loadTable(inputFile, "header");
  println(str(tripTable.getRowCount()) + " records loaded...");
  minTime = tripTable.getFloat(0, "start_time");
  maxTime = tripTable.getFloat(tripTable.getRowCount()-1, "end_time");
  t = minTime;
  totalSeconds = maxTime - minTime;
  totalFrames = totalSeconds / speed;
  println("min time: ", minTime);
  println("max time: ", maxTime);
  firstLat = tripTable.getFloat(0, "start_lat");
  firstLon = tripTable.getFloat(0, "start_lon");
  
  for (TableRow row : tripTable.rows()) {
    float startTime = row.getFloat("start_time");
    float endTime = row.getFloat("end_time");
    float startLat = row.getFloat("start_lat");
    float startLon = row.getFloat("start_lon");
    float endLat = row.getFloat("end_lat");
    float endLon = row.getFloat("end_lon");
    float bearing = row.getFloat("bearing");
    String mode = row.getString("mode");
    Location startLoc = new Location(startLat, startLon);
    Location endLoc = new Location(endLat, endLon);
    trips.add(new Trip(startTime, endTime, startLoc, endLoc, bearing, mode));
  }
}

class Trip {
  float startTime, endTime, duration, bearing;
  Location startLoc, endLoc, currentLoc;
  ScreenPosition currentPos;
  String mode;
  boolean alive = false;
  float busSize = 3;
  float subwaySize = 4;
  float railSize = 5;
  float xscale = 1.8;
  float yscale = 0.8;
  float alpha = 220;
  
  Trip(float _startTime, float _endTime, Location _startLoc, Location _endLoc, float _bearing, String _mode) {
    startTime = _startTime;
    endTime = _endTime;
    duration = endTime - startTime;
    startLoc = _startLoc;
    endLoc = _endLoc;
    bearing = radians(_bearing);
    mode = _mode;
  }
  
  void plot() {
    switch(mode) {
      case "Bus":
        plotBus();
        break;
      case "Subway":
        plotSubway();
        break;
      case "Rail":
        plotRail();
        break;
      case "Light rail":
        plotLightRail();
        break;
      case "Ferry":
        plotFerry();
        break;
      case "Cable car":
        plotCableCar();
        break;
      case "Gondola":
        plotGondola();
        break;
      case "Funicular":
        plotFunicular();
        break;
    }
  }
  
  void plotTrip() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      ellipse(currentPos.x, currentPos.y, busSize, busSize);
    }
  }
  
  void plotBus() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(0, 173, 253, alpha);
        rect(0, 0, busSize*xscale, busSize*yscale, 7);
      pop();
    }
  }
  
  void plotSubway() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(255, 0, 0, alpha-20);
        rect(0, 0, subwaySize*xscale, subwaySize*yscale, 7);
      pop();
    }
  }
  
  void plotRail() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(255, 215, 0, alpha);
        rect(0, 0, railSize*xscale, railSize*yscale, 7);
      pop();
    }
  }
  
  void plotLightRail() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(124, 252, 0, alpha);
        rect(0, 0, subwaySize*xscale, subwaySize*yscale, 7);
      pop();
    }
  }
  
  void plotFerry() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(255, 105, 180, alpha);
        rect(0, 0, subwaySize*xscale, subwaySize*yscale, 7);
      pop();
    }
  }
  
  void plotCableCar() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(255,140,0, alpha);
        rect(0, 0, subwaySize*xscale, subwaySize*yscale, 7);
      pop();
    }
  }
  
  void plotGondola() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(255, 127, 80, alpha);
        rect(0, 0, busSize*xscale, busSize*yscale, 7);
      pop();
    }
  }
  
  void plotFunicular() {
    if (t >= startTime && t <= endTime) {
      float pctTravelled = (t - startTime) / duration;
      currentLoc = new Location (
        lerp(startLoc.x, endLoc.x, pctTravelled),
        lerp(startLoc.y, endLoc.y, pctTravelled)
      );
      currentPos = map.getScreenPosition(currentLoc);
      push();
        translate(currentPos.x, currentPos.y);
        rotate(bearing + PI/2);
        rectMode(CENTER);
        fill(0, 173, 253, alpha);
        rect(0, 0, busSize*xscale, busSize*yscale, 7);
      pop();
    }
  }
}

void push() {
  pushMatrix();
  pushStyle();
}

void pop() {
  popStyle();
  popMatrix();
}