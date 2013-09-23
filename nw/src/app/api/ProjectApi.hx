package app.api;
import app.Config;
import js.node.ChildProcess;
import js.node.Fs;
import promhx.Promise;

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
	public function allProjects():Promise<Map<String,Int>> {
		var mapProm = new Promise();
		var map = new Map();

		Fs.readdir( config.projectFolders[0], function (err,files) {
			if (err!=null) mapProm.reject( err );
			
			var allPromises:Array<Promise<Null<Class<Void>>>> = [];
			for ( file in files ) {
				var p = new Promise();
				allPromises.push( p );
				Fs.readdir( config.projectFolders[0] + '$file/', function(err,subFiles) {
					if (err!=null) mapProm.reject( err );
					map[file] = subFiles.length; 
					p.resolve( null );
				});
			}
			Promise.when( allPromises ).then( function( _ ) {
				mapProm.resolve( map );
			});
		});

		return mapProm;
	}

	public function videosInProject( project:String ):Promise<Map<String,String>> {
		var p = new Promise();
		var map = new Map();

		var config = VoseApp.inst.config;
		Fs.readdir( config.projectFolders[0] + '$project/', function (err,files) {
			if (err!=null) p.reject( err );
			for ( file in files ) {
				map[file] = "Edit";
			}
			p.resolve( map );
		});

		return p;
	}

	public function newProject( id:String ):Promise<Null<Class<Void>>> {
		var p = new Promise();
		execute( 'mkdir ${config.projectFolders[0]}$id', p );
		return p;
	}

	public function renameProject( oldID:String, newID:String ) {
		var p = new Promise();
		execute( 'mv ${config.projectFolders[0]}$oldID ${config.projectFolders[0]}$newID', p );
		return p;
	}

	public function deleteProject( id:String ):Promise<Null<Class<Void>>> {
		var p = new Promise();
		execute( 'rmdir ${config.projectFolders[0]}$id', p );
		return p;
	}

	public function newVideo( project:String, id:String ):Promise<Null<Class<Void>>> {
		var p = new Promise();
		execute( 'mkdir ${config.projectFolders[0]}$project/$id', p );
		return p;
	}

	public function renameVideo( project:String, oldID:String, newID:String ) {
		var p = new Promise();
		execute( 'mv ${config.projectFolders[0]}$project/$oldID ${config.projectFolders[0]}$project/$newID', p );
		return p;
	}

	public function deleteVideo( project:String, id:String ) {
		var p = new Promise();
		execute( 'rm -rf ${config.projectFolders[0]}$project/$id', p );
		return p;
	}

	function execute( cmd:String, p:Promise<Null<Class<Void>>> ) {
		ChildProcess.exec( cmd, {}, function (err,stdout,stderr) {
			if (stderr!="") p.reject( stderr );
			p.resolve( null );
		});
	}
}