# NotBeatSaber
A rythm game made in processing where you will use accelerometers to play.

In order to work, the files should be in a "NotBeatSaber" folder (NotBeatSaber/NotBeatSaber.pde ...")

## Menu
You can navigate in the menu using the arrows and the enter key.

## Playing:
This game is made to play an existing map.

For this, the String music must reference a valid .mp3 and a valid .pattern in the data folder.

For example, if **music = "MeltyBlood"**, there must be a .mp3 **"MeltyBlood.mp3"** and a .pattern **"MeltyBlood.pattern"** 
in the data folder. 

If this is the case, the music and the pattern should begin when launching the game.

### Controls:

**Q** to destroy blocks at the right

**Z** to destroy blocks at the top right

**S** to destroy blocks at the bottom right

**M** to destroy blocks at the left

**O** to destroy blocks at the top left

**L** to destroy blocks at the bottom left

You can destroy blocks when they are between the 2 orange frames


## Saving:
This game is made to create a map.

For this, the String music must reference a valid .mp3 in the data folder.

For example, if **music = "MeltyBlood"**, there must be a .mp3 **"MeltyBlood.mp3"** in the data folder. 

If this is the case, the music should begin when launching the game.

### Controls:
**Q** to add a blocks at the right

**Z** to add a blocks at the top right

**S** to add a blocks at the bottom right

**M** to add a blocks at the left

**O** to add a blocks at the top left

**L** to add a blocks at the bottom left

**G** to save

**Left Arrow** to rewind

You should play the music with the beat (Press a button exactly on beat so that on Playing mode, 
the player should also play it on beat).
