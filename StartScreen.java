import processing.serial.*;
import processing.core.*;

class StartScreen{
  PVector radioLoc = new PVector(20, 100);
  PVector beginLoc = new PVector(500, 200);
  Option[] options;
  PVector timeLoc = new PVector(250, 100);
  infiniteCanvas p;
  
  class Option{
    String label;
    String value;
    boolean selected;
  }
  
  public StartScreen(infiniteCanvas p){
    this.p = p;
    updateOptions();
  }
  
  public void updateOptions(){
    options = new Option[Serial.list().length+1];
    for(int i = 0; i < Serial.list().length; i++){
      options[i] = new Option();
      options[i].label = Serial.list()[i];
      options[i].value = Serial.list()[i];
    }
    options[options.length - 1] = new Option();
    options[options.length - 1].label = "test";
    options[options.length - 1].value = "test";
    options[options.length - 1].selected = true;
  }
  
  public void draw(){
    p.background(150);
    //draw serial options
    p.stroke(255);
    p.textAlign(PApplet.LEFT, PApplet.TOP);
    int i, y;
    for(i = 0, y = (int)radioLoc.y; i < options.length; i++, y += 20){
      p.fill(0, options[i].selected ? 255 : 0, 0);
      p.rect(radioLoc.x, y+3, 10, 10);
      p.fill(255);
      p.text(options[i].label, radioLoc.x + 13, y);
    }
    String buttonText = "update list";
    drawButton(new PVector(radioLoc.x, y), buttonText);
    
    //draw timing options
    
    //draw buttons
    drawButton(beginLoc, "start!");
  }
  
  void drawButton(PVector location, String text){
    p.textAlign(PApplet.CENTER, PApplet.TOP);
    p.stroke(255);
    p.fill(0);
    PVector buttonSize = new PVector(p.textWidth(text)+20, 20);
    p.rect(location.x, location.y, buttonSize.x, buttonSize.y);
    p.fill(255);
    p.text(text, 
        location.x + buttonSize.x/2, 
        location.y + (buttonSize.y - p.textAscent() - p.textDescent())/2);
  }
  
  public void mouseClicked(){
    //clicked an option?
    int i, y;
    PVector mousePos = new PVector(p.mouseX, p.mouseY);
    PVector boxSize = new PVector(10, 10);
    for(i = 0, y = (int)radioLoc.y; i < options.length; i++, y += 20){
      if (inside(mousePos, new PVector(radioLoc.x, y), boxSize)){
        break;
      }
    }
    
    if (i < options.length){
      //we clicked inside one of the options
      for(int j = 0; j < options.length; j++){
        options[j].selected = (j == i);
      }
      return;
    } else {
      //update options?
      if (inside(mousePos, new PVector(radioLoc.x, y), new PVector(p.textWidth("update list"), 20))){
        updateOptions();
        return;
      }
    }
    
    //clicked on start?
    if (inside(mousePos, beginLoc, new PVector(p.textWidth("start!"), 20))){
      //begin the actual program
      String currOption = null;
      for(Option o : options){
        if (o.selected){
          if (!o.value.equals("test")){
            currOption = o.value;
          }
          break;
        }
      }
      p.begin(currOption, -1);
    }
  }
  
  boolean inside(PVector point, PVector location, PVector size){
    return (point.x > location.x && 
        point.x < location.x + size.x &&
        point.y > location.y &&
        point.y < location.y + size.y);
  }
}
