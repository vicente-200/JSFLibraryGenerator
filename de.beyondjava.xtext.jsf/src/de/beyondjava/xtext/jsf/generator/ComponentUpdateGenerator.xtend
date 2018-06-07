/*
 * generated by Xtext
 */
package de.beyondjava.xtext.jsf.generator

import de.beyondjava.xtext.jsf.componentLanguage.Component
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.io.IOException
import java.net.URI
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.FileLocator
import org.eclipse.core.runtime.Path
import org.eclipse.core.runtime.URIUtil
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IFileSystemAccessExtension2
import org.eclipse.xtext.generator.IGenerator
import de.beyondjava.xtext.jsf.formatting.JavaFormatter

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class ComponentUpdateGenerator implements IGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {

		insertAutoUpdateListener(resource, fsa);

		for (e : resource.allContents.toIterable.filter(Component)) {
			var generated = findGeneratedSourceFolder(fsa, e)
			var target = findSourceFolder(fsa, e)
			if (null != generated && null != target) {
				var generatedContent = readFile(generated)
				var contentToMerge = readFile(target)

				var index = contentToMerge.indexOf("protected enum PropertyKeys {")
				if (index > 0) {
					var start = contentToMerge.substring(0, index)
					index = generatedContent.indexOf("protected enum PropertyKeys {")
					if (index > 0) {
						var end = generatedContent.substring(index);
						var oldindex = contentToMerge.indexOf("protected enum PropertyKeys {")
						var oldEnd = contentToMerge.substring(oldindex);
						if (!end.withoutWhiteSpace().equals(oldEnd.withoutWhiteSpace())) {
							var merged = start + end;
							val platformString = resource.URI.toPlatformString(true);
							val myFile = ResourcesPlugin.getWorkspace().getRoot().getFile(new Path(platformString));
							val project = myFile.getProject();
							merged = JavaFormatter.format(merged, project);

							if (target.toString().endsWith("Core.java")) {
								fsa.generateFile(
									"../src/main/java/net/bootsfaces/component/" + e.name.toFirstLower + "/" +
										e.name.toFirstUpper + "Core.java", merged)
							} else {
								fsa.generateFile(
									"../src/main/java/net/bootsfaces/component/" + e.name.toFirstLower + "/" +
										e.name.toFirstUpper + ".java", merged)
							}
						}
					}
				}
			}

		}
	}

	def insertAutoUpdateListener(Resource resource, IFileSystemAccess fsa) {
		for (e : resource.allContents.toIterable.filter(Component)) {
			var autoUpdatable = false;
			for (a : e.attributes) {
				if (a.name == "auto-update") {
					autoUpdatable = true;
				}
			}

			if (autoUpdatable) {

				var filename = "../src/main/java/net/bootsfaces/component/" + e.name.toFirstLower + "/" +
					e.name.toFirstUpper + ".java";

				var target = findSourceFolderParentClass(fsa, e)
				System.out.println(target + " " + filename)
				if (null != target) {
					var modified = false;
					var contentToMerge = readFile(target)

					if (!contentToMerge.contains("@ListenerFor")) {
						var before = contentToMerge.indexOf("@FacesComponent");
						contentToMerge = contentToMerge.substring(0, before) +
							"@ListenersFor({ @ListenerFor(systemEventClass = PostAddToViewEvent.class) })\n" +
							contentToMerge.substring(before);
						modified = true;
					}

					if (!contentToMerge.contains("import javax.faces.event.AbortProcessingException;")) {
						var insert = '''
							import javax.faces.event.AbortProcessingException;
							import javax.faces.event.ComponentSystemEvent;
							import javax.faces.event.ListenerFor;
							import javax.faces.event.ListenersFor;
							import javax.faces.event.PostAddToViewEvent;
							
						'''
						var before = contentToMerge.indexOf("import ");

						contentToMerge = contentToMerge.substring(0, before) + insert +
							contentToMerge.substring(before);
						modified = true;
					}

					if (!contentToMerge.contains("processEvent")) {
						var insert = '''
							public void processEvent(ComponentSystemEvent event) throws AbortProcessingException {
									if (isAutoUpdate()) {
										if (FacesContext.getCurrentInstance().isPostback()) {
											FacesContext.getCurrentInstance().getPartialViewContext().getRenderIds().add(getClientId());
										}
							 	 		super.processEvent(event);
							 	 	}
								}
							
						'''
						var before = contentToMerge.indexOf("	protected enum PropertyKeys {");
						if (before < 0) {
							before = contentToMerge.indexOf("public String getFamily() {");
						}
						if (before < 0) {
							before = contentToMerge.lastIndexOf("}");
						}
						contentToMerge = contentToMerge.substring(0, before) + "	" + insert +
							contentToMerge.substring(before);
						modified = true;
					}
					if (modified) {
						fsa.generateFile(filename, contentToMerge)
					}

				}
			}
		}
	}

	def withoutWhiteSpace(String s) {
		var r = s.replace(" ", "");
		r = r.replace("\t", "");
		r = r.replace("\n", "");
		r = r.replace("\r", "");
		r = r.replace("*", ""); // ignore changes of Javadoc formatting
		return r;
	}

	def findGeneratedSourceFolder(IFileSystemAccess fsa, Component e) {
		var uri = (fsa as IFileSystemAccessExtension2).getURI(
			"net/bootsfaces/component/" + e.name.toFirstLower + "/" + e.name.toFirstUpper + "Core.java");
		var eclipseURL = URIUtil.toURL(new URI(uri.toString()));
		var file = FileLocator.toFileURL(eclipseURL);
		var pathname = file.toString().replace("file:", "");
		if (new File(pathname).exists()) {
			return pathname;
		}
		return null;
	}

	def findSourceFolderParentClass(IFileSystemAccess fsa, Component e) {
		var uri = (fsa as IFileSystemAccessExtension2).getURI(
			"../src/main/java/net/bootsfaces/component/" + e.name.toFirstLower + "/" + e.name.toFirstUpper + ".java");
		var eclipseURL = URIUtil.toURL(new URI(uri.toString()));
		var file = FileLocator.toFileURL(eclipseURL);
		var pathname = file.toString().replace("file:", "");
		if (new File(pathname).exists()) {
			return pathname;
		}

		return null;
	}

	def findSourceFolder(IFileSystemAccess fsa, Component e) {
		var uri = (fsa as IFileSystemAccessExtension2).getURI(
			"../src/main/java/net/bootsfaces/component/" + e.name.toFirstLower + "/" + e.name.toFirstUpper +
				"Core.java");
		var eclipseURL = URIUtil.toURL(new URI(uri.toString()));
		var file = FileLocator.toFileURL(eclipseURL);
		var pathname = file.toString().replace("file:", "");
		if (new File(pathname).exists()) {
			return pathname;
		}
		// provide for backward compatibility (0.8.1-SNAPSHOT didn't emply the ComponentCore.java files)
		pathname = pathname.replace("Core.java", ".java");
		if (new File(pathname).exists()) {
			return pathname;
		}
		return null;
	}

	def readFile(String filename) {
		var br = null as BufferedReader;
		var content = ""

		try {
			var sCurrentLine = null as String;
			br = new BufferedReader(new FileReader(filename));
			while ((sCurrentLine = br.readLine()) != null) {
				content += sCurrentLine + "\n";
			}

		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				if(br != null) br.close();
			} catch (IOException ex) {
				ex.printStackTrace();
			}
		}
		return content
	}
}
