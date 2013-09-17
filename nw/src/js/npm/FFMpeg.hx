package js.npm;

import js.node.stream.Writable;

extern class FFMpeg implements npm.Package.Require<"fluent-ffmpeg","*"> {

	inline static public function getMetadata( file:String, cb:Metadata->String->Void ):Void {
		Type.createInstance( FFMpeg.Metadata, [ file, cb ] );
	}
	
	static var Metadata:Class<MetaLib>;

	public function new( params:ConstructorParams ) {}
	
	public function withNoVideo():FFMpeg;
	
	public function withNoAudio():FFMpeg;
	
	public function updateFlvMetadata():FFMpeg;

	/** eg '4:3' **/
	public function withAspect( aspect:String ):FFMpeg;

	public function keepPixelAspect( bool:Bool ):FFMpeg;

	public function loop( duration:String ):FFMpeg;

	public function takeFrames( frameCount:Int ):FFMpeg;

	/** eg '640x480' **/
	public function withSize( size:String ):FFMpeg;
	
	/** eg true, 'white' **/
	public function applyAutoPadding( apply:Bool, color:String ):FFMpeg;
	
	/** eg 'podcast' **/
	public function usingPreset( preset:String ):FFMpeg;
	
	/** eg 1024 **/
	public function withVideoBitrate( bitrate:Int ):FFMpeg;
	
	/** eg 'divx' **/
	public function withVideoCodec( preset:String ):FFMpeg;
	
	/** eg 24 **/
	public function withFps( fps:Int ):FFMpeg;
	
	/** eg 24 **/
	public function withFpsInput( fps:Int ):FFMpeg;
	
	/** eg 24 **/
	public function withFpsOutput( fps:Int ):FFMpeg;
	
	/** eg '128k' **/
	public function withAudioBitrate( bitrate:String ):FFMpeg;
	
	/** eg 'libmp3lame' **/
	public function withAudioCodec( codec:String ):FFMpeg;
	
	/** eg 2 **/
	public function withAudioChannels( channels:Int ):FFMpeg;
	
	public function withAudioQuality( quality:Int ):FFMpeg; // maybe should be string?

	public function setStartTime( timestamp:String ):FFMpeg; 
	public function setDuration( duration:String ):FFMpeg; 

	public function withAudioFrequency( frequency:String ):FFMpeg;
	
	/** eg '-vtag', 'DIVX' **/
	public function addOption( name:String, value:String ):FFMpeg;
	
	/** eg ['-vtag DIVX', '-debug'] **/
	public function addOptions( options:Array<String> ):FFMpeg;

	/** eg 'myfile.mp3' **/
	public function addInput( filename:String ):FFMpeg;

	/** eg 'myfile.mp3' **/
	public function mergeAdd( filename:String ):FFMpeg;

	/** Return callback contains stdout as first argument, stderr as second **/
	public function mergeToFile( path:String, cb:Void->Void ):FFMpeg;
	
	/** eg 'avi' **/
	public function fromFormat( format:String ):FFMpeg;
	
	/** eg 'avi' **/
	public function toFormat( format:String ):FFMpeg;
	
	/** -20 (high priority) to 19 (low priority).  Default is 0 **/
	public function renice( priority:Int ):FFMpeg;

	public function onCodecData( cb:CodecData->Void ):FFMpeg;

	/** See `ProgressUpdate` for details.  Will post as often as FFMPEG gives output **/
	public function onProgress( cb:ProgressUpdate->Void ):FFMpeg;
	
	/**
		First format: number of thumbnails, spread evenly, saved to folder, with callback.

		Second format: config object defining specific points, saved to folder, with callback

		Callback is function(error:String, filenames:Array<String>):Void

		See https://github.com/schaermu/node-fluent-ffmpeg#creating-thumbnails-from-a-video-file
	**/
	@:overload( function( options:TakeScreenshotParams, pathToThumbnailFolder:String, cb:String->Array<String>->Void ):FFMpeg {} )
	public function takeScreenshots( number:Int, pathToThumbnailFolder:String, cb:String->Array<String>->Void ):FFMpeg;
	
	/** Return callback contains stdout as first argument, stderr as second **/
	public function saveToFile( path:String, tmpFolder:String, cb:Void->Void ):FFMpeg;
}


typedef ConstructorParams = {
	/** input source, required **/
	source:String,
	/** timout of the spawned ffmpeg sub-processes in seconds **/
	?timeout:Int,
	/** default priority for all ffmpeg sub-processes (optional, defaults to 0 which is no priorization) **/
	?priority:Int,
	/** set a custom [winston](https://github.com/flatiron/winston) logging instance (optional, default null which will cause fluent-ffmpeg to spawn a winston console logger) **/
	?logger:Null<Dynamic>,
	/** completely disable logging (optional, defaults to false) **/
	?nolog:Bool,
}

typedef TakeScreenshotParams = {
	count:Int,
	timemarks: Array<String>,
	?filename:String
}

typedef ProgressUpdate = {
	frames:Int,
	currentFps:Int,
	currentKbps:Int,
	targetSize:Int,
	timemark:String
}

/** Not implemented yet **/
typedef CodecData = {

}

extern class MetaLib {
	/**
		@param file:  path to file
		@param cb:    Callback function(meta:Metadata, error:String):Void
	**/
	function new( file:String, cb:Metadata->String->Void );
}

/** Not implemented yet **/
typedef Metadata = {
	album:String,
	artist:String,
	audio: {
		bitrate:Int,
		channels:Int,
		codec:String,
		sample_rate:Int,
		stream:Float
	},
	date:String,
	durationraw:String,
	durationsec:Int,
	ffmpegversion:String,
	major_brand:Null<String>,
	synched:Bool,
	title:String,
	track:String,
	video: {
		aspect:Float,
		aspectString:String,
		bitrate:Int,
		codec:String,
		container:String,
		fps:Int,
		pixel:Float,
		pixelString:String,
		resolution: {
			w:Int,
			h:Int
		},
		resolutionSquare: {
			w:Int,
			h:Int
		}
	}
}