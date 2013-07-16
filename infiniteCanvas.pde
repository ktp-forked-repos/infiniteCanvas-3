import quinkennedy.thermal_printer.*;
import processing.serial.*;

SerialThermalPrint p;
PGraphics drawn, drawing;
PImage line;
int drawingOffset = 0;
boolean m_bMove = false;
boolean m_bRotate = false;
boolean m_bShift = false;
int drawLineDelay = 500;
int drawNextLine = 0;
boolean m_bPrinterReady = false;
long linesPrinted = 0;

int m_nCurrStroke = 1;
int m_nStrokeMem = m_nCurrStroke;
boolean m_bTest = false;
boolean m_bErase = false;
int canvasWidth = 1000;
int maxCanvasWidth = 4096;
int baudRate = 9600;
float m_nCurrRotation = 0;
float m_nMouseStartRotation = 0;
float m_nCanvasStartRotation = 0;
boolean m_bLooping = false;
boolean m_bCopyMode = false;
boolean m_bShowHelp = false;
boolean m_bAdjustCanvasWidth = false;
boolean m_bMoveOffset = true;
PImage openHand, closedHand, rotateCursor, resizeCursor;

void setup(){
  size(displayWidth, displayHeight);
  //size(1000, SerialThermalPrint.MAX_WIDTH);
  setupGraphics();
  setupPrinter();
  noCursor();
}

void setupGraphics(){
  drawn = createGraphics(maxCanvasWidth, SerialThermalPrint.MAX_WIDTH);
  drawn.beginDraw();
  drawn.background(255);
  drawn.fill(0, 100);
  drawn.noStroke();
  drawn.rect(0, 0, drawn.width, drawn.height);
  drawn.endDraw();
  drawing = createGraphics(maxCanvasWidth, SerialThermalPrint.MAX_WIDTH);
  drawing.beginDraw();
  drawing.background(255);
  drawing.endDraw();
  line = createImage(SerialThermalPrint.MAX_WIDTH, 1, ARGB);
  
  //load cursors
  openHand = loadImage("hand-cursor.png");
  closedHand = loadImage("grab-cursor.png");
  rotateCursor = loadImage("rotate-cursor.png");
  resizeCursor = loadImage("move-cursor.png");
}

void setupPrinter(){
  if (m_bTest){
    return;
  }
  p = new SerialThermalPrint(this);
  //println(p.list());
  //p.connect(p.list()[0], 9600);
  println(Serial.list());
  println(p.list());
  try{
    p.connect(Serial.list()[0], baudRate);
  } catch(Exception e){
    m_bTest = true;
    p = null;
  }
}

void draw(){
  drawing.strokeWeight(m_nCurrStroke);
  background(50);
  pushMatrix();
  translate(width/2, height/2);
  if (m_bRotate && mousePressed){
    updateCanvasRotation();
  }
  rotate(m_nCurrRotation);
  translate(-canvasWidth/2, -SerialThermalPrint.MAX_WIDTH/2);
  if (m_bLooping){
    image(drawing, 0, 0, drawingOffset, SerialThermalPrint.MAX_WIDTH, 
      canvasWidth - drawingOffset, 0, canvasWidth, SerialThermalPrint.MAX_WIDTH);
  } else {
    image(drawn, 0, 0, drawingOffset, SerialThermalPrint.MAX_WIDTH, 
        drawn.width-drawingOffset, 0, drawn.width, SerialThermalPrint.MAX_WIDTH);
  }
  translate(drawingOffset, 0);
  image(drawing, 0, 0, canvasWidth - drawingOffset, SerialThermalPrint.MAX_WIDTH,
      0, 0, canvasWidth - drawingOffset, SerialThermalPrint.MAX_WIDTH);
  if (m_bLooping || m_bCopyMode){
    strokeWeight(1);
    stroke(255,0,255, 127);
    line(0, 0, 0, SerialThermalPrint.MAX_WIDTH);
  }
  popMatrix();
  drawHelp();
  drawInfo();
  drawCursor();
  printLine();
}

private void drawCursor(){
  if (m_bMove){
    if (mousePressed){
      image(closedHand, mouseX - closedHand.width/2, mouseY - closedHand.height/2);
    } else {
      image(openHand, mouseX - openHand.width/2, mouseY - openHand.height/2);
    }
  } else if (m_bRotate){
    if (mousePressed){
      //draw the delta arc
      //draw the start/end lines
      stroke(0);
      //shade in the arc
      noStroke();
      fill(0, 100);
      float currMouseAngle = getMouseAngle();
      if (currMouseAngle > m_nMouseStartRotation){
        arc(width/2, height/2, 200, 200, m_nMouseStartRotation, currMouseAngle, PIE); 
      } else {
        arc(width/2, height/2, 200, 200, m_nMouseStartRotation, currMouseAngle + PI*2, PIE);//currMouseAngle, m_nMouseStartRotation, PIE);
      }
      textAlign(CENTER, CENTER);
      fill(255,100,0);
      text(String.format("%.2f deg", degrees(currMouseAngle - m_nMouseStartRotation)), width/2, height/2);
    }
    image(rotateCursor, mouseX - rotateCursor.width/2, mouseY - rotateCursor.height/2);
  } else if (m_bAdjustCanvasWidth){
    image(resizeCursor, mouseX - resizeCursor.width/2, mouseY - resizeCursor.height/2);
  } else { 
    noFill();
    stroke(100);
    ellipse(mouseX, mouseY, m_nCurrStroke, m_nCurrStroke);
  }
}

