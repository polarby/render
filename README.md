[![pub package](https://img.shields.io/pub/v/render.svg)](https://pub.dartlang.org/packages/render)
[![GitHub stars](https://img.shields.io/github/stars/polarby/render)](https://github.com/polarby/render/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/polarby/render)](https://github.com/polarby/render/network)
[![GitHub license](https://img.shields.io/github/license/polarby/render)](https://github.com/polarby/render/blob/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/polarby/render)](https://github.com/polarby/render/issues)

# Render

With the Render widget you can render and convert widgets into a wide range of exportable file
formats. Main features include:

- Render static or animated widgets to png, jpg, gif, mov and mp4 (including sound)
- Rendering widgets that are not in your widget tree (not displayed/build)
- Render multiple variations of your widget at the same time with layered rendering (including mixed
  building visualisation)

**Important Notes:**

* Rendering platform views requires the use of `RenderWrapper`'s (see known issues)
* Rendering front-end elements is not considered the most efficient and
  native approach to editing images and videos. Use with own responsibility.

-------

## Examples

Video

## Usage

```dart

final _controller = RenderController();

Render
(
controller: _controller,
duration: Duration(seconds: 5),
builder: (context, RenderSnapshot snapshot){
return Container();
}
)


await _controller.render(overwriteFrames: 269, frame
:
5
);
```

Tip: full interactive example for usage in `./example` folder.

### Layered rendering

You might encounter situations where you want to have variations of your widget rendering (eg. one
version with round corners & and one without).
Instead of rendering your widget multiple times you can use *layered rendering*, which renderes the
widget only ones instead of multiple times and consequently reduces your rendering time and
significantly.

Simply wrap a widget within your `Render` build with `RenderLayer`:

```dart
RenderLayer
(
visualize
:
false
,
child
:
...
) 
```

## Properties of render classes

<details>
  <summary>Properties of `Render`</summary>

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

</details>

<details>
  <summary>Properties of `RenderLayer`</summary>

</details>


<details>
  <summary>Properties of `RenderController`</summary>

</details>

## Known Issues

* Isolated platform views
  are generally [not supported by flutter](https://github.com/flutter/flutter/issues/102866) (
  Example:
  Google Maps, Camera, Vide players, etc.).
  Please consider using the approach of this package by using `RenderWrapper`'s to be able to
  capture those widgets.

## Under the hood: How does `Render` work?

Render widget is a native flutter widget that relies on `RepaintBoundary` to capture flutter widgets
frame by frame. Each frame is needs to be build-out (not necessary in a visible widget tree) to be
able to get captured.
*When `capture()` is called:* The builder will try to build each state of of the child widget to be
able to repaint its boundary. The builder passes the snapshot argument, so you can adjust the
current state of the child widget to the new frame and time. Each frame is written to a temporary
directory, to then be processed by [Ffmpeg](https://pub.dev/packages/ffmpeg_kit_flutter) (a tool for
video, audio and image processing), which then process each frame to the wanted output type.

## Additional information

Contributions are very welcome and can be merged within hours if testing is successful. 

