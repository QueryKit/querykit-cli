#!/usr/bin/env xcrun swift -F Rome

import CoreData
import PathKit
import Stencil


extension Path {
  static var processPath:Path {
    if Process.arguments[0].componentsSeparatedByString(Path.separator).count > 1 {
      return Path.current + Process.arguments[0]
    }

    let PATH = NSProcessInfo.processInfo().environment["PATH"]!
    let paths = PATH.componentsSeparatedByString(":").map {
      Path($0) + Process.arguments[0]
    }.filter { $0.exists }

    return paths.first!
  }

  static var defaultTemplatePath:Path {
    return processPath + "../../share/querykit/template.swift"
  }
}


func compileCoreDataModel(source:Path) -> Path {
  let destinationExtension = source.`extension`!.hasSuffix("d") ? ".momd" : ".mom"
  let destination = try! Path.uniqueTemporary() + (source.lastComponentWithoutExtension + destinationExtension)
  system("xcrun momc \(source.absolute()) \(destination.absolute())")
  return destination
}

class AttributeDescription : NSObject {
  let name:String
  let type:String

  init(name:String, type:String) {
    self.name = name
    self.type = type
  }
}

extension NSAttributeDescription {
  var qkAttributeDescription:AttributeDescription? {
    if let className = attributeValueClassName {
      return AttributeDescription(name: name, type: className)
    }

    return nil
  }
}

extension NSRelationshipDescription {
  var qkAttributeDescription:AttributeDescription? {
    if let destinationEntity = destinationEntity {
      var type = destinationEntity.qk_className

      if toMany {
        type = "Set<\(type)>"

        if ordered {
          type = "NSOrderedSet"
        }
      }

      return AttributeDescription(name: name, type: type)
    }

    return nil
  }
}

extension NSEntityDescription {
  var qk_className:String {
    if managedObjectClassName.hasPrefix(".") {
      // "Current Module"
      return managedObjectClassName.substringFromIndex(managedObjectClassName.startIndex.successor())
    }

    return managedObjectClassName
  }
}

class CommandError : ErrorType {
  let description:String

  init(description:String) {
    self.description = description
  }
}

func render(entity:NSEntityDescription, destination:Path, template:Template) throws {
  let attributes = entity.properties.flatMap { property -> AttributeDescription? in
    if let attribute = property as? NSAttributeDescription {
      return attribute.qkAttributeDescription
    } else if let relationship = property as? NSRelationshipDescription {
      return relationship.qkAttributeDescription
    }

    return nil
  }

  let context = Context(dictionary: [
    "className": entity.qk_className,
    "attributes": attributes,
    "entityName": entity.name ?? "Unknown",
  ])

  switch template.render(context) {
  case .Success(let string):
    destination.write(string)
  case .Error(let error):
    throw CommandError(description: "Failed to render '\(entity.name): \(error).'")
  }
}

func render(model:NSManagedObjectModel, destination:Path, templatePath:Path) {
  if !destination.exists {
    do {
      try destination.mkdir()
    } catch {
      print("Failed to create directory: '\(destination)'.")
      return
    }
  }

  for entity in model.entities {
    let template = try! Template(path: templatePath)!
    let className = entity.qk_className

    if className == "NSManagedObject" {
      let name = entity.name ?? "Unknown"
      print("-> Skipping entity '\(name)', doesn't use a custom class.")
      continue
    }

    let destinationFile = destination + (className + "+QueryKit.swift")

    do {
      try render(entity, destination: destinationFile, template: template)
      print("-> Generated '\(className)' '\(destinationFile)'")
    } catch {
      print(error)
    }

  }
}

func run() {
  let arguments = Process.arguments

  if arguments.count == 3 {
    let modelPath = Path(arguments[1])
    let outputPath = Path(arguments[2])
    let modelExtension = modelPath.`extension`
    let isDataModel = modelExtension == "xcdatamodel"
    let isDataModeld = modelExtension == "xcdatamodeld"

    if isDataModel || isDataModeld {
      if modelPath.isReadable {
        let templatePath = Path.defaultTemplatePath
        if !templatePath.isReadable {
          print("Template '\(templatePath)' is not readable.")
        } else {
          let compiledModel = compileCoreDataModel(modelPath)
          let modelURL = NSURL(fileURLWithPath: compiledModel.description)
          let model = NSManagedObjectModel(contentsOfURL: modelURL)!
          render(model, destination: outputPath, templatePath: templatePath)
        }
      } else {
        print("'\(modelPath)' does not exist or is not readable.")
      }
    } else {
      print("'\(modelPath)' is not a Core Data model.")
    }
  } else {
    let processName = arguments[0]
    print("Usage: \(processName) <model> <output-directory>")
  }
}

run()

