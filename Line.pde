

/**Creates a paddle*/

class Line extends GameObject
{
  
  
  int direction;//0:up, 1:left, 2:down, 3:right
  
  Line(int direction)
  {
    
    this.direction=direction ;
    int z = (int)Z0;
    if(mode==GameMode.Saving)
    {
       z=(int)(Z_HIT_RATIO*Z0); 
    }
    if(direction==0)
    {
      transform = new Transform(0,-HEIGHT/2,z);
    }
    if(direction==1)
    {
      transform = new Transform(-WIDTH/2,0,z);
    }
    if(direction==2)
    {
      transform =new Transform(0,HEIGHT/2,z);
    }
    if(direction==3)
    {
      transform = new Transform(WIDTH/2,0,z);
    }
  }
  
  
  
  /**Draws the shape of the line in (0,0)*/
  void Draw()
  {
    
    if(direction%2==0)
    {
      line(-WIDTH/2,0,WIDTH/2,0);
    }
    else
    {
      line(0,-HEIGHT/2,0, HEIGHT/2);
      
    }
  }
  
  
  
 
  
  
}
