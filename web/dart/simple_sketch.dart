library simple_sketch;

import 'dart:html';
import 'dart:math';
import 'package:color/color.dart';

part './figures.dart';
part './controllers.dart';
part './elements.dart';
part './transcoder.dart';


//Compile-time Constants
final Point<double> ORIGIN = const Point<double>(0.0, 0.0);

//Runtime Constants
final Set<Figure> allFigures = new Set<Figure>(), selectedFigures = new Set<Figure>();
final CanvasElement canvas = document.querySelector('#canvas');
final CanvasRenderingContext2D context = canvas.context2D;
final Palette palette = new Palette();
final Menu menu = new Menu();
//final Info info = new Info();

//Mutables
CanvasColor activeColor = new CanvasColor.rgb(0, 0, 0);
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
		..append( new MenuItem('images/polygon.png', new PolygonController()) )
		..append( new MenuItem('images/rectangle.png', new AxialController(new Rectangle())) )
		..append( new MenuItem('images/square.png', new RadialController(new Square())) )
		..append( new MenuItem('images/ellipse.png', new AxialController(new Ellipse())) )
		..append( new MenuItem('images/circle.png', new RadialController(new Circle())) )
		..children.first.click();
	
	//Fill Popup
	document.querySelector('#popup')
		..append(menu)
		..append(palette);
		//..append(info);
	
	//Assign listeners
	document.body
		..onClick.listen((e) => activeController.acceptClick(e))
		..onMouseMove.listen((e) => activeController.acceptMove(e))
		..onMouseDown.listen((e) => activeController.acceptDown(e))
		..onMouseUp.listen((e) => activeController.acceptUp(e))
		..onKeyDown.listen((e) => activeController.acceptKey(e));
}

void redraw() {
	context.clearRect(0, 0, canvas.width, canvas.height);
	
	context.lineWidth = 3;
	for(Figure f in allFigures) {
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
	allFigures.add(activeFigure);
	activeFigure = null;
}

class CanvasColor extends RgbColor {
	CanvasColor.rgb(int r, int g, int b) : super(r, g, b);
	String get hexString => '#' + toHexColor().toString();
}


