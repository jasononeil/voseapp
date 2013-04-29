package vidproject.commands;

import sys.FileSystem;
import Sys.println;
import templates.kdenlive.KdenliveProducer;
import templates.kdenlive.ProjectWithDefaults;

using StringTools;

class SetupProject 
{
	var parentFolder:String;
	var projectName:String;
	var projectFolder:String;
	var importClips:Array<String>;
	var projectClips:Array<String>;
	var proxyClips:Array<String>;

	var proxyParams = "-f mpegts -acodec libmp3lame -ac 2 -ab 128k -ar 48000 -vcodec mpeg2video -g 5 -deinterlace -s 720x576 -vb 800k";

	public function new(parentFolder:String, projectName:String, importClips:Array<String>)
	{
		// Sanitise the input

		if (!parentFolder.endsWith("/")) parentFolder += "/";
		if (projectName.endsWith("/")) projectName = projectName.substr(0, projectName.length - 1);
		if (importClips == null) importClips = [];

		// Set as member variables

		this.parentFolder = parentFolder;
		this.projectName = projectName;
		this.projectFolder = parentFolder + projectName + "/";
		this.importClips = importClips;
		this.projectClips = [];
		this.proxyClips = [];
	}

	public function run()
	{
		createFolderStructure();
		copyVideosToMP4();
		createProxyClips();
		createKdenliveTemplate();
	}

	function createFolderStructure()
	{
		if (FileSystem.exists(parentFolder) == false) throw "Parent Folder does not exist";

		if (FileSystem.exists(projectFolder) == false) FileSystem.createDirectory(projectFolder);

		var foldersToCreate = [
			"RawFootage",
			"Kdenlive",
			"Kdenlive/ladspa",
			"Kdenlive/proxy",
			"Kdenlive/thumbs",
			"Kdenlive/titles",
			"Exports",
			"Exports/MP3",
			"Exports/MP4",
			"Exports/VOB",
			"Exports/ISO"
		];

		for (f in foldersToCreate)
		{
			var n = projectFolder + f;
			if (FileSystem.exists(n) == false)
			{
				println('Creating folder $n');
				FileSystem.createDirectory(n);
			}
			else 
			{
				println('Folder already exists: $n');
			}
		}
	}

	function copyVideosToMP4()
	{
		for (v in importClips)
		{
			copyVideoToMP4(v);
		}
	}

	function copyVideoToMP4(oldFilePath:String)
	{
		if (FileSystem.exists(oldFilePath) == false) throw 'Could not find video: $oldFilePath';

		var oldFileName = oldFilePath.split("/").pop();
		var oldFileNameWithoutExtension = oldFileName.split(".").shift();
		var newName = oldFileNameWithoutExtension + ".MP4";
		var newPath = projectFolder + "RawFootage/" + newName;
		

		if (FileSystem.exists(newPath) == false)
		{
			var mencoderArgs = '$oldFilePath -demuxer lavf -oac copy -ovc copy -of lavf=mp4 -o $newPath'.split(' ');
			
			println('Running Command: ');
			println('  mencoder ${mencoderArgs.join(" ")}');

			var result = Sys.command("mencoder", mencoderArgs);

			if (result != 0) throw 'Mencoder returned a bad result on clip $newName...  Please check the clip before continuing';
			else println("Command was a success");
		}
		else 
		{
			println('Using existing clip: $newPath');
		}

		projectClips.push(newPath);
	}

	function createProxyClips()
	{
		for (v in projectClips)
		{
			createProxyClip(v);
		}
	}

	function createProxyClip(clipPath)
	{
		var clipFileName = clipPath.split("/").pop();
		var clipFileNameWithoutExtension = clipFileName.split(".").shift();
		var proxyName = clipFileNameWithoutExtension + ".TS";
		var proxyPath = projectFolder + "Kdenlive/proxy/" + proxyName;
		proxyClips.push(proxyPath);
		
		if (FileSystem.exists(proxyPath) == false)
		{
			var avconvArgs = '-i $clipPath $proxyParams $proxyPath'.split(' ');
			
			println('Running Command: ');
			println('  avconv ${avconvArgs.join(" ")}');

			var result = Sys.command("avconv", avconvArgs);

			if (result != 0) throw 'AVCONV returned a bad result on clip $proxyName...  Please check the clip before continuing';
			else println("Creating proxy clip with AVCONV was a success");
		}
		else 
		{
			println('Using existing proxy: $proxyPath');
		}		
	}

	function createKdenliveTemplate()
	{
		var projectXml = new ProjectWithDefaults(projectFolder);
		
		var i = 0;
		for (i in 0...projectClips.length)
		{
			println(' ${projectClips[i]} ${proxyClips[i]}');

			var p = new KdenliveProducer();
			p.clipName;
			p.clipPath;
			p.proxyPath;
			p.fileSize;
			p.fileHash;
			p.id;
			p.duration;
		}
	}
}