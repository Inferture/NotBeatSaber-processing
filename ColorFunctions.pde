/**Generates a random color for the road (not too dark, not too bright)*/
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

/**RGB inversion*/
color RGBtoGBR(color origin)
{
  return color(green(origin), blue(origin), red(origin));
}
/**intensify or attenuates a color with a float f*/
color MultiplyColor(color c, float f)
{
   return color(red(c)*f, green(c)*f, blue(c)*f); 
}
/**Returns the negative color of c*/
color Negative(color c)
{
   return color(256-red(c), 256-green(c), 256-blue(c)); 
}
