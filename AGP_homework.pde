/**
 * @author Nils Gawlik
 * @date 2017-10-25
 * @matrikelnummer 553449
 */
 

// -- physical utility constants --
final float km = 1000; // kilometer, in m
final float h = 3600; // hour, in s
final float kmH = 1 / 3.6; // kilometers per hour, in m/s

// -- other constants --
// world constants
final float gravityX = 0.0; // in m/s
final float gravityY = -9.81; // in m/s

// origin of world on screen
final float xOrigin = 500; // in px
final float yOrigin = 700; // in px

final float baseWorldHeight = 200 * km; // in m, height of the displayed world
final float markerHeight = 30 * km; // in m, height of horizontal marker line
final float baseTimeScale = 1.0; // in s/s, time scale

// comet
final float initialImpactAngle = radians(170); // initial comet impact angle relative to x axis, in radians
final float initialVelocity = 32000 * kmH; // initial comet velocity, in m/s

// Parent class for physics objects
abstract class GameObject {
  float x;
  float y;
  // verlocity in m/s:
  float vX;
  float vY;

  GameObject(float x, float y) {
     this.x = x;
     this.y = y;
     vX = 0;
     vY = 0;
  }
  
  void move(float deltaTime) {
    // update position accounting for velocity and gravity
    x += vX * deltaTime + 0.5 * gravityX * pow(deltaTime, 2);
    y += vY * deltaTime + 0.5 * gravityY * pow(deltaTime, 2);

    // update and remember velocity for next iteration
    vX += gravityX * deltaTime;
    vY += gravityY * deltaTime;
  }

  void draw() {
    // do nothing
  }
}

// class that models and draws the comet
class Comet extends GameObject{
  float radius = 20*100; // 20 m, 100x scale
  
  Comet(float x, float y, float impactAngle, float velocity) {
    super(x, y);
    vX = -cos(impactAngle) * velocity; // calculated initial velocity vector
    vY = -sin(impactAngle) * velocity;
  }

  // move the comet, deltaTime = time passed since last update, in s
  void move(float deltaTime) {
    // handle movement in parent object
    super.move(deltaTime);
    // handle collision with ground
    if (y < radius) {
      y = radius;
      vX = 0;
      vY = 0;
    }
  }
  
  void draw() {
    // draw circle
    fill(255);
    ellipse(x, y, radius*2, radius*2);
    // draw impact arc (simplified: line)
    float distanceTillImpact = vX/vY * -y; // helper variable
    stroke(255);
    strokeWeight(200);
    line(x, y, x + distanceTillImpact, 0);
    
    // draw velocity vector
    stroke(255);
    strokeWeight(400);
    line(x, y, x + vX, y + vY);
  }
}

// class that draws the floor and other environmental things
class Floor {
  float thickness; // thickness of the floor
  float markerHeight; // height of the marking line (height at which the comet should be shot)
  
  Floor(float thickness, float markerHeight) {
    this.thickness = thickness;
    this.markerHeight = markerHeight;
  }
  
  void draw() {
   // draw ground
   fill(0);
   strokeWeight(0);
   rect(worldBorderLeft, -thickness, worldWidth, thickness);
   
   // draw marker line
   fill(0);
   strokeWeight(100);
   line(worldBorderLeft, markerHeight, worldWidth, markerHeight);
  }
}

abstract class Button {
  boolean isDown = false;

  int state = 0; // 0 = red, 1 = green
  int numberOfStates = 2;

  PImage[] images; // images for the states, alternating eween up and down position
  String[] texts;
  float downOffset; // offset when the button is down

  float textOffsetY; // normal offset

  float x;
  float y;

  Button(float x, float y, PImage[] images, String[] texts, float textOffsetY, float downOffset) {
    this.x = x;
    this.y = y;
    this.images = images;
    this.texts = texts;
    this.textOffsetY = textOffsetY;
    this.downOffset = downOffset;
  }

  void mousePressed() {
    if (checkBounds()) {
      isDown = true;
    }
  }

  void mouseReleased() {
    if (isDown) {
      isDown = false;
      performAction(state);
      increaseState();
    }
  }

  protected void performAction(int currentState) {
    // do nothing
  }

  private void increaseState() {
    // update state
    state = (state + 1) % 2; // increase state
  }

  void draw() {
    imageMode(CENTER);
    image(currentImage(), x, y);
    if (texts != null && state < texts.length) {
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(33);
      text(texts[state], x, y + textOffsetY + (isDown? downOffset : 0));
    }
  }

  PImage currentImage() {
    return isDown? images[state * 2 + 1] : images[state * 2]; // pick odd images for down, even for up
  }

