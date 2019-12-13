

/**2D objects that should be drawn on the screen*/
class GameObject
{
  
  Transform transform;
  boolean enabled=true;
  
  
   /**Displays the GameObject on the screen, according to its transform*/
  void Display()
  {
    if(enabled)
    {
     pushMatrix();
     
     int tx = abs(transform.x);
     int ty = abs(transform.y);
     
     int sgnx=1;
     int sgny=1;
     if(transform.x<0)
     {
       sgnx=-1;
     }
     if(transform.y<0)
     {
       sgny=-1;
     }
     float ratio =transform.z/Z0;
     
     
     translate(
     sgnx*pow(tx,(1-ratio)) * 
     pow(tx*SCALE_HORIZON, (ratio)), 
     sgny*pow(ty ,(1-ratio))* 
     pow(ty*SCALE_HORIZON ,(ratio))
     );
     
     rotate(transform.rot);
     
     scale(
     transform.scaleX *(pow(SCALE_HORIZON,ratio)), 
     transform.scaleY *(pow(SCALE_HORIZON,ratio)));
     
     Draw();
     /*
     //kewl effects
     scale(
     transform.scaleX *(pow(SCALE_HORIZON,1-ratio)), 
     transform.scaleY *(pow(SCALE_HORIZON,1-ratio)));
     Draw();
     */
     
     popMatrix();
    }    
  }
  
  /**Should be overwritten*/
  void Draw()
  {
  }
  
}
