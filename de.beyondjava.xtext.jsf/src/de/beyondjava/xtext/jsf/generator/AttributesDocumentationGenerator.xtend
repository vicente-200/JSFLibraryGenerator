/*
 * generated by XItext
 */
package de.beyondjava.xtext.jsf.generator

import de.beyondjava.xtext.jsf.componentLanguage.Attribute
import de.beyondjava.xtext.jsf.componentLanguage.AttributeList
import de.beyondjava.xtext.jsf.componentLanguage.Component
import java.io.File
import java.io.FileWriter
import java.net.URI
import java.util.ArrayList
import java.util.Collections
import java.util.Comparator
import java.util.HashMap
import java.util.Map
import org.eclipse.core.runtime.FileLocator
import org.eclipse.core.runtime.URIUtil
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccessExtension2
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.emf.common.util.EList

/**
 * Generates code from your model files on save.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class AttributesDocumentationGenerator implements IGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		var attributeLists = collectAttributeLists(resource)
		for (e : resource.allContents.toIterable.filter(Component)) {
			fsa.generateFile("net/bootsfaces/component/" + e.name.toFirstLower + "/" + e.name.toFirstUpper +
				"Attributes.xhtml", e.compile(attributeLists))
			var webProject = fsa.findWebProjectFolder
			if (null != webProject) {
				var targetFileAsString = e.name.findDocumentationFolder(webProject)
				if (null != targetFileAsString) {
					var targetFile = new File(targetFileAsString.toString)
					targetFile.delete();
					val writer = new FileWriter(targetFile)
					writer.append(e.compile(attributeLists).toString.replace("\t", "  "));
					writer.close();
				}
			}
		}
	}

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
			for (a:list) {
				attributes.add(a)
			}
		}
		Collections.sort(attributes, new Comparator<Attribute>(){
			override compare(Attribute o1, Attribute o2) {
				return o1.name.compareTo(o2.name)
			}

		})
		return attributes;
	}

	def findWebProjectFolder(IFileSystemAccess fsa) {
		var uri = (fsa as IFileSystemAccessExtension2).getURI("../../BootsFacesWeb/src/main/webapp");
		var eclipseURL = URIUtil.toURL(new URI(uri.toString()));
		var file = FileLocator.toFileURL(eclipseURL);
		var pathname = file.toString().replace("file:", "");
		if (new File(pathname).exists()) {
			return pathname;
		}
		return null;
	}

	def findDocumentationFolder(String widget, String pathname) {

		var docFolder = new File(pathname);
		if (docFolder.exists()) {
			var targetFolder = findDocumentationFolder(docFolder, widget);

			if (null != targetFolder) {
				return targetFolder;
			}
		}
		return null;
	}

	def findDocumentationFolder(File docFolder, String widget) {
		var files = docFolder.listFiles();
		for (File f : files) {
			if (f.isDirectory) {
				var target = findDocumentationFolder(f, widget);
				if (null != target) {
					return target;
				}
			} else {
				var filename = f.name;
				var targetFileName = widget.toFirstUpper + "Attributes.xhtml";
				if (targetFileName.equalsIgnoreCase(filename)) {
					return f.absolutePath;
				}

			}
		}
		return null;
	}

	def compile(Component widget, HashMap<String, EList<Attribute>> attributeLists) '''
<?xml version='1.0' encoding='UTF-8' ?>
<!DOCTYPE html>
<ui:fragment
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:h="http://java.sun.com/jsf/html"
	xmlns:f="http://java.sun.com/jsf/core"
	xmlns:b="http://bootsfaces.net/ui"
	xmlns:ui="http://java.sun.com/jsf/facelets">

		<b:panel look="info">
			<f:facet name="heading">
				<b>Attributes of &lt;b:«widget.name.toFirstLower» &gt;</b>
			</f:facet>
			<div class="table-responsive">
				<table class="table table-striped table-hover"
					style="background-color: #fff">
					<thead>
						<tr>
							<th>Attribute</th>
							<th>Default value</th>
							<th>Description</th>
						</tr>
					</thead>
					<tbody>
						«FOR f : widget.allAttributes(attributeLists)»
						  «f.generateAttribute»
						«ENDFOR»
					</tbody>
				</table>
			</div>
		</b:panel>
</ui:fragment>
	'''

	def generateAttribute(
		Attribute a) '''
		<tr>
		    <td>«a.name»«a.name.alternativeWriting»</td>
		    <td>«IF a.defaultValue!=null» «a.defaultValue» «ELSEIF a.type=="Boolean"»false«ELSEIF a.type=="Integer"»0 «ELSE»(none)«ENDIF»</td>
		    <td>«IF a.desc != null»«a.desc.replace("\\\"", "\"")»«ENDIF»</td>
		</tr>
	'''

	def alternativeWriting(String s) {
		if (s.contains('-')) {
			return "<br />" + toCamelCase(s) + " (alternative writing)"
		}
		return ""
	}

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
