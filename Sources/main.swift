import Darwin.libc
import PathKit
import Commander


let version = "0.2.0"

command(
  Option("template", Path.defaultTemplatePath, description: "Path to a custom template file", validator: isReadable),
  Argument<Path>("model", validator: isCoreDataModel),
  Argument<Path>("output", validator: isReadable)
) { template, model, output in
  do {
    try generate(model, output: output, template: template)
  } catch {
    print(error)
    exit(1)
  }
}.run(version)

