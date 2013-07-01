package;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import ru.stablex.ui.UIBuilder;

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


}