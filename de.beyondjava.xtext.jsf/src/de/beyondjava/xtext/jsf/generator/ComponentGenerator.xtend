/*
 * generated by Xtext
 */
package de.beyondjava.xtext.jsf.generator

import de.beyondjava.xtext.jsf.componentLanguage.Attribute
import de.beyondjava.xtext.jsf.componentLanguage.AttributeList
import de.beyondjava.xtext.jsf.componentLanguage.Component
import de.beyondjava.xtext.jsf.formatting.JavaFormatter
import java.util.ArrayList
import java.util.Collections
import java.util.Comparator
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator

/**
 * Generates code from your model files on save.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class ComponentGenerator implements IGenerator {

	def collectAttributeLists(Resource resource) {
		var attributeLists = new HashMap()
		for (e : resource.allContents.toIterable.filter(AttributeList)) {
			attributeLists.put(e.name, e.attributes)
		}
		return attributeLists
	}

	def allAttributes(Component widget, Map<String, EList<Attribute>> lists) {
		var attributes = new ArrayList<Attribute>();
		for (e : widget.attributes) {
			attributes.add(e);
		}
		for (e : widget.attributeLists) {
			var list = lists.get(e)
			for (a : list) {
				attributes.add(a)
			}
		}
		Collections.sort(attributes, new Comparator<Attribute>() {
			override compare(Attribute o1, Attribute o2) {
				return o1.name.compareTo(o2.name)
			}

		})
		return attributes;
	}

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		var attributeLists = collectAttributeLists(resource)
		for (e : resource.allContents.toIterable.filter(Component)) {
			val platformString = resource.URI.toPlatformString(true);
			val myFile = ResourcesPlugin.getWorkspace().getRoot().getFile(new Path(platformString));
			val project = myFile.getProject();
			var generated = e.compile(attributeLists)
			var formatted = JavaFormatter.format(generated.toString, project);
			fsa.generateFile(
				"net/bootsfaces/component/" + e.name.toFirstLower + "/" + e.name.toFirstUpper + ".java",
				formatted
			)
		}
	}

	def compile(Component e, HashMap<String, EList<Attribute>> attributeLists) '''
		«e.generateCopyrightHeader»
		package net.bootsfaces.component.«e.name.toFirstLower»;

		import javax.el.ValueExpression;
		import javax.faces.application.ResourceDependencies;
		import javax.faces.application.ResourceDependency;
		import javax.faces.component.*;
		«IF e.hasTooltip!=null»
			import net.bootsfaces.render.Tooltip;
		«ENDIF»
		«IF e.hasTooltip!=null»
			import net.bootsfaces.render.IResponsive;
		«ENDIF»
		import net.bootsfaces.utils.BsfUtils;


		/** This class holds the attributes of &lt;b:«e.name» /&gt;. */
		@FacesComponent("net.bootsfaces.component.«e.name.toFirstLower».«e.name.toFirstUpper»")
		public class «e.name.toFirstUpper» extends «e.name.toFirstUpper»Core
		       «IF e.hasTooltip !=null || e.isReponsive != null» implements «ENDIF»
		       «IF e.hasTooltip !=null» net.bootsfaces.render.IHasTooltip «ENDIF»
		       «IF e.isReponsive!=null», net.bootsfaces.render.IResponsive «ENDIF» {

			«e.generateMetadata»
		}

	'''

	def parentClass(Component component) {
		if (component.extends != null) {
			return component.extends;
		}
		if (component.processesInput != null) {
			return "UIInput";
		}
		return "UIOutput";
	}

	def generateAccessors(
		Attribute e) '''

		/**
		 * «e.desc» <P>
		 * @return Returns the value of the attribute, or null, if it hasn't been set by the JSF file.
		 */
		public «e.attributeType» «e.getter» {
			return «optionalTypeCast(e)» («e.objectType»)getStateHelper().eval(«e.name.propertyKey.validIdentifier»«e.defaultValueTerm»);
		}

		/**
		 * «e.desc» <P>
		 * Usually this method is called internally by the JSF engine.
		 */
		public void set«e.name.toCamelCase.toFirstUpper»(«e.attributeType» _«e.name.toCamelCase») {
		    getStateHelper().put(«e.name.propertyKey.validIdentifier», _«e.name.toCamelCase»);
		}

	'''

	def validIdentifier(String s) {
		if ("for".equals(s)) {
			return "_for";
		}
		return s;
	}

	def getPropertyKey(String s) {
		if (s.propertyKeyValue.startsWith("\"")) {
			return s.propertyKeyValue;
		} else {
			return "PropertyKeys." + s.propertyKeyValue.validIdentifier;
		}

	}

	def getPropertyKeyValue(String s) {
		if (s == "static") {
			return "\"" + s + "\"";
		} else {
			return s.toCamelCase;
		}
	}

	def getDefaultValueTerm(Attribute a) {
		if (a.defaultValue != null && a.type == null)
			', "' + a.defaultValue + '"'
		else if (a.defaultValue != null && a.type == "String")
			', "' + a.defaultValue + '"'
		else if (a.defaultValue != null)
			', ' + a.defaultValue
		else if ("Integer".equals(a.type))
			', 0'
		else if("Boolean".equals(a.type)) ', false' else ''
	}

	def optionalTypeCast(Attribute e) {
		if(e.objectType != e.attributeType) '(' + e.attributeType + ')' else ''
	}

	def getGetter(Attribute f) {
		if ("Boolean".equals(f.type)) {
			'''is«f.name.toCamelCase.toFirstUpper»()'''
		} else {
			'''get«f.name.toCamelCase.toFirstUpper»()'''
		}
	}

	def getObjectType(Attribute a) {
		if(null == a.type) "String" else a.type;
	}

	def getAttributeType(Attribute a) {
		if (null == a.type)
			"String"
		else if ("Boolean".equals(a.type))
			"boolean"
		else if("Integer".equals(a.type)) "int" else a.type;
	}

	def generateMetadata(
		Component e) '''
		public static final String COMPONENT_TYPE = "net.bootsfaces.component.«e.name.toFirstLower».«e.name.toFirstUpper»";

		public static final String COMPONENT_FAMILY = "net.bootsfaces.component";

		public static final String DEFAULT_RENDERER = "net.bootsfaces.component.«e.name.toFirstLower».«e.name.toFirstUpper»";

		public «e.name.toFirstUpper»() {
		«IF e.hasTooltip!=null»
			«"    Tooltip.addResourceFiles();"»
		«ENDIF»
			AddResourcesListener.addThemedCSSResource("core.css");
			AddResourcesListener.addThemedCSSResource("bsf.css");
			setRendererType(DEFAULT_RENDERER);
		}

		public String getFamily() {
			return COMPONENT_FAMILY;
		}

		/**
		 * Manage EL-expression for snake-case attributes
		 */
		public void setValueExpression(String name, ValueExpression binding) {
			name = BsfUtils.snakeCaseToCamelCase(name);
			super.setValueExpression(name, binding);
		}
	'''

	def generateCopyrightHeader(Component e) '''
		/**
		 *  Copyright 2014-16 by Riccardo Massera (TheCoder4.Eu), Dario D'Urzo and Stephan Rauh (http://www.beyondjava.net).
		 *
		 *  This file is part of BootsFaces.
		 *
		 *  BootsFaces is free software: you can redistribute it and/or modify
		 *  it under the terms of the GNU Lesser General Public License as published by
		 *  the Free Software Foundation, either version 3 of the License, or
		 *  (at your option) any later version.
		 *
		 *  BootsFaces is distributed in the hope that it will be useful,
		 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
		 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		 *  GNU Lesser General Public License for more details.
		 *
		 *  You should have received a copy of the GNU Lesser General Public License
		 *  along with BootsFaces. If not, see <http://www.gnu.org/licenses/>.
		 */

	'''

	def List<Attribute> notInherited(List<Attribute> elements) {
		val result = newArrayList()
		elements.forEach [ a |
			if ((a.inherited == null) && (!a.name.propertyKeyValue.startsWith("\""))) {
				result.add(a)
			}
		]
		result
	}

	def generateProperties(Component e, HashMap<String, EList<Attribute>> attributeLists) '''
		    protected enum PropertyKeys {
		«FOR f : e.allAttributes(attributeLists).notInherited SEPARATOR ',' AFTER ';'»
			«"		"»«f.name.propertyKeyValue.validIdentifier»
		«ENDFOR»

		        String toString;

		        PropertyKeys(String toString) {
		    this.toString = toString;
		        }

		        PropertyKeys() {}

		        public String toString() {
		    return ((this.toString != null) ? this.toString : super.toString());
		        }
		    }
	'''

	def toCamelCase(String s) {
		var pos = 0 as int
		var cc = s
		while (cc.contains('-')) {
			pos = cc.indexOf('-');
			cc = cc.substring(0, pos) + cc.substring(pos + 1, pos + 2).toUpperCase() + cc.substring(pos + 2);
		}
		return cc
	}

}
