using Godot;
using Godot.Collections;

[GlobalClass, Icon("icons/MultiplayerSynchronizer.svg")]
public partial class SimusNetTransformCS : Node
{
	[Export] public Node node;

	private readonly StringName _META = new("transform");
	private readonly StringName _P_POSITION = new("position");
	private readonly StringName _P_ROTATION = new("rotation");
	private readonly StringName _P_SCALE = new("scale");

	private Dictionary<StringName, Variant> _data = [];

	public override void _EnterTree()
	{

	}

	public override	void _ExitTree() 
	{
		
	}

	public override void _Ready()
	{
		Script net_synchronization = GD.Load<Script>("SimusNet/singletons/SimusNetSynchronization.gd");
		_data = (Dictionary<StringName, Variant>) net_synchronization.Call("get_synced_properties", this);

	}

	public override void _Process(double delta)
	{
	}
}
