
import processing.serial.*;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.*;
import processing.sound.*;
import processing.io.*;

import cc.arduino.*;     //import  Arduino classes 
import processing.serial.*;



enum GameMode
{
   Playing,
   Saving
}


enum GameStep
{
   ChooseMode,
   ChooseMusic,
   Game,
   End
}

GameStep step = GameStep.ChooseMode;
/***GAME PARAMETERS TO CHANGE***/
String music="MeltyBlood";
GameMode mode=GameMode.Playing;
int bpm=153;//the higher the bpm, the higher the frequency of lines coming towards you. Just for aesthetic purpose.
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

int WIDTH=1200;
int HEIGHT=900;

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
color MENU_SCREEN_COLOR = color(24, 71, 74);
float Z_HIT_RATIO=0.1;
float Z_HIT_RATIO_TOLERANCE=0.05;

int DISAPPEAR_TIME=200;

float WON_BLOCK_COLOR_MULTIPLIER=1.3;
float LOST_BLOCK_COLOR_MULTIPLIER=0.5;

float MIN_BRIGHTNESS=1;
float MAX_BRIGHTNESS=1;


int CREDIT_DISPLAY_TIME=5000;

int CREDIT_WIDTH=300;
int CREDIT_HEIGHT=30;

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



Serial acc_port;  // The serial port


I2C acc1;
I2C acc2;

int last_acc_right_x;
int last_acc_right_y;
int last_acc_left_x;
int last_acc_left_y;

int acc_right_x;
int acc_right_y;
int acc_left_x;
int acc_left_y;

PFont displayFont;
PFont displayFontLarge;


ArrayList<String> musics = new ArrayList<String>();
int currentMusic;



void StartGame(String musicFileName)
{
  text("Loading...",WIDTH/2,HEIGHT/2,WIDTH, HEIGHT);
  
  if(mode==GameMode.Playing)
  {
     pattern = Deserialize(musicFileName);
     Z_SPEED=abs(Z_SPEED);
  }
  else
  {
     pattern = new Pattern(musicFileName); 
     Z_SPEED=-abs(Z_SPEED);
  }
  
  musicFile = new SoundFile(this, "data/" + musicFileName + ".mp3");
  musicFile.play();
  
  step=GameStep.Game;
  startTime=millis();
  lastFrameTime=startTime;
  lastColorUpdateTime=startTime; 
  
  
  
}


void setup()  // runs once at start 
{   
  //println(Arduino.list());  // use this to get port# 
  //acc_port = new Serial(this, Serial.list()[0], 9600);
  
  if(I2C.list().length>0)
  {
    println(I2C.list().length);
    println(I2C.list()[0]);
    acc1 = new I2C(I2C.list()[0]);
    if(I2C.list().length>1)
    {
      acc2 = new I2C(I2C.list()[1]);
    }
    else
    {
      acc2 = new I2C(I2C.list()[0]);
    }
  }
  

  //ARDUINOHERE
  
  SCALE_HORIZON=(float)HORIZON_WIDTH/(float)WIDTH;
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
  size(1200, 900);

  targetColor = RandomWallColor();
  displayFontLarge= createFont("data/animeace2_reg.ttf", 16);
  displayFont = createFont("data/animeace2_reg.ttf", 12);
  textFont(displayFont);
  
  cut = new SoundFile(this, "data/" + "cut.wav");
  
  
} 


void draw()  //loops forever 
{ 
  
  //Center in the center of the screen
  pushMatrix();
  translate(WIDTH/2, HEIGHT/2);
  clear();
  
  if(step==GameStep.ChooseMode || step==GameStep.ChooseMusic)
  {
    
    Display();
  }
  
  if(step==GameStep.Game)
  {
    
      /**/
    //Check the accelerometer values
    getAccelerometerValues();
    
    
    int right_x=acc_right_x;
    int right_y=acc_right_y;
    int left_x=acc_left_x;
    int left_y=acc_left_y;
    
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
    
    
    
    
  }
  
  popMatrix();
  deltaTime=millis()-lastFrameTime;
  lastFrameTime=millis(); 
}


