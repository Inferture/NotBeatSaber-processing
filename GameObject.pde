

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
     /*
     translate(
     transform.x *(1-ratio) + 
     transform.x *((float)HORIZON_WIDTH/(float)WIDTH)*(ratio), 
     transform.y *(1-ratio) + 
     transform.y *((float)HORIZON_HEIGHT/(float)HEIGHT)*(ratio)
     );
     */
     
     translate(
     sgnx*pow(tx,(1-ratio)) * 
     pow(tx*SCALE_HORIZON, (ratio)), 
     sgny*pow(ty ,(1-ratio))* 
     pow(ty*SCALE_HORIZON ,(ratio))
     );
     
     rotate(transform.rot);
     /*
     scale(transform.scaleX *(ratio*SCALE_HORIZON + (1-ratio)), 
     transform.scaleY*(ratio*SCALE_HORIZON + (1-ratio)));
     */
     /*
     scale(transform.scaleX *(ratio*SCALE_HORIZON), 
     transform.scaleY*(ratio*SCALE_HORIZON));
     */
     /*
     //kewl effects
     scale(
     transform.scaleX *(pow(SCALE_HORIZON,1-ratio)), 
     transform.scaleY *(pow(SCALE_HORIZON,1-ratio)));
     */
     scale(
     transform.scaleX *(pow(SCALE_HORIZON,ratio)), 
     transform.scaleY *(pow(SCALE_HORIZON,ratio)));
     Draw();
     popMatrix();
    }    
  }
  
  /**Should be overwritten*/
  void Draw()
  {
  }
  
}
