<img src="https://github.com/QueryKit/QueryKit/blob/master/QueryKit.png" width=96 height=120 alt="QueryKit Logo" />

__DEPRECATED__: _QueryKit CLI is no longer needed, QueryKit 0.14.0 works with
KeyPath, see https://github.com/QueryKit/QueryKit/pull/55._

# QueryKit CLI

A command line tool to generate extensions for your Core Data models
including QueryKit attributes for type-safe Core Data querying.
Allowing you to use Xcode generated managed object classes with QueryKit.

## Installation

Installation can be done via [Homebrew](http://brew.sh) as follows:

```shell
$ brew install querykit/formulae/querykit-cli
```

Alternatively, you can build it yourself with the Swift package manager.

```shell
$ git clone https://github.com/QueryKit/querykit-cli
$ cd querykit-cli
$ make install
```

## Usage

You can run QueryKit against your model providing the directory to save the
extensions.

```bash
$ querykit <modelfile> <directory-to-output>
```

### Example

We've provided an [example application](http://github.com/QueryKit/TodoExample) using QueryKit's CLI tool.

```
$ querykit Todo/Model.xcdatamodeld Todo/Model
-> Generated 'Task' 'Todo/Model/Task+QueryKit.swift'
-> Generated 'User' 'Todo/Model/User+QueryKit.swift'
```

QueryKit CLI will generate a `QueryKit` extension for each of your managed
object subclasses that you can add to Xcode, in this case `Task` and `User`.

These extensions provide you with properties on your model for type-safe filtering and ordering.

#### Task+QueryKit.swift

```swift
import QueryKit

extension Task {
  static var createdAt:Attribute<NSDate> { return Attribute("createdAt") }
  static var creator:Attribute<User> { return Attribute("creator") }
  static var name:Attribute<String> { return Attribute("name") }
  static var complete:Attribute<Bool> { return Attribute("complete") }
}

extension Attribute where AttributeType: Task {
  var creator:Attribute<User> { return attribute(AttributeType.creator) }
  var createdAt:Attribute<NSDate> { return attribute(AttributeType.createdAt) }
  var name:Attribute<String> { return attribute(AttributeType.name) }
  var complete:Attribute<Bool> { return attribute(AttributeType.complete) }
}
```

#### User+QueryKit.swift

```swift
import QueryKit

extension User {
  static var name:Attribute<String> { return Attribute("name") }
}

extension Attribute where AttributeType: User {
  var name:Attribute<String> { return attribute(AttributeType.name) }
}
```

We can use these properties in conjunction with QueryKit to build type-safe
queries. For example, here we are querying for all the Tasks which are
created by a user with the name `Kyle` which are completed, ordered
by their created date.

```swift
Task.queryset(context)
  .filter { $0.user.name == "Kyle" }
  .exclude { $0.completed == true }
  .orderBy { $0.createdAt.ascending }
```

### Customising

You may pass a custom template to the QueryKit tool, please see the standard
template for more information on the syntax.

```shell
$ querykit Todo/Model.xcdatamodeld Todo/Model --template share/querykit/template.swift
```

