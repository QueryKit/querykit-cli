import Darwin.libc
import CoreData
import Commander
import PathKit
import Stencil


extension Path {
  static var processPath: Path {
    if Process.arguments[0].componentsSeparatedByString(Path.separator).count > 1 {
      return Path.current + Process.arguments[0]
    }

    let PATH = NSProcessInfo.processInfo().environment["PATH"]!
    let paths = PATH.componentsSeparatedByString(":").map {
      Path($0) + Process.arguments[0]
    }.filter { $0.exists }

    return paths.first!
  }

  public static var defaultTemplatePath: Path {
    return processPath + "../../share/querykit/template.swift"
  }
}


func compileCoreDataModel(source: Path) -> Path {
  let destinationExtension = source.`extension`!.hasSuffix("d") ? ".momd" : ".mom"
  let filename = source.lastComponentWithoutExtension + destinationExtension
  let destination = try! Path.uniqueTemporary() + Path(filename)
  system("xcrun momc \(source.absolute()) \(destination.absolute())")
  return destination
}

class AttributeDescription : NSObject {
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
      case .BooleanAttributeType:
        return "Bool"
      case .StringAttributeType:
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
  var qk_className: String {
    if managedObjectClassName.hasPrefix(".") {
      // "Current Module"
      return managedObjectClassName.substringFromIndex(managedObjectClassName.startIndex.successor())
    }

    return managedObjectClassName
  }

  func qk_hasSuperProperty(name: String) -> Bool {
    if let superentity = superentity {
      if superentity.qk_className != "NSManagedObject" && superentity.propertiesByName[name] != nil {
        return true
      }

      return superentity.qk_hasSuperProperty(name)
    }

    return false
  }
}

class CommandError : ErrorType {
  let description: String

  init(description: String) {
    self.description = description
  }
}

func render(entity: NSEntityDescription, destination: Path, template: Template) throws {
  let attributes = entity.properties.flatMap { property -> AttributeDescription? in
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

  let context = Context(dictionary: [
    "className": entity.qk_className,
    "attributes": attributes,
    "entityName": entity.name ?? "Unknown",
  ])

  try destination.write(try template.render(context))
}

func render(model: NSManagedObjectModel, destination: Path, templatePath: Path) throws {
  if !destination.exists {
    try destination.mkpath()
  }

  for entity in model.entities {
    let template = try Template(path: templatePath)
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

public func generate(model: Path, output: Path, template: Path) throws {
  let compiledModel = compileCoreDataModel(model)
  let modelURL = NSURL(fileURLWithPath: compiledModel.description)
  let model = NSManagedObjectModel(contentsOfURL: modelURL)!
  try render(model, destination: output, templatePath: template)
}

extension Path: ArgumentConvertible {
  public init(parser: ArgumentParser) throws {
    if let path = parser.shift() {
      self.init(path)
    } else {
      throw ArgumentError.MissingValue(argument: nil)
    }
  }
}

public func isReadable(path: Path) -> Path {
  if !path.isReadable {
    print("'\(path)' does not exist or is not readable.")
    exit(1)
  }

  return path
}

public func isCoreDataModel(path: Path) -> Path {
  let ext = path.`extension`
  if ext == "xcdatamodel" || ext == "xcdatamodeld" {
    return isReadable(path)
  }

  print("'\(path)' is not a Core Data model.")
  exit(1)
}
