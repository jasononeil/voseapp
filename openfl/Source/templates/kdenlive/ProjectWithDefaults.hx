package templates.kdenlive;

@:loadTemplate("ProjectWithDefaults.kdenlive")
class ProjectWithDefaults extends dtx.widget.Widget {
	public var clips:Array<ClipInfo>;
}

typedef ClipInfo = {
	var clipName:String;
	var clipPath:String;
	var proxyPath:String;
	var fileSize:Int;
	var fileHash:String;
	var id:Int;
	var duration:Int;
}