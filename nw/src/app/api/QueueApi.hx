package app.api;

import js.npm.FFMpeg;
import js.npm.Kue;
import js.npm.Kue.Queue;
import js.support.Callback in NodeCallback;
import js.node.ChildProcess;
using haxe.io.Path;
using tink.CoreApi;

class QueueApi
{
	var queue:Queue;
	var config(get,null):Config;
	var futures:Map<String,Map<Int,FutureTrigger<Outcome<Noise,String>>>>;
	
	public function new() {
		futures = new Map();
		queue = Kue.createQueue();
		addCommand( "ConvertToMP4", processConvertToMP4 );
	}

	function addCommand( name:String, cb:Job->NodeCallback<String>->Void ) {
		if ( futures.exists(name)==false ) {
			queue.process( name, cb );
			trace ("ADDING A NEW COMMAND");
			futures[name] = new Map();
		}
	}

	static var numConvertJobs:Int = 0;

	public function convertToMP4( inFile:String, currentProject:String, currentVideo:String ) {
		var name = inFile.withoutDirectory().withoutExtension();
		var outFile = '${config.projectFolders[0]}$currentProject/$currentVideo/RawFootage/$name.MP4';
		
		var id = numConvertJobs++;
		var f = Future.trigger();
		futures["ConvertToMP4"][id] = f;

		var data = {
			convertID: id,
			inFile: inFile,
			outFile: outFile,
			title: 'Import $name into $currentProject/$currentVideo'
		}

		var job = queue.create( "ConvertToMP4", data );
		job.save();

		return f.asFuture();
	}

	function processConvertToMP4( job:Job, done:NodeCallback<String> ) {
		var inFile:String = job.data.inFile;
		var outFile:String = job.data.outFile;
		var cmd = 'gnome-terminal -e "mencoder $inFile -demuxer lavf -oac copy -ovc copy -of lavf=mp4 -o $outFile"';
		return execute( cmd, false, done, futures["ConvertToMP4"][job.data.convertID] );
	}

	function get_config() {
		return VoseApp.inst.config;
	}

	function execute( cmd:String, ?ignoreStderr=false, done:NodeCallback<String>, ft:FutureTrigger<Outcome<Noise,String>> ) {
		trace ( 'About to execute this command:' );
		trace ( '  $cmd' );
		ChildProcess.exec( cmd, {}, function (err,stdout,stderr) {
			if ( stderr!="" && ignoreStderr==false ) {
				var err = 'STDOUT: $stdout\n\nSTDERR: $stderr';
				ft.trigger( Failure(err) );
				done(err, null);
			}
			else {
				ft.trigger( Success(Noise) );
				done(null, "Completed.");
			}
		});
	}
}