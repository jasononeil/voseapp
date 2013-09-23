package app.view;

import dtx.widget.Widget;
import dtx.widget.WidgetLoop;

class PanelList extends Widget
{
	public var items:Array<ListItem>;
	public function new( title:String ) {
		super();
		this.title = title;
	}
}

typedef ListItem = {
	icon:String,
	name:String,
	badge:String
}