

/**Creates a paddle*/

class Line extends GameObject
{
  
  
  int direction;//0:up, 1:left, 2:down, 3:right
  
  Line(int direction)
  {
    this.direction=direction ;
    if(direction==0)
    {
      transform = new Transform(0,-HEIGHT/2,(int)Z0);
    }
    if(direction==1)
    {
      transform = new Transform(-WIDTH/2,0,(int)Z0);
    }
    if(direction==2)
    {
      transform =new Transform(0,HEIGHT/2,(int)Z0);
    }
    if(direction==3)
    {
      transform = new Transform(WIDTH/2,0,(int)Z0);
    }
  }
  
  
  
  /**Draws the shape of the paddle in (0,0)*/
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
     //rect(-WIDTH/2,-5,WIDTH,10);
  }
  
  
  
 
  
  
}
