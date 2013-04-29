package;


import com.eclecticdesignstudio.motion.Actuate;
import nme.display.Sprite;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.text.TextFormat;
import nme.text.TextField;
import nme.text.TextFieldType;
import nme.events.*;
import nme.Assets;
import nme.Lib;
import vidproject.commands.*;

/**
 * @author Jason O'Neil
 */
class VoseApp extends Sprite {
	
	
	public function new () {
		
		super ();
		
		initialize ();
		
		var font = Assets.getFont ("assets/VeraSe.ttf");
		var format = new TextFormat (font.fontName, 24, 0xFF0000);
		
		var textField = new TextField ();
		textField.defaultTextFormat = format;
		textField.selectable = false;
		textField.embedFonts = true;
		textField.width = 260;
		textField.height = 40;
		textField.x = 20;
		textField.y = 20;
		
		textField.text = "Setup Project";
		
		addChild (textField);

		textField.addEventListener (MouseEvent.CLICK, function (e:MouseEvent) {
			var textField:TextField = e.currentTarget;
			trace ("Clicked... setting up project now");
			// var p = new sys.io.Process("kdenlive", ["/home/jason/workspace/Vose-Video-Node/src/tools/renderer/sample.kdenlive"]);
			
		});
		
	}
	
	
	private function initialize ():Void {
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
	}
	
	
	
	
	// Entry point
	
	
	
	
	public static function main () {
		
		Lib.current.addChild (new VoseApp ());
		
	}
	
	
}