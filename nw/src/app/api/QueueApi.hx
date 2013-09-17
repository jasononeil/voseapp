package app.api;

import js.npm.FFMpeg;
import js.npm.Kue;
import js.npm.Kue.Queue;

class QueueApi
{
	var queue:Kue;
	public function new() {
		var queue = Kue.createQueue();
	}

	public function copyMultipleMTStoSingleMP4(inFiles:Array<String>, tmpFolder:String, outFile:String) {
		if (inFiles==null || inFiles.length==0) throw "At least one input file must be specified";
		if (tmpFolder==null) throw "Temporary Folder file must be specified";
		if (outFile==null) throw "Output file must be specified";

		var ffmpeg = new FFMpeg({
			source: inFiles.shift()
		});

		for (file in inFiles) {
			ffmpeg.mergeAdd( file );
		}

		ffmpeg.onProgress( function(p) {
			trace ('${p.frames} ${p.timemark}');
		});

		ffmpeg.mergeToFile( outFile, function () {
			trace ("Done");
		});
	}

}