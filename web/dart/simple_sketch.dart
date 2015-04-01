library simple_sketch;

import 'dart:html';
import 'dart:math';
import 'dart:convert';
import 'package:color/color.dart';

part './figures.dart';
part './controllers.dart';
part './elements.dart';

//Compile-time Constants
final Point<double> ORIGIN = const Point<double>(0.0, 0.0);

//Runtime Constants
final Set<Figure> unselectedFigures = new Set<Figure>(), selectedFigures = new Set<Figure>(), copiedFigures = new Set<Figure>();
final CanvasElement canvas = document.querySelector('#canvas');
final CanvasRenderingContext2D context = canvas.context2D;
final DivElement popup = document.querySelector('#popup');
final Palette palette = new Palette();
final Menu menu = new Menu();
final Info info = new Info();

//Mutables
Color activeColor = new Color.rgb(0, 0, 0);
Figure activeFigure;
CanvasController activeController;
Circle selectionCircle;

void main() {
	//Configure canvas
	void resize(Event e) {
		canvas
			..width = window.innerWidth
			..height = window.innerHeight;
		redraw();
	}
		
	window.onResize.listen(resize);
	resize(null);
	
	//Configure menu
	menu
		..append( new MenuItem('images/select.png', new SelectionController()) )
		..append( new MenuItem('images/move.png', new MoveController()) )
		..append( new MenuItem('images/freehand.png', new FreehandController()) )
		..append(new BRElement())
		..append( new MenuItem('images/line.png', new LineController()) )
		..append( new MenuItem('images/polygon.png', new PolygonController()) )
		..append( new MenuItem('images/rectangle.png', new AxialController(new Rectangle())) )
		..append(new BRElement())
		..append( new MenuItem('images/square.png', new RadialController(new Square())) )
		..append( new MenuItem('images/ellipse.png', new AxialController(new Ellipse())) )
		..append( new MenuItem('images/circle.png', new RadialController(new Circle())) )
		..children.first.click();
	
	//Fill Popup
	popup
		..append(menu)
		..append(palette)
		..append(info);
	
	//Assign listeners
	document.body
		..onClick.listen((e) => activeController.acceptClick(e))
		..onMouseMove.listen((e) => activeController.acceptMove(e))
		..onMouseDown.listen((e) => activeController.acceptDown(e))
		..onMouseUp.listen((e) => activeController.acceptUp(e))
		..onMouseLeave.listen((e) => activeController.acceptLeave(e))
		..onKeyDown.listen((e) => activeController.acceptKeyDown(e))
		..onKeyUp.listen((e) => activeController.acceptKeyUp(e));
}

void redraw() {
	context.clearRect(0, 0, canvas.width, canvas.height);
	
	context.lineWidth = 3;
	for(Figure f in unselectedFigures) {
		if(!selectedFigures.contains(f)) {
			f.draw(context);
		}
	}
	
	context.lineWidth = 5;
	for(Figure f in selectedFigures) {
		f.draw(context);
	}
	if(activeFigure != null) { activeFigure.draw(context); }
	
	if(selectionCircle != null) {
		context
			..lineWidth = 1
			..setLineDash([5, 5])
			..strokeStyle = 'black';
		selectionCircle.draw(context);
		context.setLineDash([]);
	}
}

void completeFigure() {
	unselectedFigures.add(activeFigure);
	activeFigure = null;
}

void mouseUpdate(Point p) {
	for(Hidable h in popup.children) {
		if(h is Hidable && h.hidden) {
			h.style
				..left = '${p.x}px'
				..top = '${p.y}px';
		}
	}
}

