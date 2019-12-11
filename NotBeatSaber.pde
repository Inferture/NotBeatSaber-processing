
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


/***GAME PARAMETERS TO CHANGE***/
String music="KRool";
GameMode mode=GameMode.Playing;
int bpm=140;//the higher the bpm, the higher the frequency of lines coming towards you. Just for aesthetic purpose.
/******************************/



//Declare an Arduino object 
Arduino arduino;  
//ARDUINOHERE
int RIGHT_ACCELEROMETER_X_PIN =5;
int RIGHT_ACCELEROMETER_Y_PIN =6;
int LEFT_ACCELEROMETER_X_PIN = 7; 
int LEFT_ACCELEROMETER_Y_PIN = 8; 

int ACCELERATION_TRESHOLD=50;


//
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
int combo = 0;
int multiplier = 1;
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

float WON_BLOCK_COLOR_MULTIPLIER=1.3;
float LOST_BLOCK_COLOR_MULTIPLIER=0.5;

float MIN_BRIGHTNESS=1;
float MAX_BRIGHTNESS=1;

   

static String MAIN_FOLDER;

Pattern pattern;

int currentSpawn=0;
int startTime;
int lastFrameTime;
int deltaTime=0;
color targetColor;
boolean fastTransformation;

SoundFile musicFile;
SoundFile cut;


void setup()  // runs once at start 
{   
  //println(Arduino.list());  // use this to get port# 
  
  MAIN_FOLDER=dataPath("");
  LINE_PERIOD=(int) (1000*(float)60/(float)bpm);
  
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
     pattern = Deserialize(music);  
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
  
  
  
  
  targetColor = RandomWallColor();
  PFont displayFont;
  displayFont = createFont("data/animeace2_reg.ttf", 12);
  textFont(displayFont);
  
  
  musicFile = new SoundFile(this, "data/" + music + ".mp3");
  musicFile.play();
  
  
  cut = new SoundFile(this, "data/" + "cut.wav");
  musicFile.play();
  
  startTime=millis();
  lastFrameTime=startTime;
  lastColorUpdateTime=startTime;
  
  
  
  launch(MAIN_FOLDER + "/tet.bat");
  //exec("echo", " \"Salut\" > text.txt ");
} 

