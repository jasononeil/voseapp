package templates.kdenlive;

@loadTemplate("ProjectWithDefaults.kdenlive")
class ProjectWithDefaults extends dtx.widget.Widget
{
	public function new(projectPath:String)
	{
		super();
		trace (projectPath);
	}
}