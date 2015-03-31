part of simple_sketch;

abstract class CanvasController {
	//Static
	static bool _down = false, _ctrl = false, _shift = false;
	static final commands = {
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
	
	
	//Data
	String cursorStyle = 'crosshair';
	
	//Methods		
	void configure() {
		document.body.style.cursor = cursorStyle;
	}
	
	void _generalMouse(MouseEvent e) {
		e.stopPropagation();
		e.preventDefault();
		mouseUpdate(e.client);
	}
	
	void acceptClick(MouseEvent e) {
		_generalMouse(e);	
		handleClick(e.client);
		redraw();
	}
	
	void acceptDown(MouseEvent e) {
		_generalMouse(e);	
		_down = true;
		handleDown(e.client);
		redraw();
	}
	
	void acceptMove(MouseEvent e) {
		e.stopPropagation();
		e.preventDefault();
		
		if(_down) {
			handleDrag(e.client);
			redraw();
		}
	}
	
	void acceptUp(MouseEvent e) {
		_generalMouse(e);	
		_down = false;
		handleUp(e.client);
		redraw();
	}
		
	void acceptLeave(MouseEvent e) {
		_generalMouse(e);	
		_ctrl = e.ctrlKey;
		_shift = e.shiftKey;
		_down = false;
		redraw();
	}
	
	void acceptKeyDown(KeyboardEvent e) {	
		if(e.repeat) { return; }
		_ctrl = e.ctrlKey;
		_shift = e.shiftKey;
		
		if( handleKey(new String.fromCharCode(e.keyCode)) ) {
			e.stopPropagation();
			e.preventDefault();
		}
		redraw();
	}
	
	void acceptKeyUp(KeyboardEvent e) {
		_ctrl = e.ctrlKey;
		_shift = e.shiftKey;
		redraw();
	}
		
	void handleClick(Point<num> p) { }
	void handleDown(Point<num> p) { }
	void handleDrag(Point<num> p) { }
	void handleUp(Point<num> p) { }
	
	bool handleKey(String char) {
		Function f = commands[char];
		if(_shift || !_ctrl || f == null) { return false; } 
		f();
		return true;
	}
}

class AxialController extends CanvasController {
	//Data
	final AxialFigure prime;
	Point<num> _start;
	
	//Constructor
	AxialController(this.prime);
	
	//Methods	
	void handleDown(Point<num> p) {
		_start = p;
		activeFigure = prime.clone()
					   		..center = p
					   		..color = activeColor;
	}
	
	void handleDrag(Point<num> p) {
		Point<num> delta = p - _start;
		
		if(CanvasController._shift) {
			(activeFigure as AxialFigure)
				..center = _start
				..halfWidth = delta.x.abs()
				..halfHeight = delta.y.abs();
		}
		else {
			delta *= 0.5;
			(activeFigure as AxialFigure)
				..center = _start + delta
				..halfWidth = delta.x
				..halfHeight = delta.y;
		}
	}	
	
	void handleUp(Point<num> p) {
		handleDrag(p);
		completeFigure();
	}
}

class RadialController extends AxialController {	
	//Constructor
	RadialController(RadialFigure prime) : super(prime);
	
	//Methods
	num sign(num n) => (n == 0) ? 0 : ((n < 0) ? -1 : 1);
	
	void handleDrag(Point<num> p) {
		Point<num> delta = p - _start;

		if(CanvasController._shift) {
			(activeFigure as RadialFigure)
				..center = _start 
				..radius = delta.magnitude;
		}
		else {
			num n = ((delta.x.abs() < delta.y.abs()) ? delta.x : delta.y).abs() / 2;
			(activeFigure as RadialFigure)
				..center = _start + new Point<num>(n * sign(delta.x), n * sign(delta.y))
				..radius = n;
		}
	}	
}

class PolygonController extends CanvasController {
	//Statics
	static final MIN_SEPARATION = 10;
	
	//Data
	Point<num> _start, _last;
	bool _isBufferPoint = false;
	
	//Methods	
	void handleClick(Point<num> p) {
		if(activeFigure == null) { 
			activeFigure = new Polygon()
								..color = activeColor;
			_start = p;
		}
		Polygon poly = (activeFigure as Polygon);
		
		if(poly.sides >= 2 && p.distanceTo(_start) < MIN_SEPARATION) { poly.isClosed = true; }
		
		if((_last != null && p.distanceTo(_last) < MIN_SEPARATION) || poly.isClosed) {
			completeFigure();
			_start = null;
			_last = null;
			return;
		}
		else { poly.addPoint(p); }
		
		_isBufferPoint = false;
		_last = p;
	}
	
	void handleDrag(Point<num> p) {
		if(activeFigure == null) { return; }
		
		if(_isBufferPoint) { (activeFigure as Polygon).removePoint(); }
		else { _isBufferPoint = true; }
		(activeFigure as Polygon).addPoint(p);
	}
}

class LineController extends CanvasController {
	//Methods
	void handleDown(Point<num> p) {
		activeFigure = new Polygon()
			..color = activeColor
			..addPoint(p)
			..addPoint(p);
	}
	
	void handleDrag(Point<num> p) {
		(activeFigure as Polygon)
			..removePoint()
			..addPoint(p);
	}
	
	void handleUp(Point<num> p) {
		handleDrag(p);
		completeFigure();
	}
}

class FreehandController extends CanvasController {
	//Statics
	static final SMOOTHING = 0.6;
	
	//Data
	Point<num> _smoothed;
	
	//Methods
	void handleDown(Point<num> p) {
		activeFigure = new Polygon()
			..color = activeColor
			..addPoint(p);
		_smoothed = p;
	}
	
	void handleDrag(Point<num> p) {
		_smoothed = (_smoothed * SMOOTHING) + (p * (1 - SMOOTHING));
		(activeFigure as Polygon).addPoint(_smoothed);
	}
	
	void handleUp(Point<num> p) {
		handleDrag(p);
		completeFigure();
	}
}

class SelectionController extends CanvasController {
	//Data
	final Circle outline = new Circle();
	
	//Methods
	void handleDown(Point<num> p) {
		unselectedFigures.addAll(selectedFigures);
		selectedFigures.clear();
		selectionCircle = outline
							..radius = 0
							..center = p;
	}
	
	void handleDrag(Point<num> p) {
		outline.radius = p.distanceTo(outline.center);
		unselectedFigures.addAll(selectedFigures);
		selectedFigures
			..clear()
			..addAll(unselectedFigures.where( (Figure f) =>
				f.center.distanceTo(outline.center) < outline.radius
			));
		unselectedFigures.removeAll(selectedFigures);
	}
	
	void handleUp(Point<num> p) => selectionCircle = null;
}

class MoveController extends CanvasController {
	//Data
	Point<num> _last;
	String cursorStyle = 'move';
	
	//Methods
	void handleDown(Point<num> p) { _last = p; }
	
	void handleDrag(Point<num> p) {
		Point<num> delta = p - _last;
		_last = p;
		for(Figure f in selectedFigures) {
			f.center += delta;
		}
	}
}