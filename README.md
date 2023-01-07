*PRE-RELEASE*

# Render 

With the Render widget you can render and convert wigets into a wide range of exportable file formats. Main features include:

- Render static or animated widgets to png, jpg, gif, mov and mp4 (including sound) 
- Rendering wigets that are not in your widget tree (not displayed/build) 
- Render multiple variations of your widget at the same time with layered rendering (including mixed building visualisation) 


**Important:** Note that rendering front-end elements is not considered the most efficient and native approach to editing images and videos. Use with own responsabilty. 

-------
## Examples 
Video 
## Usage 

```dart

final _controller 	= RenderController();

Render(
    controller: _controller,
    duration: Duration(seconds: 5),
    builder: (context, RenderSnapshot snapshot){
       return Container();
    } 
) 


await  _controller.render(overwriteFrames: 269, frame: 5);
```

Tip: full interactive example for usage in `./example` folder. 

### Layered rendering 
You might encounter situations where you want to have variations of your widget rendering (eg. one version with round corners & and one without). 
Instead of rendering your widget multiple times you can use *layered rendering*, which renderes the widget only ones instead of multiple times and consequently reduces your rendering time and significantly. 

Simply wrap a widget within your `Render` build with `RenderLayer`:
```dart
RenderLayer(
    visualize: false,
    child: ... 
) 
```



## Properties of `Render`

|  Name  |  Type  |  Default Behavior  |  Description  |
|----|----|----|----|
|  controller  |  PageController?  |  PageController() |  The controller to manipulate the state of your list. The behavior of list and controller equals the default `PageView` widget  |
|  *required* itemBuilder  |  Widget Function(BuildContext, int) |    |   |
|  *required* itemCount  |  int  |    |    |
|  scrollDirection  |  Axis  |  Axis.horizontal |    |
|  physics  |  ScrollPhysics?  |  AlwaysScrollable() |    |
|  itemExtent |  double? |    |    |
|  minCacheExtent  |  double? |    |    |
|  itemSnapping  |  bool  |  false  |    |
|  addSemanticIndexes  |  bool  |  true  |    |
|  addAutomaticKeepAlives  |  bool  |  true  |    |
|  addRepaintBoundaries  |  bool  |  true  |    |
|  reverse  |  bool  |  false  |    |
|  itemPositionsListener  |  ItemPositionsListener?  |    |    |
|  onPageChanged  |  void Function(int index, double size)? |    |    |
|  onPageChange  |  void Function(double page, double size)? |    |    |
|  overscrollPhysics  |  PageOverscrollPhysics?  |  normal PageView scrolling |    |
|  scrollBehavoir  |  ScrollBehavoir?  |    |    |
|  visualisation |  ListVisualisation?  |  ListVisualisation.normal() |    |
|  allowItemSizes  |  bool  |  false  |    |
|  snapAlignment  |  SnapAlignment  |  SnapAlignment.static(0.5) |    |
|  snapOnItemAlignment  |  SnapAlignment  |  SnapAlignment.static(0.5)  |    |

## Properties of `RenderLayer`

## Properties of `RenderController`

## Additional information
Contributions are very welcome and can be merged within hours if testing is successful. 