private void drawInfo(){
  textAlign(TOP, RIGHT);
  //TODO: wrap rotation between 360/-360 (180/-180?)
  String[] text = new String[]{
    String.format("rotation: %.2f deg", degrees(m_nCurrRotation)),
    String.format("duration: %d:%d:%d", millis()/1000/60/60, millis()/1000/60%60, millis()/1000%60),
    "lines: " + linesPrinted,
    String.format("canvas width: %d px", canvasWidth)
  };
  
  for(int i = 0, j = 16; i < text.length; i++, j += 16){
    text(text[i], width - 150, j);
  }
}

private void drawHelp(){
  textAlign(TOP, LEFT);
  fill(255,100,255);
  String[] text = new String[]{
    "h - toggle - show help text",
    "[SPACE] - momentary - move canvas left/right with mouse",
    "b - momentary - make brush very large",
    "e - momentary - erase mode (white brush)",
    "'[' and ']' - toggle - decrement and increment brush size",
    "[SHIFT] + '[' and ']' - toggle - dec. and inc. brush size x5",
    "0 through 9 - radio - set print delay x100 milliseconds",
    "l - toggle - enable copy mode",
    "L - toggle - enable looping mode",
    "[UP] and [DOWN] - toggle - rotate canvas",
    "r - momentary - rotate canvas with mouse",
    "w - momentary - adjust the canvas width with mouse",
    "f - toggle - freeze canvas offset"};
    //preserve 's' for 'save' and 'o' for 'open'
    
  for(int i = 0, j = 16; i < (m_bShowHelp ? text.length : 1); i++, j += 16){
    text(text[i], 10, j);
  }
}

private void printLine(){
  if ((m_bPrinterReady || m_bTest) && drawNextLine < millis()){
    drawNextLine = millis() + drawLineDelay;
    m_bPrinterReady = false;
    drawing.loadPixels();
    for(int i = 0; i < drawing.height; i++){
      line.pixels[i] = drawing.pixels[(drawing.height - 1 - i)*drawing.width];
    }
    line.updatePixels();
    
    drawn.beginDraw();
    drawn.copy(1, 0, drawn.width-1, drawn.height, 0, 0, drawn.width-1, drawn.height);
    drawn.pushMatrix();
    drawn.translate(drawn.width-1, drawn.height);
    drawn.rotate(-PI/2.0);
    drawn.image(line, 0, 0);
    drawn.popMatrix();
    drawn.stroke(0, 100);
    drawn.line(drawn.width-1, 0, drawn.width-1, drawn.height);
    drawn.endDraw();
    
    drawing.beginDraw();
    drawing.copy(1, 0, drawing.width-1, drawing.height, 0, 0, drawing.width-1, drawing.height);
    if (m_bLooping || m_bCopyMode){
      //TODO: why doesn't this work?!?
      /*
      drawing.pushMatrix();
      drawing.translate(drawing.width-1, drawing.height);
      drawing.rotate(-PI/2.0);
      drawing.image(line, 0, 0);
      drawing.popMatrix();
      */
    } else {
      drawing.stroke(255);
      drawing.strokeWeight(1);
      drawing.line(canvasWidth-1, 0, canvasWidth-1, drawing.height);
    }
    drawing.endDraw();
    
    //NOTE: This feels like a temporary hack until 
    //  I can figure out why the TODO above doesn't work
    if (m_bLooping || m_bCopyMode){
      line.loadPixels();
      for(int i = 0; i < line.width; i++){
        drawing.pixels[(canvasWidth-1)+(drawing.width*i)] = line.pixels[line.width-1-i];
      }
      drawing.updatePixels();
    }
    
    if (m_bMoveOffset){
      drawingOffset = min(drawingOffset+1, canvasWidth);
    }
    thread("doPrint");
  }
}

public void doPrint(){
  if (!m_bTest){
    p.print(line);
  }
  linesPrinted++;
}

public void onPrinterReady(){
  m_bPrinterReady = true;
  printLine();
}

void mouseDragged(){
  if (m_bMove){
    drawingOffset += (mouseX - pmouseX); 
    if (m_bLooping){
      //TODO: this doesn't work when the canvas is rotated
      drawingOffset %= canvasWidth;
      while (drawingOffset < 0){
        drawingOffset += canvasWidth;
      }
    } else {
      drawingOffset = constrain(drawingOffset, 0, canvasWidth);
    }
  } else if (m_bRotate){
    //TODO: should the rotation update happen here instead of in the draw loop?
    //  probably
  } else if (m_bAdjustCanvasWidth){
    canvasWidth = constrain(canvasWidth + (mouseX - pmouseX), 1, maxCanvasWidth);
  } else {
    drawLineOnCanvas(mouseX, mouseY, pmouseX, pmouseY);
    /*if (m_bLooping){
      drawLineOnCanvas(mouseX + canvasWidth, mouseY, pmouseX + canvasWidth, pmouseY);
    }*/
  }
}

