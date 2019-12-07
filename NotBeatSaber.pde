
import processing.serial.*;
import http.requests.*;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.*;
import processing.sound.*;

import cc.arduino.*;     //import  Arduino classes 

enum GameMode
{
   Playing,
   Saving
}



String music="MeltyBlood";
GameMode mode=GameMode.Playing;

//Declare an Arduino object 
Arduino arduino;  
int pin =5;
int ledPin = 13; 

int BLOCK_WIDTH=200;
int BLOCK_HEIGHT=600;

float Z0=1000;
float Z_SPEED=0.5;


int HORIZON_WIDTH=100;
int HORIZON_HEIGHT=75;

int WIDTH=800;
int HEIGHT=600;

float SCALE_HORIZON = 0.125;

int points = 0;

ArrayList<Line> lines;
ArrayList<Block> blocks;
ArrayList<Block> hittableBlocks;

Line limitDown;
Line limitUp;
Line limitLeft;
Line limitRight;

Block limitFar;
Block limit;
Block limitClose;

int LINE_PERIOD=500;
int lastLineTime;

int COLOR_UPDATE_PERIOD=200;
int lastColorUpdateTime;
color wallColor=color(20,65,0);

float Z_HIT_RATIO=0.1;
float Z_HIT_RATIO_TOLERANCE=0.05;

int DISAPPEAR_TIME=200;



static String MAIN_FOLDER;

Pattern pattern;

int currentSpawn=0;
int startTime;
int lastFrameTime;
int deltaTime=0;
color targetColor;
boolean fastTransformation;

SoundFile musicFile;

void setup()  // runs once at start 
{   
  //println(Arduino.list());  // use this to get port# 
  
  MAIN_FOLDER=dataPath("");
  lines=new ArrayList<Line>();
  blocks=new ArrayList<Block>();
  
  limitFar = new Block(WIDTH, HEIGHT);
  limitFar.transform.z = (int)(Z0* (Z_HIT_RATIO+Z_HIT_RATIO_TOLERANCE));
  
  limit = new Block(WIDTH, HEIGHT);
  limit.transform.z = (int)(Z0* Z_HIT_RATIO);
  
  limitClose = new Block(WIDTH, HEIGHT);
  limitClose.transform.z = (int)(Z0* (Z_HIT_RATIO-Z_HIT_RATIO_TOLERANCE));
  
  //Initiates the screen
  size(800, 600);

  /*
  arduino = new Arduino(this, Arduino.list()[0], 57600);     //instanciate own Arduino object  // COM port number and baudrate
  arduino.pinMode(ledPin, Arduino.OUTPUT); 
  arduino.pinMode(pin, Arduino.INPUT);
  */
  
  
  if(mode==GameMode.Playing)
  {
     pattern = Pattern.Deserialize(music);  
     /*print(pattern.spawns.size());
     print("-");
     print(pattern.spawns.get(0).time);
      print("-");
     print(pattern.spawns.get(0).type);*/
  }
  else
  {
     pattern = new Pattern(music); 
  }
  
  
  musicFile = new SoundFile(this, "data/" + music + ".mp3");
  musicFile.play();
  
  startTime=millis();
  lastFrameTime=startTime;
  lastColorUpdateTime=startTime;
    
  //pattern.Serialize();
  
  targetColor = RandomWallColor();
  
} 

