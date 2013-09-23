import app.api.Api;
import app.api.QueueApi;
import app.Config;
import app.view.CurrentVideoPanel;
import app.view.PanelList;
import bootstrap.Button;
import fontawesome.Icons;
import js.Browser;
import js.node.Fs;
import js.npm.Kue;
import js.npm.nodewebkit.App;
import js.npm.FFMpeg;
import haxe.Json;
using Detox;

class VoseApp
{
	public static var inst:VoseApp;

	static function main() {
		inst = new VoseApp();
	}

	public var config:Config;
	public var api:Api;

	public function new() {

		// use non-native trace
		haxe.Log.trace;

		api = new Api();

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

	var projectsPanel:PanelList;
	var videosPanel:PanelList;
	var currentVideoPanel:CurrentVideoPanel;

	var currentProject:String;
	var currentVideo:String;

	function run() {

		// Set up the panels
		projectsPanel = new PanelList( "Projects" );
		videosPanel = new PanelList( "Videos" );
		currentVideoPanel = new CurrentVideoPanel( "Current Video" );
		"#projects-panel".find().append( projectsPanel );
		"#videos-panel".find().append( videosPanel );
		"#current-video-panel".find().append( currentVideoPanel );

		videosPanel.hide();
		currentVideoPanel.hide();

		updateProjectsPanel();

		var newProjectBtn = new Button( "New Project", Icons.iconPlus(), Primary);
		newProjectBtn.click( function(e) newProject() ).appendTo( projectsPanel.buttons );

		var newProjectBtn = new Button( "New Video", Icons.iconPlus(), Primary);
		newProjectBtn.click( function(e) newVideo() ).appendTo( videosPanel.buttons );

		var newProjectBtn = new Button( "Rename Project", Icons.iconPlus(), Default);
		newProjectBtn.click( function(e) renameProject(currentProject) ).appendTo( videosPanel.buttons );

		var newProjectBtn = new Button( "Delete Project", Icons.iconPlus(), Default);
		newProjectBtn.click( function(e) deleteProject(currentProject) ).appendTo( videosPanel.buttons );

		currentVideoPanel.renameVideo.click( function(e) renameVideo(currentProject, currentVideo) );
		currentVideoPanel.deleteVideo.click( function(e) deleteVideo(currentProject, currentVideo) );

	}

	function updateProjectsPanel() {
		api.projectApi.allProjects().then( function(allProjects) {
			projectsPanel.items = [ for (p in allProjects.keys()) { icon: "icon-folder-open", name: p, badge: '${allProjects[p]}'  } ];

			for ( item in projectsPanel.itemLoop.getWidgetLoopItems() ) {
				if (currentProject==null) currentProject = item.input.name;
				item.widget.click( function(e) updateVideosPanel( item.input.name ) );
			}

			// open the current video
			if ( currentProject!=null )
				projectsPanel.find( '[data-id="$currentProject"]' ).click();
		});
	}

	function updateVideosPanel( project:String ) {
		currentProject = project;

		projectsPanel.find( '.active' ).removeClass( 'active' );
		projectsPanel.find( '[data-id="$project"]' ).addClass("active");

		videosPanel.itemLoop.empty();
		videosPanel.title = '$project Vids';

		videosPanel.show();

		api.projectApi.videosInProject( project ).then( function(videos) {
			videosPanel.items = [ for (v in videos.keys()) { icon: "icon-factime-video", name: v, badge: videos[v]  } ];
			for ( item in videosPanel.itemLoop.getWidgetLoopItems() ) {
				if (currentVideo==null) currentVideo = item.input.name;
				item.widget.click( function (e) updateCurrentVideoPanel(project, item.input.name) );
			}
			if ( currentVideo!=null )
				videosPanel.find( '[data-id="$currentVideo"]' ).click();
		});
	}

	function updateCurrentVideoPanel( project:String, video:String ) {
		currentProject = project;
		currentVideo = video;

		videosPanel.find( '.active' ).removeClass( 'active' );
		videosPanel.find( '[data-id="$currentVideo"]' ).addClass("active");

		currentVideoPanel.show();
		currentVideoPanel.title = 'Video: $project / $video';
	}

	function newProject() {
		var id = Browser.window.prompt( "Project Name", "PC301" );
		if (id!=null) {
			currentProject = id;
			api.projectApi.newProject( id )
			.then( function (_) updateProjectsPanel() )
			.error( function (e) alert('Failed to create new project: $e') );
		}
	}

	function renameProject( project:String ) {
		var newID = Browser.window.prompt( 'Rename $project to', project );
		if (newID!=null) {
			currentProject = newID;
			api.projectApi.renameProject( project, newID )
			.then( function (_) updateProjectsPanel() )
			.error( function (e) alert('Failed to rename project: $e') );
		}
	}

	function deleteProject( project:String ) {
		if ( Browser.window.confirm('Delete project $project?') ) {
			api.projectApi.deleteProject( project )
			.then( function (_) updateProjectsPanel() )
			.error( function (e) alert('Failed to delete project: $e') );
		}
	}

	function newVideo() {
		var id = Browser.window.prompt( "Video Name", "Week01" );
		if (id!=null) {
			currentVideo = id;
			api.projectApi.newVideo( currentProject, id )
			.then( function (_) updateProjectsPanel() )
			.error( function (e) alert('Failed to create new video: $e') );
		}
	}

	function renameVideo( project:String, video:String ) {
		var newID = Browser.window.prompt( 'Rename $video to', video );
		if (newID!=null) {
			currentVideo = newID;
			api.projectApi.renameVideo( project, video, newID )
			.then( function (_) updateVideosPanel(project) )
			.error( function (e) alert('Failed to rename video: $e') );
		}
	}

	function deleteVideo( project:String, video:String ) {
		if ( Browser.window.confirm('Delete project $project / $video?') ) {
			api.projectApi.deleteVideo( project, video )
			.then( function (_) updateVideosPanel(project) )
			.error( function (e) alert('Failed to delete video: $e') );
		}
	}

	function alert( e:Dynamic ) {
		trace ( e );
		js.Lib.alert( e );
	}
}