void drawLineOnCanvas(int mouseX, int mouseY, int pmouseX, int pmouseY){
    drawing.beginDraw();
    drawing.stroke(m_bErase ? 255 : 0);
    drawing.pushMatrix();
    adjustForDrawing();
    drawing.line(pmouseX, pmouseY, mouseX, mouseY);
    drawing.popMatrix();
    if (m_bLooping){
      drawing.pushMatrix();
      drawing.translate(canvasWidth, 0);
      adjustForDrawing();
      drawing.line(pmouseX, pmouseY, mouseX, mouseY);
      drawing.popMatrix();
    }
    cleanUpOverdraw();
    drawing.endDraw();
}

private void drawEllipseOnCanvas(int mouseX, int mouseY){
  drawing.beginDraw();
  drawing.fill(m_bErase ? 255 : 0);
  drawing.noStroke();
  drawing.pushMatrix();
  adjustForDrawing();
  drawing.ellipse(mouseX, mouseY, m_nCurrStroke, m_nCurrStroke);
  drawing.popMatrix();
  cleanUpOverdraw();
  drawing.endDraw();
}

void adjustForDrawing(){
  drawing.translate(-drawingOffset, 0);
  drawing.translate(canvasWidth/2, drawing.height/2);
  drawing.rotate(-m_nCurrRotation);
  drawing.translate(-width/2, -height/2);
}

void cleanUpOverdraw(){
    //clean up any over-draw off the active canvas
    drawing.fill(255);
    drawing.noStroke();
    drawing.rect(canvasWidth, 0, drawing.width - canvasWidth, SerialThermalPrint.MAX_WIDTH);
}

float getMouseAngle(){
  return atan2(mouseY - height/2, mouseX - width/2);
}

void mousePressed(){
  if (m_bRotate){
    m_nMouseStartRotation = getMouseAngle();
    m_nCanvasStartRotation = m_nCurrRotation;
  }
}

void updateCanvasRotation(){
    m_nCurrRotation = m_nCanvasStartRotation + (getMouseAngle() - m_nMouseStartRotation);
    if (m_bShift){
      m_nCurrRotation = round(m_nCurrRotation / radians(45))*radians(45);
    }
}

void mouseReleased(){
  if (m_bRotate){
    updateCanvasRotation();
  }
}

void mouseClicked(){
  if (m_bMove || m_bRotate){
    return;
  }
  drawEllipseOnCanvas(mouseX, mouseY);
  if (m_bLooping){
    drawEllipseOnCanvas(mouseX + canvasWidth, mouseY);
  }
}

void keyPressed(){
  if (key == ' '){
    m_bMove = true;
  } else if (key >= '0' && key <= '9'){
    drawLineDelay = (key - '0') * 100;
  } else if (key == '['){
    m_nCurrStroke = Math.max(m_nCurrStroke - 1, 1);
  } else if (key == ']'){
    m_nCurrStroke++;
  } else if (key == '{'){
    m_nCurrStroke = Math.max(m_nCurrStroke - 5, 1);
  } else if (key == '}'){
    m_nCurrStroke += 5;
  } else if (key == 'b'){
    m_nStrokeMem = m_nCurrStroke;
    m_nCurrStroke += Math.max(20, m_nCurrStroke/2);
  } else if (key == 'e'){
    m_bErase = true;
  } else if (key == 'l'){
    m_bCopyMode = !m_bCopyMode;
    m_bLooping = false;
  } else if (key == 'L'){
    m_bLooping = !m_bLooping;
    m_bCopyMode = false;
  } else if (key == 'h'){
    m_bShowHelp = !m_bShowHelp;
  } else if (key == 'r' || key == 'R'){
    m_bRotate = true;
    if (mousePressed){
      mousePressed();
    }
  } else if (key == 'w'){
    m_bAdjustCanvasWidth = true;
  } else if (key == 'f'){
    m_bMoveOffset = !m_bMoveOffset;
  } else if (key == CODED){ 
    if (keyCode == UP){
      m_nCurrRotation += .01;
    } else if (keyCode == DOWN){
      m_nCurrRotation -= .01;
    } else if (keyCode == SHIFT){
      m_bShift = true;
    }
  }
}

void keyReleased(){
  if (key == ' '){
    m_bMove = false;
  } else if (key == 'b'){
    m_nCurrStroke = m_nStrokeMem;
  } else if (key == 'e'){
    m_bErase = false;
  } else if (key == 'r' || key == 'R'){
    if (mousePressed){
      mouseReleased();
    }
    m_bRotate = false;
  } else if (key == 'w'){
    m_bAdjustCanvasWidth = false;
  } else if (key == CODED){
    if (keyCode == SHIFT){
      m_bShift = false;
    }
  }
}

void serialEvent(Serial port){
  p.serialEvent(port);
}
