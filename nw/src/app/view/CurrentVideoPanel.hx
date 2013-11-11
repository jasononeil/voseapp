package app.view;

import app.api.ProjectApi.VideoStatus;
import dtx.widget.Widget;
import dtx.widget.WidgetLoop;
import bootstrap.Button;
import haxe.EnumFlags;

class CurrentVideoPanel extends Widget
{
	public var existingClips:Array<String>;
	public var clipsToImport:Array<String>;

	var exists:Bool;
	var clipsCopied:Bool;
	var kdenliveCreated:Bool;
	var mp3Rendered:Bool;
	var mp4Rendered:Bool;
	var vobRendered:Bool;
	var dvdStylerCreated:Bool;
	var isoCreated:Bool;

	public function new( title:String ) {
		clipsToImport = [];
		existingClips = [];
		super();
		this.title = title;
	}

	public function setStatus( status:EnumFlags<VideoStatus> ) {
		exists = status.has( Exists );
		clipsCopied = status.has( ClipsCopied );
		kdenliveCreated = status.has( KdenliveCreated );
		mp3Rendered = status.has( MP3Rendered );
		mp4Rendered = status.has( MP4Rendered );
		vobRendered = status.has( VobRendered );
		dvdStylerCreated = status.has( DvdStylerCreated );
		isoCreated = status.has( IsoCreated );
	}
}