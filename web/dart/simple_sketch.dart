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
final Palette palette = new Palette();
final Menu menu = new Menu();
final Info info = new Info();
final commands = {
	'A': ()  { selectedFigures.addAll(unselectedFigures); unselectedFigures.clear(); },
	'C': () => copiedFigures..clear()..addAll( selectedFigures.map((Figure f) => f.clone()) ),
	'D': () => selectedFigures.clear(),
	'G': ()  { var f = new CompositeFigure(selectedFigures); selectedFigures..clear()..add(f); },
	'I': () => info.hidden = !info.hidden,
	'M': () => menu.hidden = !menu.hidden,
	'P': () => palette.hidden = !palette.hidden,
	'Q': () => selectedFigures.forEach((Figure f) => f.color = activeColor),
	'S': () => window.localStorage['drawing'] = JSON.encode({'unselected': unselectedFigures.toList(), 'selected': selectedFigures.toList(), 'copied': copiedFigures.toList()}),
	'V': ()  { unselectedFigures.addAll(selectedFigures); selectedFigures..clear()..addAll( copiedFigures.map((Figure f) => f.clone()) ); },
	'X': ()  { copiedFigures..clear()..addAll(selectedFigures); selectedFigures.clear(); },
	
	'U': ()  {
    		Set<Figure> composites = new Set<Figure>.from(selectedFigures.where((Figure f) => f is CompositeFigure)),
        				exploded = new Set<Figure>();
        	for(CompositeFigure f in composites) { exploded.addAll(f.subfigures); }
        		
        	selectedFigures
        		..removeAll(composites)
        		..addAll(exploded);
	},
    
    'O': () {
    	String serial = window.localStorage['drawing'];
    	if(serial == null) { return; }
    	
    	Iterable<Figure> revive(Iterable i) => i.map((Map m) => REVIVE_MAP[m['class']](m));
    	
    	Map interm = JSON.decode(serial);
    	selectedFigures
    		..clear()
    		..addAll(revive(interm['selected']));
    	unselectedFigures
	        ..clear()
    		..addAll(revive(interm['unselected']));
    	copiedFigures
	        ..clear()
    		..addAll(revive(interm['copied']));
    }
};

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
	document.querySelector('#popup')
		..append(menu)
		..append(new BRElement())
		..append(palette)
		..append(new BRElement())
		..append(info);
	
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

