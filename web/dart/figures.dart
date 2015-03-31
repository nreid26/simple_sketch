part of simple_sketch;

abstract class AxialFigure implements Figure {
	num halfHeight = 0, halfWidth = 0;
	
	Map addEncoding(Map m) {
		m['halfHeight'] = halfHeight;
		m['halfWidth'] = halfWidth;
		return m;
	}
}

abstract class RadialFigure implements AxialFigure {
	num radius = 0;
	
	num  get halfHeight => radius;
	void set halfHeight(num n) { radius = n; }
	
	num  get halfWidth => radius;
	void set halfWidth(num n) { radius = n; }
	
	Map addEncoding(Map m) {
		m['radius'] = radius;
		return m;
	}
}

////////////////////////////////////////////////

final Map<String, Function> REVIVE_MAP = {
	'CompositeFigure': CompositeFigure.revive,
	'Polygon': Polygon.revive,
	'Ellipse': Ellipse.revive,
	'Circle': Circle.revive,
	'Rectangle': Rectangle.revive,
	'Square': Square.revive,
};

String _toHexString(Color c) => '#' + c.toHexColor().toString();

Point<num> _extractPoint(Map m) => new Point<num>(m['x'].toDouble(), m['y'].toDouble());

///////////////////////////////////////////////

abstract class Figure {
	//Data
	Point<num> center = ORIGIN;
	Color color = new Color.rgb(0, 0, 0);
	
	//Methods
	Figure clone();
	void draw(CanvasRenderingContext2D context);
		
	num get perimeter;
	
	Map toJson() => {
		'class': this.runtimeType.toString(),
		'center': {'x': center.x, 'y': center.y},
		'perimeter': perimeter,
		'color': _toHexString(color).substring(1),
	};
}

class CompositeFigure extends Figure {	
	//Static
	static CompositeFigure revive(Map m) {
		var s = new Set<Figure>();
		for(Map p in m['subfigures']) { s.add( REVIVE_MAP[p['class']](p) ); }
		return new CompositeFigure(s);
	}
	
	//Data
	final Set<Figure> _subfigures = new Set<Figure>();
	final num perimeter;
	Point<num> _center;
	
	//Constructor
	CompositeFigure(Set<Figure> parts) : perimeter = parts.fold(0, (num p, Figure f) => p + f.perimeter) {
		_subfigures.addAll(parts);
		_center = _subfigures.fold(ORIGIN, (Point<num> p, Figure f) => p + f.center * f.perimeter) * (1 / perimeter);
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
	
	Point<num> get center => _center;
	void set center(Point<num> p) {
		var c = center - p;
		_center = p;
		for(Figure f in _subfigures) { f.center -= c; }
	}
	
	Color get color => null;
	void	    set color(Color c) => _subfigures.forEach((Figure f) => f.color = c);
	
	Set<Figure> get subfigures => new Set<Figure>.from(_subfigures);
	
	Map toJson() {
		var m = super.toJson();
		m['subfigures'] = _subfigures.map((Figure f) => toJson()).toList(growable: false);
		return m;
	}
}

class Polygon extends Figure {	
	//Static
	static Polygon revive(Map m) {
		return new Polygon()
			.._points.addAll( m['points'].map(_extractPoint) )
			.._isClosed = m['closed']
			..color = new Color.hex(m['color']);
	}
	
	//Data
	final List<Point<num>> _points = [];
	bool _isClosed = false;
	num _perimeter = null;
	Point<num> _center = null;
		
	//Methods
	Point<num> get center {
		if(_center == null) {
			_center = _points.reduce((a, b) => a + b) * (1 / _points.length);
		}
		return _center;
	}
	void		  set center(Point<num> p) {
		Point<num> delta = p - center;
		for(int i = 0; i < _points.length; i++) { _points[i] += delta; }
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
			Iterator a = _points.iterator..moveNext(), b = _points.iterator..moveNext();
			
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
			..strokeStyle = _toHexString(color)
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
	
	void addPoint(Point<num> p) {		
		_points.add(p);
		_center = null;
		_perimeter = null;
	}
	
	bool removePoint() {
		_center = null;
		_perimeter = null;
		return (_points.removeLast() != null);
	}		
	
	Map toJson() {
		var m = super.toJson();
		m['closed'] = isClosed;
        m['points'] = _points.map((Point p) => {'x': p.x, 'y': p.y}).toList(growable: false);
		return m;
	}	
}

class Ellipse extends Figure with AxialFigure {	
	//Static
	static Ellipse revive(Map m) {
		return new Ellipse()
			..center = _extractPoint(m['center'])
			..halfHeight = m['halfHeight']
			..halfWidth = m['halfWidth']
			..color = new Color.hex(m['color']);
	}
	
	//Methods
	void draw(CanvasRenderingContext2D context) {
		context		
			..strokeStyle = _toHexString(color)
			..beginPath()
			..ellipse(center.x, center.y, halfWidth.abs(), halfHeight.abs(), 0, 0, 2 * PI, false)
			..stroke()
			
			..restore();
	}
	
	Ellipse clone() {
		return new Ellipse()
			..color = color
			..center = center
			..halfHeight = halfHeight
			..halfWidth = halfWidth;
	}	
	
	num get perimeter {
		var h = pow((halfWidth - halfHeight) / (halfWidth + halfHeight), 2);
		return PI * (halfWidth.abs() + halfHeight.abs()) * (1 + (3 * h) / (10 - sqrt(4 - 3 * h))); //Ramanujan approximation
	}
	
	Map toJson() => addEncoding(super.toJson());
}

class Circle extends Ellipse with RadialFigure {	
	//Static
	static Circle revive(Map m) {
		return new Circle()
			..center = _extractPoint(m['center'])
			..radius = m['radius']
			..color = new Color.hex(m['color']);
	}
	
	//Methods	
	Circle clone() {
		return new Circle()
			..color = color
			..center = center
			..radius = radius;
	}
}

class Rectangle extends Figure with AxialFigure {
	//Static
	static Rectangle revive(Map m) {
		return new Rectangle()
			..center = _extractPoint(m['center'])
			..halfHeight = m['halfHeight']
			..halfWidth = m['halfWidth']
			..color = new Color.hex(m['color']);
	}
	
	//Methods
	void draw(CanvasRenderingContext2D context) {
		context
			..strokeStyle = _toHexString(color)
			..strokeRect(center.x - halfWidth, center.y - halfHeight, halfWidth * 2, halfHeight * 2);
	}
	
	Rectangle clone() {
		return new Rectangle()
			..color = color
			..center = center
			..halfHeight = halfHeight
			..halfWidth = halfWidth;
	}	
	
	num get perimeter => 4 * (halfWidth + halfHeight);
	
	Map toJson() => addEncoding(super.toJson());
}

class Square extends Rectangle with RadialFigure {
	//Static
	static Square revive(Map m) {
		return new Square()
			..center = _extractPoint(m['center'])
			..radius = m['radius']
			..color = new Color.hex(m['color']);
	}
	
	//Methods	
 	Square clone() {
		return new Square()
			..color = color
			..center = center
			..radius = radius;
	}	 	
}