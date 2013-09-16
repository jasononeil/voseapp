import vidproject.commands.*;
import Sys.println;
import sys.FileSystem;
import vidproject.commands.Render;
using StringTools;
using Lambda;

class CommandLine
{
	static var args:Array<String>;
	static function main()
	{
		println ("Welcome to the Vose command line");

		args = Sys.args();

		if (args.length == 0)
		{
			usage();
		}
		else 
		{
			var command = args.shift();
			switch (command)
			{
				case "setup":
					setup();
				case "export":
					export();
				default: 
					println ('Unknown Command: $command');
					usage();
			}
		}

	}

	static function usage()
	{
		println("Usage:");
		println("  neko commandline.n setup ...");
		println("  neko commandline.n export ...");
	}

	static function setup()
	{
		if (args.length != 3)
		{
			println("Usage:");
			println("  neko commandline.n setup {pathToUnit} {weekName} {pathToClips}");
			println("Example:");
			println("  neko commandline.n setup /media/vosedrive/PC301/ Week01 /media/sdcard1/clips/");
		}
		else 
		{
			var unitPath = args[0];
			var projectName = args[1];
			var clipsDir = args[2];

			if (!FileSystem.exists(clipsDir) || !FileSystem.isDirectory(clipsDir)) throw "Not a valid Clips directory";

			var clips = [];
			for (f in FileSystem.readDirectory(clipsDir))
			{
				if (clipsDir.endsWith("/") == false) clipsDir = clipsDir + "/";
				clips.push(clipsDir + f);
			}

			new SetupProject(unitPath, projectName, clips).run();
		}
	}

	static function export()
	{
		if (args.length != 2)
		{
			println("Usage:");
			println("  neko commandline.n export {pathToWeek} {profile}");
			println("Example:");
			println("  neko commandline.n export /media/vosedrive/PC301/Week01/Week01.kdenlive mp3");
			println("  neko commandline.n export /media/vosedrive/PC301/Week01/Week01.kdenlive dvd");
		}
		else 
		{
			var path = args[0];
			var profile = args[1].toUpperCase();

			if (FileSystem.exists(path) && path.endsWith(".kdenlive"))
			{
				var validTypes = Type.getEnumConstructs(RenderType);
				if (validTypes.has(profile))
				{
					var renderType = Type.createEnum(RenderType, profile);
					new Render(path, renderType);
				}
				else 
				{
					println('Profile not found: $profile');
					println('Valid profiles are: ');
					for (p in validTypes)
					{
						println('  $p');
					}
				}
			}
			else 
			{
				println('Kdenlive project not found: $path');
			}
		}
	}
}