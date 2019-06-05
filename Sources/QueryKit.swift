import Darwin.libc
import CoreData
import Commander
import PathKit
import Stencil


extension Path {
  static var processPath: Path {
    if ProcessInfo.processInfo.arguments[0].components(separatedBy: Path.separator).count > 1 {
      return Path.current + ProcessInfo.processInfo.arguments[0]
    }

    let PATH = ProcessInfo.processInfo.environment["PATH"]!
    let paths = PATH.components(separatedBy: ":").map {
      Path($0) + ProcessInfo.processInfo.arguments[0]
    }.filter { $0.exists }

    return paths.first!
  }

  public static var defaultTemplatePath: Path {
    return processPath + "../../share/querykit/template.swift"
  }
}


func compileCoreDataModel(_ source: Path) -> Path {
  let destinationExtension = source.`extension`!.hasSuffix("d") ? ".momd" : ".mom"
  let filename = source.lastComponentWithoutExtension + destinationExtension
  let destination = try! Path.uniqueTemporary() + Path(filename)
  
  Process.launchedProcess(
    launchPath: "/usr/bin/xcrun",
    arguments: ["momc", source.absolute().string, destination.absolute().string]
  ).waitUntilExit()
  
  return destination
}

struct AttributeDescription {
  let name: String
  let type: String

  init(name: String, type: String) {
    self.name = name
    self.type = type
  }
}

extension NSAttributeDescription {
  var qkClassName: String? {
    switch attributeType {
      case .booleanAttributeType:
        return "Bool"
      case .stringAttributeType:
        return "String"
      default:
        return attributeValueClassName
    }
  }

  var qkAttributeDescription: AttributeDescription? {
    if let className = qkClassName {
      return AttributeDescription(name: name, type: className)
    }

    return nil
  }
}

extension NSRelationshipDescription {
  var qkAttributeDescription: AttributeDescription? {
    if let destinationEntity = destinationEntity {
      var type = destinationEntity.qk_className

      if isToMany {
        type = "Set<\(type)>"

        if isOrdered {
          type = "NSOrderedSet"
        }
      }

      return AttributeDescription(name: name, type: type)
    }

    return nil
  }
}

extension NSEntityDescription {
  var qk_className: String {
    if managedObjectClassName.hasPrefix(".") {
      // "Current Module"
      return managedObjectClassName.substring(from: managedObjectClassName.index(after: managedObjectClassName.startIndex))
    }

    return managedObjectClassName
  }

  func qk_hasSuperProperty(_ name: String) -> Bool {
    if let superentity = superentity {
      if superentity.qk_className != "NSManagedObject" && superentity.propertiesByName[name] != nil {
        return true
      }

      return superentity.qk_hasSuperProperty(name)
    }

    return false
  }
}

class CommandError : Error {
  let description: String

  init(description: String) {
    self.description = description
  }
}

func render(entity: NSEntityDescription, destination: Path, template: Template) throws {
  let attributes = entity.properties.compactMap { property -> AttributeDescription? in
    if entity.qk_hasSuperProperty(property.name) {
      return nil
    }

    if let attribute = property as? NSAttributeDescription {
      return attribute.qkAttributeDescription
    } else if let relationship = property as? NSRelationshipDescription {
      return relationship.qkAttributeDescription
    }

    return nil
  }

  let context: [String: Any] = [
    "className": entity.qk_className,
    "isAbstract": entity.isAbstract,
    "attributes": attributes,
    "entityName": entity.name ?? "Unknown",
  ]

  try destination.write(try template.render(context))
}

func render(model: NSManagedObjectModel, destination: Path, templatePath: Path) throws {
  if !destination.exists {
    try destination.mkpath()
  }

  for entity in model.entities {
    let loader = FileSystemLoader(paths: [templatePath.parent().absolute()])
    let environment = Environment(loader: loader)
    let template = try environment.loadTemplate(name: templatePath.lastComponent)
    let className = entity.qk_className

    if className == "NSManagedObject" {
      let name = entity.name ?? "Unknown"
      print("-> Skipping entity '\(name)', doesn't use a custom class.")
      continue
    }

    let destinationFile = destination + (className + "+QueryKit.swift")

    do {
      try render(entity: entity, destination: destinationFile, template: template)
      print("-> Generated '\(className)' '\(destinationFile)'")
    } catch {
      print(error)
    }
  }
}

public func generate(model: Path, output: Path, template: Path) throws {
  let compiledModel = compileCoreDataModel(model)
  let modelURL = URL(fileURLWithPath: compiledModel.description)
  let model = NSManagedObjectModel(contentsOf: modelURL)!
  try render(model: model, destination: output, templatePath: template)
}

extension Path: ArgumentConvertible {
  public init(parser: ArgumentParser) throws {
    if let path = parser.shift() {
      self.init(path)
    } else {
      throw ArgumentError.missingValue(argument: nil)
    }
  }
}

public func isReadable(_ path: Path) -> Path {
  if !path.isReadable {
    print("'\(path)' does not exist or is not readable.")
    exit(1)
  }

  return path
}

public func isCoreDataModel(_ path: Path) -> Path {
  let ext = path.`extension`
  if ext == "xcdatamodel" || ext == "xcdatamodeld" {
    return isReadable(path)
  }

  print("'\(path)' is not a Core Data model.")
  exit(1)
}
