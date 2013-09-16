package;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import ru.stablex.ui.UIBuilder;
import sys.FileSystem;
import vidproject.commands.RenderCommand;
import vidproject.commands.SetupProjectCommand;
using haxe.io.Path;

/**
* Basic Vose App
*/
class Main extends ru.stablex.ui.widgets.Widget{

    //callback to create alert popups
    static public var alert : Dynamic->ru.stablex.ui.widgets.Floating;


    /**
    * Enrty point
    *
    */
    static public function main () : Void{
        Lib.current.stage.align     = StageAlign.TOP_LEFT;
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

        //register main class to access it's methods and properties in xml
        UIBuilder.regClass('Main');
        UIBuilder.regClass('Zenity');

        //initialize StablexUI
        UIBuilder.init('ui/android/defaults.xml');

        //register skins
        UIBuilder.regSkins('ui/android/skins.xml');

        //create callback for alert popup
        Main.alert = UIBuilder.buildFn('ui/alert.xml');

        //Create our UI
        UIBuilder.buildFn('ui/index.xml')().show();
    }

    static var homeFolder = "/media/VoseDrive/";

    static public function newProject() {
        var name = Zenity.textInput("New Project", 'Name:');
        if ( createFolder(homeFolder, name) ) {
            Zenity.alert( "Done!" );
        }
    }

    static public function newVideo() {
        var project = pickProject();
        if ( project=="" ) {
            Zenity.alert ('You did not pick a project...');
        }
        else {
            var parentFolder = homeFolder.addTrailingSlash() + project.addTrailingSlash();
            var name = Zenity.textInput("New Video", 'Name:');
            if ( createFolder( parentFolder, name) ) {
                var files = Zenity.openMultiple("/media/");
                var cmd = new SetupProjectCommand( parentFolder, name, files );
                cmd.onStatusUpdate.add( function (s) {
                    switch (s) {
                        case SNotReady, SInvalid( _ ), SReady:
                        case SInProgress( completion ):
                            Zenity.alert( "Copying the video has begun... this might take a while.  You'll get another popup when it's done." );
                        case SCompleted:
                            Zenity.alert( "It's done!" );
                            var projectFile = parentFolder+name.addTrailingSlash()+name+".kdenlive";
                            doEdit( projectFile );
                        case SError( err ):
                            Zenity.alert( err );
                    }
                });
                cmd.execute();
            } else Zenity.alert( 'Failed to create folder for new video' );
        }
    }

    static public function test() {
        var project = "EM301";
        var parentFolder = homeFolder.addTrailingSlash() + project.addTrailingSlash();
        var name = "Week02";
        var files = ["/home/jason/VoseProjects/camera/00011.MTS"];
        var cmd = new SetupProjectCommand( parentFolder, name, files );
        cmd.onStatusUpdate.add( function (s) {
            switch (s) {
                case SNotReady, SInvalid( _ ), SReady:
                case SInProgress( completion ):
                    Zenity.alert( "Copying the video has begun... this might take a while.  You'll get another popup when it's done." );
                case SCompleted:
                    Zenity.alert( "It's done!" );
                    var projectFile = parentFolder+name.addTrailingSlash()+name+".kdenlive";
                    doEdit( projectFile );
                case SError( err ):
                    Zenity.alert( err );
            }
        });
        cmd.execute();
    }

    static public function edit() {
        var choice = pickProjectAndVideo();
        if (choice!=null) 
            doEdit( choice.path + choice.video + ".kdenlive" );
        else 
            Zenity.alert( 'No project/video selected' );
    }

    static function doEdit( projectFile:String ) {
        if ( FileSystem.exists(projectFile) ) {
            trace ( 'Open in Kdenlive: $projectFile' );
            var p = new sys.io.Process("kdenlive", [projectFile]);
        }
        else Zenity.alert( 'Failed to open kdenlive file $projectFile' );
    }

    static public function render() {
        var choice = pickProjectAndVideo();
        if (choice!=null) {
            var output = Zenity.pickItem("Output Type", ["MP4 (Vimeo)", "MP3", "DVD"]);
            switch (output) {
                case "": 
                    Zenity.alert( 'No output type selected' );
                default: 
                    Zenity.alert( 'Render ${choice.project} ${choice.video} $output' );
            }
        }
        else Zenity.alert( 'No project/video selected' );
    }

    static public function openFolder() {
        var choice = pickProjectAndVideo();
        if (choice!=null) {
            var p = new sys.io.Process("nautilus", [choice.path]);
        }
        else Zenity.alert( 'No project/video selected' );
    }

    static function createFolder( parentFolder:String, name:String ) {
        if ( name != "" ) {
            var dirToCreate = parentFolder.addTrailingSlash() + name;
            try {
                FileSystem.createDirectory( dirToCreate );
                return true;
            }
            catch ( e:Dynamic ) {
                Zenity.alert ( 'Error creating folder $dirToCreate: $e' );
                return false;
            }
        }
        else {
            Zenity.alert ('You did not enter a name...');
            return false;
        }
    }

    static function pickProject() {
        var folders = FileSystem.readDirectory( homeFolder );
        return Zenity.pickItem("Project", folders);
    }

    static function pickVideo( project:String ) {
        var folders = FileSystem.readDirectory( homeFolder.addTrailingSlash() + project );
        return Zenity.pickItem("Video", folders);
    }

    static function pickProjectAndVideo() {
        var project = pickProject();
        if (project!="") {
            var video = pickVideo( project );
            if (video!="") return {
                project: project,
                video: video,
                path: homeFolder.addTrailingSlash() + project.addTrailingSlash() + video.addTrailingSlash()
            }
        }
        return null;
    }
}