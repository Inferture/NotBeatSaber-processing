/**Creates a block*/

enum BlockType
{
  None,
  Right,
  RightUp,
  RightDown,
  Left,
  LeftUp,
  LeftDown
}
class Block extends GameObject
{
  boolean standing;
  boolean hittable=false;
  boolean hit=false;
  BlockType type;
  
  int block_width;
  int block_height;
  /**Draws the shape of the block as if it was in the origin, GameObject.display will place it correctly*/
   void Draw()
  {
      rect(-block_width/2,-block_height/2,block_width,block_height);
      //rect(0,0,100,100);
  }
  
  Block(boolean standing)
  {
    block_width=BLOCK_WIDTH;
    block_height=BLOCK_HEIGHT;
    this.standing=standing;
    transform = new Transform(WIDTH/2-block_width/2,HEIGHT/2-block_height/2,(int)Z0);
    enabled=true;
  }
  
  Block(int block_width, int block_height)
  {
    this.block_width=block_width;
    this.block_height=block_height;
    transform = new Transform(WIDTH/2-block_width/2,HEIGHT/2-block_height/2,(int)Z0);
    enabled=true;
  }
  
  Block(int x, int y, int block_width, int block_height)
  {
    this.block_width=block_width;
    this.block_height=block_height;
    transform = new Transform(x,y,(int)Z0);
    enabled=true;
  }
  Block(BlockType type)
  {
    this.type=type;
    if(type==BlockType.Right)
    {
      block_width = WIDTH/4;
      block_height=HEIGHT/2;
      transform = new Transform(WIDTH/2-block_width/2, 0, (int)Z0);
    }
    else if(type==BlockType.RightDown)
    {
      block_width = WIDTH/3;
      block_height=HEIGHT/4;
      transform = new Transform(WIDTH/4, HEIGHT/2-block_height/2, (int)Z0);
    }
    else if(type==BlockType.RightUp)
    {
      block_width = WIDTH/3;
      block_height=HEIGHT/4;
      transform = new Transform(WIDTH/4, -HEIGHT/2+block_height/2, (int)Z0);
    }
    else if(type==BlockType.Left)
    {
      block_width = WIDTH/4;
      block_height=HEIGHT/2;
      transform = new Transform(-WIDTH/2+block_width/2, 0, (int)Z0);
    }
    else if(type==BlockType.LeftDown)
    {
      block_width = WIDTH/3;
      block_height=HEIGHT/4;
      transform = new Transform(-WIDTH/4, HEIGHT/2-block_height/2, (int)Z0);
    }
    else //(BlockType.LeftUp)
    {
      block_width = WIDTH/3;
      block_height=HEIGHT/4;
      transform = new Transform(-WIDTH/4, -HEIGHT/2+block_height/2, (int)Z0);
    }
    enabled=true;
  }
}
