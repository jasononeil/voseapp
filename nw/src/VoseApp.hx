import app.api.QueueApi;
import app.Config;
import js.node.Fs;
import js.npm.Kue;
import js.npm.nodewebkit.App;
import js.npm.FFMpeg;
import haxe.Json;
using Detox;

class VoseApp
{
	static function main() {
		new VoseApp();
	}

	var config:Config;

	public function new() {

		var dataPath = App.dataPath[0];
		config = Json.parse( Fs.readFileSync('$dataPath/config.json') );
		
		Detox.ready( run );

		FFMpeg.getMetadata( "/home/jason/VoseProjects/camera/00006.MTS", function(meta,err) {
			if (err!=null) throw err;
			trace (meta.video.aspectString);
		} );

		setupKue();
	}

	function setupKue() {
		var queue = new QueueApi();

		queue.copyMultipleMTStoSingleMP4(
			[
				"/home/jason/VoseProjects/camera/00011.MTS",
				"/home/jason/VoseProjects/camera/00011.MTS",
			],
			"/home/jason/tmp/",
			"/home/jason/VoseProjects/joined.MP4"
		);

		var jobs = Kue.createQueue();
		Kue.app.listen( 3654 );
	}

	function run() {
		"#clickme".find().click(function(e) {

			Fs.readdir( config.projectFolders[0], function (err,files) {
				if (err!=null) throw err;
				for (f in files) {
					trace (f);
				}
				js.Lib.alert( files.join(", ") );
			});

		});
	}
}