package app.api;
import app.Config;
import haxe.EnumFlags;
import js.node.ChildProcess;
import js.node.Fs;
import tink.CoreApi;
using StringTools;

class ProjectApi
{
	
	public function new() {}

	var config(get,null):Config;
	function get_config() {
		return VoseApp.inst.config;
	}

	/**
		Return a map of all projects, and the number of videos inside that project
	**/
	public function allProjects():Surprise<Map<String,Int>,String> {
		var mapTrigger = Future.trigger();
		var map = new Map();

		Fs.readdir( config.projectFolders[0], function (err,files) {
			if (err!=null) mapTrigger.trigger( Failure(err) );
			
			var allFutures:Array<Future<Dynamic>> = [];
			for ( file in files ) {
				var p = Future.trigger();
				allFutures.push( p );
				var path = config.projectFolders[0] + '$file/';
				Fs.readdir( path, function(err,subFiles) {
					if (err==null) {
						subFiles = subFiles.filter( function(sf) return Fs.lstatSync('$path/$sf').isDirectory() );
						map[file] = subFiles.length; 
						p.trigger( Success(null) );
					}
					else p.trigger( Failure(null) );
				});
			}
			var allFuturesPromise:Future<Array<Dynamic>> = allFutures; // Future.fromMany cast
			allFuturesPromise.handle( function( _ ) {
				mapTrigger.trigger( Success(map) );
			});
		});

		return mapTrigger;
	}

	public function videosInProject( project:String ):Surprise<Map<String,String>,String> {
		var t = Future.trigger();
		var map = new Map();

		var config = VoseApp.inst.config;
		var projectPath = config.projectFolders[0] + '$project/';
		Fs.readdir( projectPath, function (err,files) {
			if (err!=null) 
				t.trigger( Failure(err) );
			for ( file in files ) 
				if ( Fs.lstatSync('$projectPath/$file').isDirectory() )
					map[file] = "Edit";
			t.trigger( Success(map) );
		});

		return t;
	}

	public function newProject( id:String ) {
		return execute( 'mkdir "${config.projectFolders[0]}$id"' );
	}

	public function renameProject( oldID:String, newID:String ) {
		trace ('mv ${config.projectFolders[0]}$oldID ${config.projectFolders[0]}$newID');
		return execute( 'mv "${config.projectFolders[0]}$oldID" "${config.projectFolders[0]}$newID"' );
	}

	public function deleteProject( id:String ) {
		return execute( 'rmdir "${config.projectFolders[0]}$id"' );
	}

	public function newVideo( project:String, id:String ):Surprise<Noise,Array<String>> {
		var vid = '${config.projectFolders[0]}$project/$id';
		var p1 = execute( 'mkdir -p "$vid"' );
		var p2 = execute( 'mkdir -p "$vid/RawFootage/"' );
		var p3 = execute( 'mkdir -p "$vid/Kdenlive/"' );
		var p4 = execute( 'mkdir -p "$vid/Kdenlive/Proxies"' );
		var p5 = execute( 'mkdir -p "$vid/Exports/"' );
		var p6 = execute( 'mkdir -p "$vid/Exports/MP3"' );
		var p7 = execute( 'mkdir -p "$vid/Exports/MP4"' );
		var p8 = execute( 'mkdir -p "$vid/Exports/VOB"' );

		var p:Future<Array<Outcome<Noise,String>>> = [p1, p2, p3, p4, p5, p6, p7, p8];
		return p.map( function(arr) {
			var errors = [];
			for ( f in arr ) 
				switch f {
					case Failure(data): errors.push(data);
					default:
				}
			
			return 
				if ( errors.length>0 ) Failure(errors);
				else Success(Noise);
		});
	}

	public function renameVideo( project:String, oldID:String, newID:String ) {
		return execute( 'mv "${config.projectFolders[0]}$project/$oldID" "${config.projectFolders[0]}$project/$newID"' );
	}

	public function deleteVideo( project:String, id:String ) {
		return execute( 'rm -rf "${config.projectFolders[0]}$project/$id"' );
	}

	public function getClipsInVideo( project:String, id:String ):Surprise<Array<String>,String> {
		var t = Future.trigger();
		var arr = [];

		var config = VoseApp.inst.config;
		var rawFootagePath = config.projectFolders[0] + '$project/$id/RawFootage';
		Fs.readdir( rawFootagePath, function (err,files) {
			if (err!=null) 
				t.trigger( Failure('$err') );
			else {
				for ( file in files ) 
					arr.push(file);
				t.trigger( Success(arr) );
			}
		});

		return t.asFuture();
	}

	public function getVideoStatus( project:String, id:String ):Future<EnumFlags<VideoStatus>> {
		var basePath = config.projectFolders[0] + '$project/$id';

		var flags = new EnumFlags<VideoStatus>();
		var allFutures = [];

		function check( path:String, en:VideoStatus ) {
			var f = path.endsWith("/") ? folderContainsFiles( path ) : fileExists( path );
			f = f.map( function(b) { 
				if (b) flags.set( en ); 
				return b;
			});
			allFutures.push( f );
		}

		check( '$basePath/', Exists );
		check( '$basePath/RawFootage/', ClipsCopied );
		check( '$basePath/$id.kdenlive', KdenliveCreated );
		check( '$basePath/Exports/MP3/', MP3Rendered );
		check( '$basePath/Exports/MP4/', MP4Rendered );
		check( '$basePath/Exports/VOB/', VobRendered );
		check( '$basePath/$id.dvds', DvdStylerCreated );
		check( '$basePath/$id.iso', IsoCreated );

		return Future.ofMany( allFutures ).map( function(_) return flags );
	}

	public function editInKdenlive( project:String, id:String ) {
		var filePath = config.projectFolders[0] + '$project/$id/$id.kdenlive';
		
		var done = 
			fileExists( filePath )
			.flatMap(function ( exists:Bool ) {
				trace ('exists? $exists');
				if ( !exists ) return createKdenliveProject( project, id );
				else return Future.sync( Noise );
			})
			.flatMap( function (_) return execute('kdenlive $filePath') )
		;

		done.handle( function (surprise) trace('okay') );

		return done;
	}

	function execute( cmd:String ):Surprise<Noise,String> {
		var t = Future.trigger();
		ChildProcess.exec( cmd, {}, function (err,stdout,stderr) {
			if (stderr!="") t.trigger( Failure(stderr) );
			t.trigger( Success(null) );
		});
		return t;
	}

	function fileExists( path:String ):Future<Bool> {
		trace ('File exists?: $path');
		return Future.async( Fs.exists.bind(path) );
	}

	function folderContainsFiles( path:String ):Future<Bool> {
		return Future.async( function (cb) {
			Fs.readdir( path, function (err,files) {
				if (err!=null) cb( false );
				else cb( files.length>0 );
			});
		});
	}

	function createKdenliveProject( project:String, id:String ) {
		var footagePath = config.projectFolders[0] + '$project/$id/RawFootage/';
		var filePath = config.projectFolders[0] + '$project/$id/$id.kdenlive';

		js.Lib.alert( 'in here' );

		var kdenliveProject = CompileTime.readXmlFile( 'app/templates/kdenlive/ProjectWithDefaults.kdenlive.sample' );
		Fs.writeFileSync( filePath, kdenliveProject );
		return Future.sync( Noise );
	}

}

enum VideoStatus {
	Exists;
	ClipsCopied;
	KdenliveCreated;
	MP3Rendered;
	MP4Rendered;
	VobRendered;
	DvdStylerCreated;
	IsoCreated;
}