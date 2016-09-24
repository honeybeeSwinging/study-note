#Xcode 相关概念
去年的时候有翻译过一篇关于同时在手机上面安装几个版本(Debug,Release,AppStore等)的[文章](http://joakimliu.github.io/2015/07/01/Translate-The-Blog-Post-Concurrent-Debug-Beta-and-App-Store-Builds/)，后面一直都没有实际操作过项目配置相关的东西，最近同事在搞自动化打包相关的东西，又增加了几个版本。所以想巩固下 Xcode 中的相关概念，所以把官方文档[Xcode Concepts](https://developer.apple.com/library/content/featuredarticles/XcodeConcepts/Concept-Targets.html)看了一篇，顺便翻译总结一下。先总结下概念性的东西， 后面再弄个实例。

##Xcode Target
`A target specifies a product to build and contains the instructions for building the product from a set of files in a project or workspace. A target defines a single product; it organizes the inputs into the build system—the source files and instructions for processing those source files—required to build that product. Projects can contain one or more targets, each of which produces one product.`

一个 target 就代表构建一个产品所需要的相关指令，构建产品所需的一套文件资源来自于 project 或者 workspace(下面会提到)。简单来说，一个 target 就定义了一个产品，它组织源文件以及构建产品所需要的进程指令到构建系统中。 Projects 可以包含一个或者多个 target，它们代表不同的产品(例如：如果你的产品需要做企业版和 AppStore 版本，那么你可以考虑采取两个 target 来处理)。

构建产品的指令采取构建设置(build settings)和构建参数(build phases)的形式来设置，这些都可以在Xcode的 project editor 中调整。一个 target 继承 project 构建设置，但是你可以通过在不同的 target 层级指定不同的设置来重载任何的 project 设置。同时间内只能有一个 active target，Xcode scheme 能够指定 active target。

一个 target 可以跟其他 target 相关联。如果一个 target 在构建的时候需要另外一个 target 的输出，我们说前者依赖于后者。如果两个 target 在相同的 workspace 里，Xcode 能够发现它们的从属关系，它能够以需要的顺序构建产品(即首先构建后者，再构建前者)。这样的关系可以被称为隐形从属依赖(implicit dependency)。当然你也可以在 build settings 
中指定它们的显性从属依赖(explicit dependency)，当你需要连接到不在同个 workspace 的 library 时，因为这个时候 Xcode 没法发现它们的依赖关系。


##Xcode Project
`An Xcode project is a repository for all the files, resources, and information required to build one or more software products. A project contains all the elements used to build your products and maintains the relationships between those elements. It contains one or more targets, which specify how to build products. A project defines default build settings for all the targets in the project (each target can also specify its own build settings, which override the project build settings).`

Xcode project 是个构建一个或者多个产品所需要的文件，资源，信息等的仓库。project 包含用于构建你产品的所有元素，并且管理这些元素间的关系。它包含一个或多个 target，指定怎样去构建产品。A project 在工程里面默认的为所有的 target 指定 build settings（每个 target 可以覆盖 project build settings，去指定自己特有的 build settings）。

一个 Xcode project 包含下面的信息：
* 源文件的引用：
  * 源码，包括头文件和实现文件
  * Libraries and frameworks, internal and external
  * 资源文件(plist等)
  * 图片文件
  * nib 文件(xib,故事版等)
* 采取分组的形式在工程结构导航中组织源文件(这里又分物理文件和引用文件)
* Project-level build configurations. 你可以为 project 指定多个 build configuration，例如，Xcode 就默认为我们指定了 debug 和 release 的 build settings，当然你也可以自定义个 AppStore build setting。
* Targets，每个 target 指定(前面 Xcode Target 已有提到)：
  * project 构建的一个 product 的引用
  * 构建 product 所需的资源文件的引用
  * build configuration 可以用于构建 product，包括和其他 targets 的附属依赖关系以及其他设置；project-level build settings 当 target's build configurations 没有覆盖它们的时候是可用的。
* 执行环境(executable environment)，debug 还是 test，每个执行环境指定：
  * 当你运行或者调试的时候，哪个可执行文件启动
  * 如果有的话，Command-line 参数传递给可执行文件
  * 如果有的话，当运行程序的时候，每一个环境变量都会被设置

A project 可以单独存在，也可以被包含在 workspace 里面(cocoapods 就是被包含在 workspace 里面)。

你用 Xcode scheme 去指定哪个 target，编译配置，可执行配置 在规定的时间(即运行的时候)是有效的。


##Build Settings
`A build setting is a variable that contains information about how a particular aspect of a product’s build process should be performed. For example, the information in a build setting can specify which options Xcode passes to the compiler.`

A build setting 是一个包含产品构建过程中指定某个特定方面需要被执行等相关信息的变量。例如，这个信息在传递给编译器的时候能够在 Xcode build setting 被指定。

你能够在 project 或者 target 层级指定 build settings。每个 project-level 的 build setting 都添加到 project 中的所有 target 里面，除非被某个特定 target 的 build setting 重载。（意思是，如果 target 中已经指定了相同的设置，那么 project 层级的就不会被添加，有点子类父类继承的概念。）

在 Xcode 中的 build setting 有两部分：title 和 definition。title 能够定义 build setting，能被其他设置使用。definition 是一个 Xcode 的常量或准则去决定在构建的时候使用哪个值。A build setting 可能会有一个 display name，用于在 Xcode 用户界面展示。

除了使用 project template 创建新工程被 Xcode 提供的默认构建设置以外，你可以为你的 project 或者特定的一个 target 创建 user-defined build setting。你还可以指定条件构建设置，条件构建设置的值取决于哪个先决条件是满足的。这种机制允许你，例如，指定 SDK 在一个特定的架构上面构建一个产品。


##Xcode Workspace
`A workspace is an Xcode document that groups projects and other documents so you can work on them together. A workspace can contain any number of Xcode projects, plus any other files you want to include. In addition to organizing all the files in each Xcode project, a workspace provides implicit and explicit relationships among the included projects and their targets.`

workspace 是一种 Xcode 文档，它组织 projects 和其他文档，这样你就可以在它们上面一起工作。一个 workspace 可以包含任何数量的 Xcode projects，添加其他你想要添加的其他文件。除了组织每个 Xcode project 中的所有文件外，workplace 还提供了包括 project 和它们的 targets 之间隐性和显性的关系。

###Workspaces Extend the Scope of Your Workflow
一个 project 文件包含指向工程中的所有文件，以及构建配置和其他工程信息。在 Xcode4 及以后，你可以选择创建一个 workspace 去管理一个或者多个 project ，添加其他你想要添加的文件。一个 project 可以属于多个 workspace。

![apple workspace_hierarchy](../Images/workspace_hierarchy.jpg)

###Projects in a Workspace Share a Build Directory
默认情况下，workspace 下面的 projects 都是在同一个目录下构建的，也就是 workspace 的编译目录(workspace build directory)。由于是在同一个目录下面，project 的资源文件都彼此都是可见的，可互相引用的。所以，如果你有多个 projects 使用相同库的时候，不需要将它分别拷贝到各个 project 中。

Xcode 会在编译目录下检查文件发现它们的隐形从属依赖。例如，如果 workspace 中的一个 project 编译的时候需要链接到相同 workspace 的其他 project 某个库，Xcode 会自动帮你先编译那个库，即使构建配置没有显式的指定从属依赖关系。如果需要的话，你可以指定显式从属依赖，但是你必须创建 project 引用。

workspace 中的每个 project 仍然有属于它们自己的独立的标识。你也可以单独打开某个 project 而没有必要打开 workspace，或者你也可以添加某个 project 到其他的 workspace。因为，一个 project 可以属于多个 workspace，你可以任意组合 projects，而无需重新配置 projects 或者 workspaces。


##Xcode Scheme
`An Xcode scheme defines a collection of targets to build, a configuration to use when building, and a collection of tests to execute.`
Xcode scheme 定义了构建的很多 targets，构建时的配置，以及需要执行的测试等。

你可以有多个你想要的 scheme，但是只有一个是有效的。我们可以指定一个 scheme 保存在 project(在 project 所属的 workspace 中也是有效的) 还是 workspace(只有当前 workspace 是有效的) 中。当你选择了 scheme 以后，也就意味着你选择了运行的目的（即哪个产品去构建）。





