package vidproject.commands;

import sys.FileSystem;
import sys.io.File;
import templates.kdenlive.ProjectWithDefaults;
import vidproject.commands.Command;
import haxe.PosInfos;
using StringTools;
using haxe.io.Path;
using tink.core.types.Outcome;
using Detox;

class SetupProjectCommand extends Command
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
		super();

		// Sanitise the input

		parentFolder = parentFolder.addTrailingSlash();
		projectName = projectName.removeTrailingSlash();
		if (importClips == null) importClips = [];

		// Set as member variables

		this.parentFolder = parentFolder;
		this.projectName = projectName;
		this.projectFolder = parentFolder + projectName + "/";
		this.importClips = importClips;
		this.projectClips = [];
		this.proxyClips = [];

		updateStatus( SReady );
	}

	override public function execute()
	{
		updateStatus( SInProgress() );
		try {
			createFolderStructure();
			copyVideosToMP4();
			createProxyClips();
			createKdenliveTemplate();
			updateStatus( SCompleted );
			
		} catch (e:Dynamic) {
			var msg = 'Execution failed with error: $e';
			trace (msg);
			updateStatus( SError(msg) );
		}
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
				trace ('Creating folder $n');
				FileSystem.createDirectory(n);
			}
			else 
			{
				trace ('Folder already exists: $n');
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
			var mencoderArgs = '-demuxer lavf -oac copy -ovc copy -of lavf=mp4 -o'.split(' ');
			mencoderArgs.unshift(oldFilePath);
			mencoderArgs.push(newPath);
			
			trace ('Running Command: ');
			trace ('  mencoder ${mencoderArgs.join(" ")}');

			var result = Sys.command("mencoder", mencoderArgs);

			if (result != 0) throw 'Mencoder returned a bad result on clip $newName...  Please check the clip before continuing';
			else trace ("Command was a success");
		}
		else 
		{
			trace ('Using existing clip: $newPath');
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
			
			trace ('Running Command: ');
			trace ('  avconv ${avconvArgs.join(" ")}');

			var result = Sys.command("avconv", avconvArgs);

			if (result != 0) throw 'AVCONV returned a bad result on clip $proxyName...  Please check the clip before continuing';
			else trace ("Creating proxy clip with AVCONV was a success");
		}
		else 
		{
			trace ('Using existing proxy: $proxyPath');
		}		
	}

	function createKdenliveTemplate()
	{
		var projectXml = new ProjectWithDefaults();
		projectXml.projectFolder = projectFolder;
		
		var i = 0;
		var clips = [];
		for (i in 0...projectClips.length)
		{
			clips.push({
				clipName: projectClips[i].withoutDirectory().withoutExtension(),
				clipPath: projectClips[i],
				proxyPath: proxyClips[i],
				fileSize: FileSystem.stat( projectClips[i] ).size,
				fileHash: haxe.crypto.Md5.encode( projectClips[i] ),
				id: i+1,
				duration: -1
			});
		}
		projectXml.clips = clips;

		var filename = '$parentFolder$projectName/$projectName.kdenlive';
		File.saveContent( filename, projectXml.html() );
	}
}