void Display()
{
  if(step==GameStep.ChooseMode)
  {
    fill(MENU_SCREEN_COLOR);
    stroke(MENU_SCREEN_COLOR);//24, 71, 74);
    rect(-WIDTH/2,-HEIGHT/2,WIDTH,HEIGHT);
     if(mode==GameMode.Playing)
     {
         textFont(displayFontLarge);
         fill(color(0,255,255));
         text(">Play", -WIDTH/2+60,-HORIZON_HEIGHT/2, WIDTH, HORIZON_HEIGHT);
         textFont(displayFont);
         fill(color(255,255,255));
         text("Make a pattern", -WIDTH/2+60,-HORIZON_HEIGHT/2+60, WIDTH, HORIZON_HEIGHT);
     }
     else
     {
         textFont(displayFont);
         fill(color(255,255,255));
         text("Play", -WIDTH/2+60,-HORIZON_HEIGHT/2, WIDTH, HORIZON_HEIGHT);
         textFont(displayFontLarge);
         fill(color(0,255,255));
         text(">Make a pattern", -WIDTH/2+60,-HORIZON_HEIGHT/2+60, WIDTH, HORIZON_HEIGHT);
     }
  }
  if(step==GameStep.ChooseMusic)
  {
       fill(MENU_SCREEN_COLOR);
       stroke(MENU_SCREEN_COLOR);//24, 71, 74);
       rect(-WIDTH/2,-HEIGHT/2,WIDTH,HEIGHT);
       textFont(displayFont);
       fill(color(255,255,255));
       for(int i=0;i<currentMusic;i++)
       {
           text(musics.get(i), -WIDTH/2+120,-HEIGHT/2 + 60*(i+1), WIDTH, HORIZON_HEIGHT);
       }
       textFont(displayFontLarge);
       fill(color(0,255,255));
       text(musics.get(currentMusic), -WIDTH/2+120,-HEIGHT/2 + 60*(currentMusic+1), WIDTH, HORIZON_HEIGHT);
       textFont(displayFont);
       fill(color(255,255,255));
       for(int i=currentMusic+1;i<musics.size();i++)
       {
           text(musics.get(i), -WIDTH/2+120,-HEIGHT/2 + 60*(i+1), WIDTH, HORIZON_HEIGHT);
       }
       
  }
  if(step==GameStep.Game)
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
    for(int k=blocks.size()-1;k>=0;k--)
    {
      int i=k;
      if(mode==GameMode.Saving)
      {
        i=blocks.size()-1-k;
      }
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
    
    
    //Display credits
    if(millis() - startTime < CREDIT_DISPLAY_TIME)
    {
      
      if(millis() - startTime < CREDIT_DISPLAY_TIME/2)
      {
        fill(Negative(wallColor));
      }
      else
      {
        fill(Negative(wallColor),255 * 2*(1- ((float)(millis() - startTime)/ CREDIT_DISPLAY_TIME)));
      }
      
      
      String credits = pattern.musicName + " ~ ";
      credits+=pattern.artistName;
      text(credits, WIDTH/2-CREDIT_WIDTH, HEIGHT/2-CREDIT_HEIGHT, CREDIT_WIDTH, CREDIT_HEIGHT);
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
      i--;
    }
  }
   for(int i=0;i<blocks.size();i++)
  {
     if(!blocks.get(i).enabled)
    {
      blocks.remove(i);
      i--;
    }
  }
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
  
  
  if(step==GameStep.ChooseMode)
  {
    if(keyCode==UP || keyCode==DOWN )
      {
        if(mode==GameMode.Playing)
        {
           mode=GameMode.Saving; 
        }
        else
        {
           mode=GameMode.Playing;
        }
      }
      if(keyCode==ENTER)
      {
        step=GameStep.ChooseMusic;
        
        if(mode==GameMode.Saving)
        {
          musics = new ArrayList<String>();
          File f = new File(MAIN_FOLDER);
          FilenameFilter mp3Only = new FilenameFilter() {
          public boolean accept(File dir, String name) {
            return name.toLowerCase().endsWith(".mp3");
          }};
          if (f.isDirectory()) {
            File[] files = f.listFiles(mp3Only);
            for(File file: files)
            {
               String name = file.getName().substring(0,file.getName().length()-4);
               println(name);
               musics.add(name);
            }
          }
        }
        else
        {
          musics = new ArrayList<String>();
          File f = new File(MAIN_FOLDER);
          FilenameFilter mp3Only = new FilenameFilter() {
          public boolean accept(File dir, String name) {
            return name.toLowerCase().endsWith(".mp3");
          }};
          if (f.isDirectory()) {
            File[] files = f.listFiles(mp3Only);
            for(File file: files)
            {
               String name = file.getName().substring(0,file.getName().length()-4);
               File patternFile = new File(MAIN_FOLDER + "/" + name + ".json");
               
               if(patternFile.exists())
               {
                 println(name);
                 musics.add(name);
               }
            }
          }
        }
      }
  }
  else if(step==GameStep.ChooseMusic)
  {
    if(musics.size()>0)
    {
       if(keyCode==DOWN)
       {
          currentMusic = (currentMusic+1) % musics.size();
       }
       if(keyCode==UP)
       {
          currentMusic = (currentMusic-1 +musics.size()) % musics.size();
       }
       if(keyCode==ENTER)
       {
           text("Loading...",50,50,WIDTH, HEIGHT);
           StartGame(musics.get(currentMusic));
       }
    }
  }
  else if(step==GameStep.Game)
  {
    //In saving mode, we add blocks when the buttons are pressed
    if(mode==GameMode.Saving)
    {
      if (key=='o' || key=='O'||keyCode==UP)
      {
        pattern.Add(BlockType.RightUp, millis()-startTime);
        blocks.add(new Block(BlockType.RightUp));
        
      } 
      if (key=='m' || key=='M'||key==';' ||keyCode==RIGHT)
      {
        pattern.Add(BlockType.Right, millis()-startTime);
        blocks.add(new Block(BlockType.Right));
      }
      if (key=='l' || key=='L'||keyCode==DOWN)
      {
        pattern.Add(BlockType.RightDown, millis()-startTime);
        blocks.add(new Block(BlockType.RightDown));
      }
      if (key=='z' || key=='Z'|| key=='w' || key=='W')
      {
        pattern.Add(BlockType.LeftUp, millis()-startTime);
        blocks.add(new Block(BlockType.LeftUp));
      } 
      if (key=='q' || key=='Q'|| key=='a' || key=='A')
      {
        pattern.Add(BlockType.Left, millis()-startTime);
        blocks.add(new Block(BlockType.Left));
      }
      if (key=='s' || key=='S')
      {
        pattern.Add(BlockType.LeftDown, millis()-startTime);
        blocks.add(new Block(BlockType.LeftDown));
      }
      if(keyCode==LEFT)
      {
        Rewind(100);
      }
      if (key=='g' || key=='G')
      {
        pattern.Serialize();
      }
    }
    
    //In playing mode, the blocks are destructed when the button is pressed at the right moment
    else if(mode==GameMode.Playing)
    {
      if (key=='o' || key=='O' ||keyCode==UP)
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
      if (key=='m' || key=='M'||key==';' ||keyCode==RIGHT)
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
      if (key=='l' || key=='L'||keyCode==DOWN)
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
      if (key=='z' || key=='Z' || key=='w' || key=='W')
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
      if (key=='q' || key=='Q' || key=='a' || key=='A')
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
  
}

void getAccelerometerValues()
{
  if(acc1!=null)
  {
      acc1.beginTransmission(0x68);
      
      acc1.write(0x3B);
      //acc1.endTransmission();// Wire.endTransmission(false); (arduino)
      byte[] in = acc1.read(14);
      
      acc_right_x = in[0]|in[1];//(in[0] & 0xff);
      acc_right_y = in[2]|in[3];//(in[1] & 0xff);
      if(acc2==null)
      {
        acc_left_x = acc_right_x;
        acc_left_x = acc_right_y;
      }
  }
  if(acc2 != null)
  {
      acc2.beginTransmission(0x68);
      acc2.write(0x3B);
      //acc2.endTransmission();// Wire.endTransmission(false); (arduino)
      byte[] in = acc2.read(14);
      
      acc_left_x = in[0]|in[1];
      acc_left_y = in[2]|in[3];
  }
}


void Rewind(int timeMs)
{
  print("a");
  startTime=min(startTime+timeMs,millis());
  //musicFile.pause();
  musicFile.jump((float)(millis()-startTime)/1000);
  
  
  //Move blocks
  
  for(int i=0;i<blocks.size();i++)
  {
     blocks.get(i).transform.z+=Z_SPEED*timeMs; 
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
  
   
  for(int i=0;i<pattern.spawns.size();i++)
  {
      if(pattern.spawns.get(i).time >=millis()-startTime - Z_SPEED * Z0*Z_HIT_RATIO)//&& pattern.spawns.get(i).time<=millis()-startTime+timeMs + Z_SPEED * Z0*Z_HIT_RATIO)
      {
         pattern.spawns.remove(i);
         i--;
      }
  }
        
  
  //Move lines
  for(int i=0;i<lines.size();i++)
  {
     lines.get(i).transform.z+=Z_SPEED*timeMs;
     if(lines.get(i).transform.z<0)
     {
        lines.get(i).enabled=false; 
     }
  }
  
  
}



  
  
