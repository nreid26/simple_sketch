part of simple_sketch;

class ElementFactory {
	static Map<Type, List<String>> _registrations = {};
	
	static Element construct(Type type, String name, [String superName]) {
		name = 'x-' + name;

		if(!_registrations.containsKey(type)) {
			document.registerElement(name, type, extendsTag: superName);
			_registrations[type] = [name, superName];
		}
		
		var x = _registrations[type];
		if(x[0] != name || x[1] != superName) { throw new ArgumentError("'$type' was previously registered as '${x[0]}' extending '${x[1]}'"); }
		return new Element.tag(x[1], x[0]);
	}
}

/////////////////////////////////////////////

abstract class Hidable implements Element {
	bool get hidden => style.display == 'none';
	void set hidden(bool b) { style.display = (b) ? 'none' : 'inline-block'; }
}

abstract class Nonpropagating implements Element {
	void _stopPropagation() {
		void stopE(Event e) => e.stopPropagation();

		onClick.listen(stopE);
		onMouseDown.listen(stopE);	
		onMouseUp.listen(stopE);	
		onMouseMove.listen(stopE);	
	}
}

/////////////////////////////////////////////

class Menu extends DivElement with Hidable, Nonpropagating {
	//Constructor
	Menu.created() : super.created() {
		_stopPropagation();
		hidden = true;
		classes.add('menu');
	}
	
	factory Menu() { 
		return ElementFactory.construct(Menu, 'menu', 'div');
	}	
}

class MenuItem extends ImageElement {
	//Static
	static MenuItem _selected;
	
	//Constructor
	MenuItem.created() : super.created() {
		classes.add('menu_item');
	}
	
	factory MenuItem(String src, CanvasController controller) { 
		MenuItem m = (ElementFactory.construct(MenuItem, 'menu-item', 'img') as MenuItem);
		m
			..src = src
			..onClick.listen((Event e) {
				activeFigure = null;
				activeController = controller;
				
				if(_selected != null) { _selected.classes.remove('selected_menu_item'); }
				_selected = m;
				m.classes.add('selected_menu_item');
			});
		
		return m;
	}	
}

class Palette extends DivElement with Hidable, Nonpropagating {
	//Data
	Color display = new Color.rgb(0, 0, 0);
	
	//Constructor
	Palette.created() : super.created() { 
		_stopPropagation();
		id = 'palette';
		hidden = true;
		innerHtml = '''
					<div>
						<input type="range" max="255" value="0" /><br>
						<input type="range" max="255" value="0" /><br>
						<input type="range" max="255" value="0" /><br>
					</div>
					<div id="palette_sample"></div>
					<br>
					<input type="button" value="Ok" id="palette_ok" />
					<input type="button" value="Cancel" id="palette_cancel" />
					''';
		
		List<RangeInputElement> sliderList = this.querySelectorAll('input[type="range"]');
		DivElement sample = this.querySelector('#palette_sample');
		CanvasColor color;
		
		void setSample(Event e) {
			var l = sliderList.map((re) => int.parse(re.value, onError: (s) => 0)).toList(growable: false);
			color = new CanvasColor.rgb(l[0], l[1], l[2]);
			sample.style.background = color.hexString;
		}
		for(Element r in sliderList) { r.onChange.listen(setSample); }
		setSample(null);
		
		this.querySelector('input[type="button"][value="Ok"]').onClick.listen((e) {
				hidden = true;
				activeColor = color;
			});
		this.querySelector('input[type="button"][value="Cancel"]').onClick.listen((e) {
				hidden = true;
				color = activeColor;
				sample.style.background = color.hexString;
			});
	}
	
	factory Palette() { 
		return ElementFactory.construct(Palette, 'palette', 'div');
	}
}