  boolean checkBounds() {
    return mouseX >= x - currentImage().width/2 && mouseX < x + currentImage().width/2
    && mouseY >= y - currentImage().height/2 && mouseY < y + currentImage().height/2;
  }
}

// button responsible for start and reset
class StartButton extends Button {
  StartButton() {
    super(
      120, 70, // x, y
      new PImage[] {buttonGreenUp, buttonGreenDown, buttonRedUp, buttonRedDown}, // images
      new String[] {"Start", "Reset"}, // label
      -12, 8 // offset of text when normal and pressed
      );
  }

  void performAction(int currentState) {
    // do certain things based on state
    switch (state) {
      case 0: // start
        timeScale = baseTimeScale;
      break;
      case 1: // reset
        teardownDynamic();
        setupDynamic();
      break;
    }
  }
}

// class that models and draws a rocket
class Rocket extends GameObject {
  float h = 100*100; // rocket height (100x scale)
  float w = 20*100; // rocket width (100x scale)
  float cap = 20*100; // height of cap (100x scale)
  
  Rocket(float x, float y) {
    super(x, y);
  }

  void move(float deltaTime) {
    // handle movement in parent object
    super.move(deltaTime);
    // handle collision with ground
    if (y < h/2) {
      y = h/2;
      vX = 0;
      vY = 0;
    }
  }

  void draw() {
    pushMatrix();

    translate(x, y); // translation to simplify calculations below
    // calculate and draw the rocket parts
    strokeWeight(0);
    fill(0);
    rect(-w/2, -h/2, w, h - cap);
    fill(0);
    triangle(-w/2, -h/2 + h - cap, w/2, -h/2 + h - cap, 0, h/2);
    
    popMatrix();
  }
}

// images
PImage backgroundImage;
PImage buttonGreenUp;
PImage buttonGreenDown;
PImage buttonRedUp;
PImage buttonRedDown;

// world
float worldWidth; // width of world, in m
float worldHeight; // height of world, in m
float worldScale; // scale of world, in px/m
float timeScale; // time scale, in s/s
float worldBorderLeft; // distance from origin to left border, in m
float worldBorderRight; // distance from origin to right border, in m

Comet comet;
Floor floor;
Rocket rocket;
Button button;

void setup() {
  // display
  size(1000, 800);
  frameRate(60);
  
  // dimensions
  float screenRatio = (float)(width) / (float)height;
   
  worldHeight = baseWorldHeight;
  worldWidth = worldHeight * screenRatio;

  worldScale = (float) width / worldWidth;
  timeScale = 0; // no prograssion at start, activated by start button

  worldBorderLeft = -xOrigin / worldScale;
  worldBorderRight = -xOrigin / worldScale + worldWidth;
  
  // load images
  buttonGreenUp = loadImage("b_green_up.png");
  buttonGreenDown = loadImage("b_green_down.png");
  buttonRedUp = loadImage("b_red_up.png");
  buttonRedDown = loadImage("b_red_down.png");
  
  // generate image for background
  color c1 = #FAD723;
  color c2= #4D221F;
  backgroundImage = createImage(width, height, RGB);
  backgroundImage.loadPixels();

  for (int i = 0; i < backgroundImage.pixels.length; i++) {
    float amount = (float) i / backgroundImage.pixels.length;
    backgroundImage.pixels[i] = lerpColor(c1, c2, amount);; // TODO use realistic colors to represent the athmosphere (and scale correctly)
  }
  backgroundImage.updatePixels();
  
  // initialize objects
  setupDynamic();
  floor = new Floor(yOrigin / worldScale, markerHeight);

  button = new StartButton();
}

// set up dynamic objects
void setupDynamic() {
  comet = new Comet(-120*km, 40*km, initialImpactAngle, initialVelocity);
  rocket = new Rocket(0*km, 0*km);
}

// tear down dynamic objects (for reset)
void teardownDynamic() {
  comet = null;
  rocket = null;
  timeScale = 0;
}

// called every frame before drawing
void update() {
  float deltaTime = timeScale * 1.0 / frameRate;
  comet.move(deltaTime);
  rocket.move(deltaTime);
}

void mouseReleased() {
  button.mouseReleased();
}

void mousePressed() {
  button.mousePressed();
}
 
void draw() {
  update();

  background(backgroundImage);
  
  // add a transform from world space to screen space
  translate(0, height); // offset because of upcoming scale
  scale(worldScale, -worldScale); // scale and flip in y direction
  translate(xOrigin / worldScale, (height - yOrigin) / worldScale);  // move origin to correct position

  comet.draw();
  floor.draw(); 
  rocket.draw();
  
  // UI
  resetMatrix(); // reset back to screen space for UI
  
  button.draw();
}