void draw()  //loops forever 
{ 
  
  //Center in the center of the screen
  pushMatrix();
  translate(WIDTH/2, HEIGHT/2);
  
  
  //Changes road color
  if(wallColor==targetColor)
  {
      fastTransformation=false;
      targetColor=RandomWallColor();
  }
  if(millis()>lastColorUpdateTime+COLOR_UPDATE_PERIOD)
  {
    if(fastTransformation)
    {
      wallColor = GetNextColor(wallColor, targetColor, 10) ;
    }
    
    else
    {
      wallColor = GetNextColor(wallColor, targetColor, 1) ;
    }
    lastColorUpdateTime=millis();
  }
  
  
  //Spawn moving lines
  if(millis()>lastLineTime+LINE_PERIOD)
  {
    lines.add(new Line(0));
    lines.add(new Line(1));
    lines.add(new Line(2));
    lines.add(new Line(3));
    lastLineTime=millis();
  }
  
  //Spawn blocks
   if(mode==GameMode.Playing)
  {
      if(currentSpawn<pattern.spawns.size() && pattern.spawns.get(currentSpawn).time - Z0*(1-Z_HIT_RATIO)/Z_SPEED<=millis()-startTime)
      {
        blocks.add(new Block(pattern.spawns.get(currentSpawn).type));
        currentSpawn++;
      }
  }
  
  clear();
  
  
  
  //Move blocks
  
  for(int i=0;i<blocks.size();i++)
  {
     blocks.get(i).transform.z-=Z_SPEED*deltaTime; 
     blocks.get(i).hittable= blocks.get(i).transform.z>=Z0*(Z_HIT_RATIO-Z_HIT_RATIO_TOLERANCE) && blocks.get(i).transform.z<=Z0*(Z_HIT_RATIO+Z_HIT_RATIO_TOLERANCE);
     
     if(blocks.get(i).transform.z<0)
     {
        blocks.get(i).enabled=false; 
     }
  }
  
  //Move lines
  for(int i=0;i<lines.size();i++)
  {
     lines.get(i).transform.z-=Z_SPEED*deltaTime;
     if(lines.get(i).transform.z<0)
     {
        lines.get(i).enabled=false; 
     }
  }
  
  Ditch();//Deletes disabled GameObjects
  Display();
  
  popMatrix();
  
  deltaTime=millis()-lastFrameTime;
  lastFrameTime=millis();  
}


void Display()
{
  //Display Road
  stroke(color(10,30,0));
  fill(wallColor);
  triangle(0,0,WIDTH/2, HEIGHT/2, -WIDTH/2, HEIGHT/2);
  triangle(0,0,-WIDTH/2, -HEIGHT/2, WIDTH/2, -HEIGHT/2);
  
  fill(color(0.7*red(wallColor),0.7*green(wallColor),0.7*blue(wallColor)));
  triangle(0,0,WIDTH/2, -HEIGHT/2, WIDTH/2, HEIGHT/2);
  triangle(0,0,-WIDTH/2, HEIGHT/2, -WIDTH/2, -HEIGHT/2);
  
  //Display lines
  stroke(color(100,100,100));
  for(int i=0;i<lines.size();i++)
  {
     lines.get(i).Display(); 
  }
  
  //Display goal
  stroke(color(235,232,52));
  fill(color(255,255,255,0));
  limit.Display();
  stroke(color(235, 158, 52));
  limitFar.Display();
  limitClose.Display();
  
  
  //Display Void
  stroke(color(5,5,10));
  fill(color(5,5,10));
  rect(-HORIZON_WIDTH/2,-HORIZON_HEIGHT/2, HORIZON_WIDTH, HORIZON_HEIGHT);
  
  //Display blocks
  //fill(color(20,30,70,240));
  fill(RGBtoGBR(wallColor),240);
  stroke(color(70,0,70,240));
  for(int i=blocks.size()-1;i>=0;i--)
  {
    if(blocks.get(i).hit)
    {
      float alpha = 240 - (float)blocks.get(i).disappearTimer/DISAPPEAR_TIME * 255;
      if(alpha<=0)
      {
         blocks.get(i).enabled=false; 
      }
      else
      {
        //fill(color(20,30,70,alpha));
        fill(RGBtoGBR(wallColor),alpha);
        stroke(RGBtoGBR(wallColor),alpha);
        blocks.get(i).Display(); 
        fill(RGBtoGBR(wallColor),240);
        //fill(color(20,30,70,240));
        stroke(RGBtoGBR(wallColor),240);
      }
      blocks.get(i).disappearTimer+=deltaTime;
    }
    else
    {
      blocks.get(i).Display(); 
    }
     
  }
}

/**Deletes unnecessary objects*/
void Ditch()
{
  for(int i=0;i<lines.size();i++)
  {
    if(!lines.get(i).enabled)
    {
      lines.remove(i);
    }
  }
   for(int i=0;i<blocks.size();i++)
  {
     if(!blocks.get(i).enabled)
    {
      blocks.remove(i);
    }
  }
}

