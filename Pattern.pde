
import java.io.*;

static class Pattern implements Serializable 
{
  /*Speed ?*/
  /*Beat ? To associate with speed to get line frequency*/
  
  String name;
  
  ArrayList<BlockSpawn> spawns;
  
  Pattern(String name)
  {
    this.name=name;
    spawns= new ArrayList<BlockSpawn>();
  }
  
  void Add(BlockType type, int time)
  {
    spawns.add(new BlockSpawn(type, time));
  }
  void Add(BlockSpawn spawn)
  {
    spawns.add(spawn);
  }
  
  void Serialize()
  {
    try
    {
      FileOutputStream patternFile=new FileOutputStream(MAIN_FOLDER+"/"+name+".pattern",false);
      ObjectOutputStream o=new ObjectOutputStream(patternFile);
      o.writeObject(this);
      o.close(); 
    }
    catch(IOException e)
    {
      print("problem when trying to open "+name + " :" + e.toString());
    }
  }
  
  static Pattern Deserialize(String name)
  {
     try
      {
        FileInputStream patternFile=new FileInputStream(MAIN_FOLDER+"/"+name +".pattern");
        ObjectInputStream o=new ObjectInputStream(patternFile);
        Pattern pattern = (Pattern)o.readObject();
        
        o.close(); 
        
        return pattern;
      }
    catch(IOException e)
    {
      print("problem when trying to open "+"dd" + " :" + e.toString());
    }
    catch(ClassNotFoundException e)
    {
       print("problem when trying to read class pattern "+"dd" + " :" + e.toString());
    }
    return null;
  }
}

static  class BlockSpawn implements Serializable
{
   BlockType type;
   int time;
   
   BlockSpawn(BlockType type, int time)
   {
      this.type=type;
      this.time=time;
   }
}