void draw()  //loops forever 
{ 
  
  //Center in the center of the screen
  pushMatrix();
  translate(WIDTH/2, HEIGHT/2);
  
  
  
  
  /**/
  //Check the accelerometer values
  int right_x=0;
  int right_y=0;
  int left_x=0;
  int left_y=0;
  
  accelerometerAction(right_x, right_y, left_x, left_y);
  
  //ARDUINOHERE
  
  
  /****/
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
       if(!blocks.get(i).hit)
       {
         combo=0;
       }
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
  stroke(MultiplyColor(wallColor,1.3),190);
  //stroke(color(100,100,100));
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
  
  //Display infos
  if(mode==GameMode.Playing)
  {
    String infos = "Score: " + points + "\n";
    infos+="Combo: " + combo+"\n";
    infos+="Multiplier: " + multiplier;
    fill(wallColor);
    text(infos, -HORIZON_WIDTH/2,-HORIZON_HEIGHT/2, HORIZON_WIDTH, HORIZON_HEIGHT);
  }
  
  
  //Display blocks
  //fill(color(20,30,70,240));
  color blockColor1 = RGBtoGBR(wallColor);
  color blockColor2 = RGBtoGBR(blockColor1);
  
  //fill(blockColor,240);
  stroke(color(70,0,70,240));
  for(int i=blocks.size()-1;i>=0;i--)
  {
    color blockColor = blockColor1;
    if(GetTypeValue(blocks.get(i).type)<=3)
    {
        blockColor = blockColor2;
    }
    fill(blockColor,240);
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
        color wonColor = MultiplyColor(blockColor, WON_BLOCK_COLOR_MULTIPLIER);
        fill(wonColor,alpha);
        stroke(wonColor,alpha);
        blocks.get(i).Display(); 
        fill(blockColor,240);
        //fill(color(20,30,70,240));
        stroke(blockColor,240);
      }
      blocks.get(i).disappearTimer+=deltaTime;
    }
    else if(blocks.get(i).transform.z<(Z_HIT_RATIO-Z_HIT_RATIO_TOLERANCE)*Z0)
    {
        color lostColor = MultiplyColor(blockColor,LOST_BLOCK_COLOR_MULTIPLIER);
        fill(lostColor,240);
        stroke(lostColor,240);
        blocks.get(i).Display(); 
        
        fill(blockColor,240);
        stroke(blockColor,240);
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
   
  float min_brightness=255*3*MIN_BRIGHTNESS;
  float max_brightness=255*3*MAX_BRIGHTNESS;
   int r = int(random(255)); 
   int g = int(random(255));
   int b = int(random(255));
   
   float brightness = max(r+g+b,1);
   
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
   //return color(256,256,256);
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
color MultiplyColor(color c, float f)
{
   return color(red(c)*f, green(c)*f, blue(c)*f); 
}


/**Interprets accelerometer values and acts accordingly*/
void accelerometerAction(int right_x, int right_y, int left_x, int left_y)
{
  //Right
   if(right_x>ACCELERATION_TRESHOLD && right_x>abs(right_y))
   {
     for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.Right)
         {
             blocks.get(i).hit=true;
             points+=multiplier;
             combo++;
             cut.play();
         }
      }
   }
   
   //RightUP
   if(right_y>ACCELERATION_TRESHOLD && right_y>right_x)
   {
     for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.RightUp)
         {
             blocks.get(i).hit=true;
             points+=multiplier;
             combo++;
             cut.play();
         }
      }
   }
   
   //RightDOWN
   if(right_y<-ACCELERATION_TRESHOLD && right_y<-right_x)
   {
     for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.RightDown)
         {
             blocks.get(i).hit=true;
             points+=multiplier;
             combo++;
             cut.play();
         }
      }
   }
   
   //Left
   
   if(left_x<-ACCELERATION_TRESHOLD && left_x<-abs(left_y))
   {
     for(int i=0;i<blocks.size();i++)
      {
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.Left)
         {
             blocks.get(i).hit=true;
             points+=multiplier;
             combo++;
             cut.play();
         }
      }
   }
   
   //LeftUp
   
   if(left_y>ACCELERATION_TRESHOLD && left_y>-left_x)
   {
     for(int i=0;i<blocks.size();i++)
      {
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.LeftUp)
         {
             blocks.get(i).hit=true;
             points+=multiplier;
             combo++;
             cut.play();
         }
      }
   }
   
   //LeftDown
   if(left_y<-ACCELERATION_TRESHOLD && left_y<-left_x)
   {
     for(int i=0;i<blocks.size();i++)
      {
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.LeftDown)
         {
             blocks.get(i).hit=true;
             points+=multiplier;
             combo++;
             cut.play();
         }
      }
   }
   
   
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
    if (key=='o' || key=='O')
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.RightUp)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points+=multiplier;
             combo++;
             //print(points + "/");
             cut.play();
         }
      }
    } 
    if (key=='m' || key=='M')
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.Right)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points+=multiplier;
             combo++;
             //print(points + "/");
             cut.play();
         }
      }
    }
    if (key=='l' || key=='L')
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.RightDown)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points+=multiplier;
             combo++;
             //print(points + "/");
             cut.play();
         }
      }
    }
    if (key=='z' || key=='Z')
    {
       for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.LeftUp)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points+=multiplier;
             combo++;
             //print(points + "/");
             cut.play();
         }
      }
    } 
    if (key=='q' || key=='Q')
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.Left)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points+=multiplier;
             combo++;
             //print(points + "/");
             cut.play();
         }
      }
    }
    if (key=='s' || key=='S')
    {
      for(int i=0;i<blocks.size();i++)
      {
         
         if(blocks.get(i).hittable && !blocks.get(i).hit && blocks.get(i).type==BlockType.LeftDown)
         {
             blocks.get(i).hit=true;
             //blocks.get(i).enabled=false;
             points+=multiplier;
             combo++;
             //print(points + "/");
             cut.play();
         }
      }
    }
    multiplier = combo/10 +1;
    
  }
}

 
  
  
static int GetTypeValue(BlockType type)
{
  switch(type)
  {
    case None:return 0;
    case Right:return 1;
    case RightUp: return 2;
    case RightDown: return 3;
    case Left:return 4;
    case LeftUp:return 5;
    case LeftDown: return 6;
  }
  return -1;
}

static BlockType GetValueType(int typeValue)
{
  switch(typeValue)
  {
    case 0:return BlockType.None;
    case 1:return BlockType.Right;
    case 2: return BlockType.RightUp;
    case 3: return BlockType.RightDown;
    case 4:return BlockType.Left;
    case 5:return BlockType.LeftUp;
    case 6: return BlockType.LeftDown;
  }
  return BlockType.None;
}
