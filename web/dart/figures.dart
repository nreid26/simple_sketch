part of simple_sketch;

abstract class AxialFigure implements Figure {
	num halfHeight = 0, halfWidth = 0;
}

abstract class RadialFigure implements AxialFigure {
	num radius = 0;
	
	num  get halfHeight => radius;
	void set halfHeight(num n) { radius = n; }
	
	num  get halfWidth => radius;
	void set halfWidth(num n) { radius = n; }
}

////////////////////////////////////////////////

abstract class Figure {
	//Data
	Point<double> center = ORIGIN;
	CanvasColor color = new CanvasColor.rgb(0, 0, 0);
	
	//Methods
	Figure clone();
	void draw(CanvasRenderingContext2D context);
		
	num get perimeter;
}

class CompositeFigure extends Figure {	
	//Data
	final Set<Figure> _subfigures = new Set<Figure>();
	final num perimeter;
	Point<double> _center;
	
	//Constructor
	CompositeFigure(Set<Figure> parts) : perimeter = parts.fold(0, (num p, Figure f) => p + f.perimeter) {
		_subfigures.addAll(parts);
		_center = _subfigures.fold(ORIGIN, (Point<double> p, Figure f) => p + f.center * f.perimeter) * (1 / perimeter);
	}
	
	//Methods
	void draw(CanvasRenderingContext2D context) {
		for(Figure f in _subfigures) {
			f.draw(context);
		}
	}
	
	CompositeFigure clone() {
		Set x = new Set();
		for(Figure f in _subfigures) {
			x.add(f.clone());
		}
		
		return new CompositeFigure(x);
	}
	
	Point<double> get center => _center;
	void set center(Point<double> p) {
		var c = center - p;
		_center = p;
		for(Figure f in _subfigures) { f.center -= c; }
	}	
}

class Polygon extends Figure {	
	//Data
	final List<Point<double>> _points = [];
	bool _isClosed = false;
	num _perimeter = null;
	Point<double> _center = null;
		
	//Methods
	Point<double> get center {
		if(_center == null) {
			_center = _points.reduce((a, b) => a + b) * (1 / _points.length);
		}
		return _center;
	}
	void		  set center(Point<double> p) {
		Point<double> delta = p - center;
		for(int i = 0; i < _points.length; i++) { _points[i] -= delta; }
		_center = p;
	}
	
	bool get isClosed => _isClosed;
	void set isClosed(bool b) {
		if(_isClosed != b) {
			_perimeter = null;
			_isClosed = b;
		}
	}
	
	int get sides => _points.length - ((_isClosed) ? 1 : 0);
	
	num get perimeter {
		if(_perimeter == null) {
			_perimeter = 0;
			Iterator a = _points.iterator, b = _points.iterator;
			while(a.moveNext()) {
				_perimeter += a.current.distanceTo(b.current);
				b.moveNext();
			}
			if(_isClosed) { _perimeter += _points.first.distanceTo(_points.last); }
		}
		return _perimeter;
	}
	
	void draw(CanvasRenderingContext2D context) {
		if(_points.length < 2) { return; }
		
		context
			..strokeStyle = color.hexString
			..beginPath()
			..moveTo(_points.first.x, _points.first.y);
		
		for(Point p in _points) { context.lineTo(p.x, p.y); }
		if(_isClosed) { context.closePath(); }
		context.stroke();
	}
	
	Polygon clone() {
		var x = new Polygon()..color = color;
		for(Point p in _points) {
			x.addPoint(p);
		}
		return x
			.._isClosed = _isClosed;
	}
	
	void addPoint(Point<double> p) {		
		_points.add(p);
		_center = null;
		_perimeter = null;
	}
	
	bool removePoint() {
		_center = null;
		_perimeter = null;
		return (_points.removeLast() != null);
	}		
}

class Ellipse extends Figure with AxialFigure {		
	//Methods
	void draw(CanvasRenderingContext2D context) {
		context		
			..strokeStyle = color.hexString
			..beginPath()
			..ellipse(center.x, center.y, halfWidth, halfHeight, 0, 0, 2 * PI, false)
			..stroke()
			
			..restore();
	}
	
	Ellipse clone() {
		return new Ellipse()
			..color = color
			..halfHeight = halfHeight
			..halfWidth = halfWidth;
	}	
	
	num get perimeter {
		var h = pow((halfWidth - halfHeight) / (halfWidth + halfHeight), 2);
		return PI * (halfWidth + halfHeight) * (1 + (3 * h) / (10 - sqrt(4 - 3 * h))); //Ramanujan approximation
	}
}

class Circle extends Ellipse with RadialFigure {	
	//Methods	
	Circle clone() {
		return new Circle()
			..color = color
			..radius = radius;
	}	
}

class Rectangle extends Figure with AxialFigure {	
	//Methods
	void draw(CanvasRenderingContext2D context) {
		context
			..strokeStyle = color.hexString
			..strokeRect(center.x - halfWidth, center.y - halfHeight, halfWidth * 2, halfHeight * 2);
	}
	
	Rectangle clone() {
		return new Rectangle()
			..color = color
			..halfHeight = halfHeight
			..halfWidth = halfWidth;
	}	
	
	num get perimeter => 4 * (halfWidth + halfHeight);
}

class Square extends Rectangle with RadialFigure {
	//Methods	
 	Square clone() {
		return new Square()
			..color = color
			..radius = radius;
	}	 	
}