
import java.io.*;

Pattern Deserialize(String name)
  {
     try
      {
        
        /*
        //JAVA Serial
        FileInputStream patternFile=new FileInputStream(MAIN_FOLDER+"/"+name +".pattern");
        ObjectInputStream o=new ObjectInputStream(patternFile);
        Pattern pattern = (Pattern)o.readObject();
        
        o.close(); 
        
        return pattern;
        */
        
        //JSON Serial
        JSONObject json = loadJSONObject(MAIN_FOLDER+"/"+name +".json");
        String jsonName = json.getString("name");
        
        
        Pattern pattern = new Pattern(jsonName);
        
        JSONArray values = json.getJSONArray("spawns");
        for (int i = 0; i < values.size(); i++) 
        {
          JSONObject value = values.getJSONObject(i);
          int time = value.getInt("time");
          BlockType type = GetValueType(value.getInt("type"));
          pattern.Add(type,time);
        }
        return pattern;
        
      }
    catch(Exception e)
    {
      print("problem when trying to open "+"dd" + " :" + e.toString());
    }
   /* catch(ClassNotFoundException e)
    {
       print("problem when trying to read class pattern "+"dd" + " :" + e.toString());
    }*/
    return null;
  }
  
class Pattern//static class Pattern implements Serializable 
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
      //Java serial
     /* FileOutputStream patternFile=new FileOutputStream(MAIN_FOLDER+"/"+name+".pattern",false);
      ObjectOutputStream o=new ObjectOutputStream(patternFile);
      o.writeObject(this);
      o.close(); */
      
      //JSON Serial
      
      JSONObject json = new JSONObject();
      
      JSONArray jsonSpawns = new JSONArray();

    for (int i = 0; i < spawns.size(); i++) 
    {
        BlockSpawn spawn = spawns.get(i);
        JSONObject jsonSpawn = new JSONObject();
        jsonSpawn.setInt("time", spawn.time);
        jsonSpawn.setInt("type", GetTypeValue(spawn.type));
        jsonSpawns.setJSONObject(i, jsonSpawn);
    }
    
    json.setString("name", name);
    json.setJSONArray("spawns", jsonSpawns);
      
    
    saveJSONObject(json, MAIN_FOLDER+"/"+name+".json");
    
    }
    catch(Exception e)
    {
      print("problem when trying to open "+name + " :" + e.toString());
    }
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