/**Generates a random color for the road (not too dard, not too bright)*/
color RandomWallColor()
{
   float min_brightness=255*3*0.3;
   
   float max_brightness=255*3*0.7;
  
   int r = int(random(255)); 
   int g = int(random(255));
   int b = int(random(255));
   
   int brightness = r+g+b;
   
   if(r+g+b<min_brightness)
   {
      r*= min_brightness/brightness;
      g*= min_brightness/brightness;
      b*= min_brightness/brightness;
   }
   if(r+g+b>max_brightness)
   {
      r*= max_brightness/brightness;
      g*= max_brightness/brightness;
      b*= max_brightness/brightness;
   }
   return color(r,g,b);
}

/**Gets from a color current to a color target with the speed speed*/
color GetNextColor(color current, color target, int speed)
{
    if(red(current)>red(target))
    {
      current = color(max(red(target),red(current)-speed),green(current), blue(current)); 
    }
    if(red(current)<red(target))
    {
      current = color(min(red(target),red(current)+speed),green(current), blue(current)); 
    }
    
    if(blue(current)>blue(target))
    {
      current = color(red(current),green(current), max(blue(target),blue(current)-speed)); 
    }
    if(blue(current)<blue(target))
    {
      current = color(red(current),green(current), min(blue(target),blue(current)+speed)); 
    }
    
    if(green(current)>green(target))
    {
      current = color(red(current), max(green(target),green(current)-speed), blue(current)); 
    }
    if(green(current)<green(target))
    {
      current = color(red(current), min(green(target),green(current)+speed), blue(current)); 
    }
    return current;
}

color RGBtoGBR(color origin)
{
  return color(green(origin), blue(origin), red(origin));
}


/**What to do when a certain key is pressed*/
void keyPressed()
{
  //In saving mode, we add blocks when the buttons are pressed
  if(mode==GameMode.Saving)
  {
    if (key=='o' )
    {
      pattern.Add(BlockType.RightUp, millis()-startTime);
      blocks.add(new Block(BlockType.RightUp));
      
    } 
    if (key=='m' )
    {
      pattern.Add(BlockType.Right, millis()-startTime);
      blocks.add(new Block(BlockType.Right));
    }
    if (key=='l' )
    {
      pattern.Add(BlockType.RightDown, millis()-startTime);
      blocks.add(new Block(BlockType.RightDown));
    }
    if (key=='z' )
    {
      pattern.Add(BlockType.LeftUp, millis()-startTime);
      blocks.add(new Block(BlockType.LeftUp));
    } 
    if (key=='q' )
    {
      pattern.Add(BlockType.Left, millis()-startTime);
      blocks.add(new Block(BlockType.Left));
    }
    if (key=='s' )
    {
      pattern.Add(BlockType.LeftDown, millis()-startTime);
      blocks.add(new Block(BlockType.LeftDown));
    }
    if (key=='g' )
    {
      pattern.Serialize();
    }
  }
  
  //In playing mode, the blocks are destructed when the button is pressed at the right moment
  else if(mode==GameMode.Playing)
  {
    if (key=='o' )
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && blocks.get(i).type==BlockType.RightUp)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points++;
             print(points + "/");
         }
      }
    } 
    if (key=='m' )
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && blocks.get(i).type==BlockType.Right)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points++;
             print(points + "/");
         }
      }
    }
    if (key=='l' )
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && blocks.get(i).type==BlockType.RightDown)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points++;
             print(points + "/");
         }
      }
    }
    if (key=='z' )
    {
       for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && blocks.get(i).type==BlockType.LeftUp)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points++;
             print(points + "/");
         }
      }
    } 
    if (key=='q' )
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && blocks.get(i).type==BlockType.Left)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points++;
             print(points + "/");
         }
      }
    }
    if (key=='s' )
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && blocks.get(i).type==BlockType.LeftDown)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points++;
             print(points + "/");
         }
      }
    }
  }
}
