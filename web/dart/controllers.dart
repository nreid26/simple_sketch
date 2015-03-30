part of simple_sketch;

abstract class CanvasController {
	//Static
	static Point<double> _unroundPoint(Point p) => (p.x is int || p.y is int) ? new Point<double>(p.x.toDouble(), p.y.toDouble()) : p;
	static bool _down = false;
	
	//Methods		
	void acceptClick(MouseEvent e) {
		e.stopPropagation();
		e.preventDefault();
		
		handleClick(_unroundPoint(e.client));
		redraw();
	}
	
	void acceptDown(MouseEvent e) {
		e.stopPropagation();
		e.preventDefault();
		
		_down = true;
		handleDown(_unroundPoint(e.client));
		redraw();
	}
	
	void acceptMove(MouseEvent e) {
		e.stopPropagation();
		e.preventDefault();
		
		if(_down) {
			handleDrag(_unroundPoint(e.client));
			redraw();
		}
	}
	
	void acceptUp(MouseEvent e) {
		e.stopPropagation();
		e.preventDefault();
		
		_down = false;
		handleUp(e.client);
		redraw();
	}
	
	void acceptKey(KeyboardEvent e) {
		e.stopPropagation();
		e.preventDefault();
		
		if(e.repeat || e.shiftKey || !e.ctrlKey) { return; }		
		handleKey(new String.fromCharCode(e.keyCode));
		redraw();
	}
		
	void handleClick(Point<double> p) { }
	void handleDown(Point<double> p) { }
	void handleDrag(Point<double> p) { }
	void handleUp(Point<double> p) { }
	
	void handleKey(String char) {
		switch(char) {
			case 'R': window.location.reload(); break;
			case 'P': palette.hidden = !palette.hidden; break;
			case 'M': menu.hidden = !menu.hidden; break;
			case 'S': transcoder.save(); break;
			case 'L': transcoder.load(); break;
		}
	}
}

class AxialController extends CanvasController {
	//Data
	final AxialFigure prime;
	
	//Constructor
	AxialController(this.prime);
	
	//Methods	
	void handleDown(Point<double> p) {
		activeFigure = prime.clone()
					   		..center = p
					   		..color = activeColor;
	}
	
	void handleDrag(Point<double> p) {
		p -= activeFigure.center;
		(activeFigure as AxialFigure)
			..halfWidth = p.x.abs()
			..halfHeight = p.y.abs();
	}	
	
	void handleUp(Point<double> p) {
		handleDrag(p);
		completeFigure();
	}
}

class RadialController extends AxialController {	
	//Constructor
	RadialController(RadialFigure prime) : super(prime);
	
	//Methods
	void handleDrag(Point<double> p) {
		(activeFigure as RadialFigure).radius = activeFigure.center.distanceTo(p);
	}	
}

class PolygonController extends CanvasController {
	//Statics
	static final MIN_SEPARATION = 10;
	
	//Data
	Point<double> _start, _last;
	bool _isBufferPoint = false;
	
	//Methods	
	void handleClick(Point<double> p) {
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
	
	void handleDrag(Point<double> p) {
		if(activeFigure == null) { return; }
		
		if(_isBufferPoint) { (activeFigure as Polygon).removePoint(); }
		else { _isBufferPoint = true; }
		(activeFigure as Polygon).addPoint(p);
	}
}

class FreehandController extends CanvasController {
	//Statics
	static final SMOOTHING = 0.6;
	
	//Data
	Point<double> _smoothed;
	
	//Methods
	void handleDown(Point<double> p) {
		activeFigure = new Polygon()
			..color = activeColor
			..addPoint(p);
		_smoothed = p;
	}
	
	void handleDrag(Point<double> p) {
		_smoothed = (_smoothed * SMOOTHING) + (p * (1 - SMOOTHING));
		(activeFigure as Polygon).addPoint(_smoothed);
	}
	
	void handleUp(Point<double> p) {
		handleDrag(p);
		completeFigure();
	}
}

class SelectionController extends CanvasController {
	//Data
	final Circle outline = new Circle();
	
	//Methods
	void handleDown(Point<double> p) {
		selectedFigures.clear();
		selectionCircle = outline
							..radius = 0
							..center = p;
	}
	
	void handleDrag(Point<double> p) {
		outline.radius = p.distanceTo(outline.center);
		selectedFigures.addAll(allFigures.where( (Figure f) =>
			f.center.distanceTo(outline.center) < outline.radius
		));
	}
	
	void handleUp(Point<double> p) => selectionCircle = null;
}

class MoveController extends CanvasController {
	//Data
	Point<double> _last;
	
	//Methods
	void handleDown(Point<double> p) { _last = p; }
	
	void handleDrag(Point<double> p) {
		Point<double> delta = p - _last;
		_last = p;
		for(Figure f in selectedFigures) {
			f.center += delta;
		}
	}
}