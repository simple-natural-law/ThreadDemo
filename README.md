# 线程编程指南 -- 关于线程编程

多年来，计算机的最高性能在很大程度上受限于计算机内核中单个微处理器的运算速度。然而，随着单个处理器的运算速度开始达到其实际限制，芯片制造商开始使用多核设计来使计算机有机会同时执行多个任务。虽然OS X无论何时都在利用这些内核执行与系统相关的任务，但我们自己的应用程序也可以通过线程来利用这些内核。


## 什么是线程？

线程是在应用程序内部实现多个执行路径的相对轻量级的方式。在系统层面，程序并排运行，系统根据程序的需求和其他程序的需求为每个程序分配执行时间。但是在每个程序中，存在一个或多个可用于同时或以几乎同时的方式执行不同的任务的执行线程。系统本身实际上管理着这些执行线程，并调度它们到可用内核上运行。同时，还能根据需要提前中断它们以允许其他线程运行。

从技术角度讲，线程是管理代码执行所需的内核级和应用级数据结构的组合。内核级数据结构协调事件到达线程的调度和在某个可用内核上的线程的抢先调度。应用级数据结构包含用于存储函数调用的调用堆栈和应用程序需要用于管理和操作线程的属性和状态的结构。

在非并发的应用程序中，只有一个执行线程。该线程以应用程序的主例程开始和结束，并逐个分支到不同的方法或函数中，以实现应用程序的整体行为。相比之下，支持并发的应用程序从一个线程开始，并根据需要添加更多线程来创建额外的执行路径。每个新路径都有自己的独立于应用程序主例程中的代码运行的自定义启动例程。在应用程序中有多个线程提供了两个非常重要的潜在优势：
- 多个线程可以提高应用程序的感知响应能力。
- 多个线程可以提高应用程序在多核系统上的实时性能。

如果应用程序只有一个线程，那么该线程必须做所有的事情。其必须响应事件，更新应用程序的窗口，并执行实现应用程序行为所需的所有计算。只有一个线程的问题是它一次只能做一件事情。如果一个计算需要很长时间才能完成，那么当我们的代码忙于计算它所需的值时，应用程序会停止响应用户事件和更新其窗口。如果这种行为持续时间足够长，用户可能会认为我们的应用程序被挂起了并试图强行退出它。但是，如果将自定义计算移至单独的线程，则应用程序的主线程可以更及时地自由响应用户交互。

随着多核计算机的普及，线程提供了一种提高某些类型应用程序性能的方法。执行不同任务的线程可以在不同的处理器内核上同时执行，从而使应用程序可以在给定的时间内执行更多的工作。

当然，线程并不是解决应用程序性能问题的万能药物。线程提供的益处也会带来潜在的问题。在应用程序中执行多个路径可能会增加代码的复杂度。每个线程必须与其他线程协调行动，以防止它破坏应用程序的状态信息。由于单个应用程序中的线程共享相同的内存空间，所以它们可以访问所有相同的数据结构。如果两个线程试图同时操作相同的数据结构，则其中一个线程可能会以破坏数据结构的方式覆盖另一个线程的更改。即使有适当的保护措施，我们仍然需要对编译器优化保持注意，因为编译器优化会在我们的代码中引入细微的错误。

## 线程术语

在讨论线程及其支持技术之前，有必要定义一些基本术语。

如果你熟悉UNIX系统，则可能会发现本文档中的术语“任务”的使用有所不同。在UNIX系统中，有时使用术语“任务”来指代正在运行的进程。

本文档采用以下术语：
- 术语“线程”用于指代单独的代码执行路径。
- 术语“进程”用于指代正在运行的可执行文件，它可以包含多个线程。
- 术语“任务”用于指代需要执行的抽象工作概念。

## 线程的替代方案

自己创建线程的一个问题是它们会给代码添加不确定性。线程是一种相对较底层且复杂的支持应用程序并发的方式。如果不完全了解设计的含义，则可能会遇到同步或校时问题，其严重程度可能会从细微的行为变化到应用程序崩溃以及用户数据的损坏。

另一个要考虑的因素是是否需要线程或并发。线程解决了如何在同一进程中同时执行多个代码路径的具体问题。但是在有些情况下，并不能保证并发执行我们需要的工作。线程会在内存消耗和CPU时间方面为进程带来了巨大的开销。我们可能会发现这种开销对于预期的任务来说太大了，或者其他选项更容易实现。

下表列出了线程的一些替代方案。
| Technology | Description |
|---------------|--------------|
| Operation objects | 在OS X v10.5中引入的操作对象是通常在辅助线程上执行的任务的封装器。这个封装器隐藏了执行任务的线程管理方面，让我们可以自由地专注于任务本身。通常将操作对象与一个操作队列对象结合使用，操作队列对象实际上管理一个或多个线程上的操作对象的执行。 |
| Grand Central Dispatch (GCD) | 在OS X v10.6中引入的Grand Central Dispatch是线程的另一种替代方案，可以让我们专注于需要执行的任务而不是线程管理。使用GCD，我们可以定义要执行的任务并将其添加到工作队列中，该工作队列可以在适当的线程上处理我们的任务计划。工作队列会考虑可用内核的数量和当前负载，以便比使用线程更有效地执行任务。 |
| Idle-time notifications | 对于相对较短且优先级很低的任务，空闲时间通知让我们可以在应用程序不太忙时执行任务。Cocoa使用`NSNotificationQueue`对象为空闲时间通知提供支持。要请求空闲时间通知，请使用`NSPostWhenIdle`选项向默认`NSNotificationQueue`对象发布通知。队列会延迟通知对象的传递，直到run loop变为空闲状态。 |
| Asynchronous functions | 系统接口包含许多为我们提供自动并发性的异步功能。这些API可以使用系统守护进程和进程或者创建自定义线程来执行任务并将结果返回给我们。在设计应用程序时，寻找提供异步行为的函数，并考虑使用它们而不是在自定义线程上使用等效的同步函数。 |
| Timers | 可以在应用程序的主线程上使用定时器来执行相对于使用线程而言过于微不足道的定期任务，但是需要定期维护。 |
| Separate processes | 尽管比线程更加重量级，但在任务仅与应用程序切向相关的情况下，创建单独的进程可能很有用。如果任务需要大量内存或必须使用root权限执行，则可以使用进程。例如，我们可以使用64位服务器进程来计算大型数据集，而我们的32位应用程序会将结果显示给用户。 |

> **注意**：使用`fork`函数启动单独的进程时，必须使用与调用`exec`函数或类似函数相同的方式调用`fork`函数。依赖于Core Foundation，Cocoa或者Core Data框架（显式或隐式）的应用程序必须对`exec`函数进行后续调用，否则这些框架的行为可能会不正确。

## 线程支持

OS X和iOS系统提供了多种技术来在我们的应用程序中创建线程，并且还为管理和同步需要在这些线程上完成的工作提供支持。以下各节介绍了在OS X和iOS中使用线程时需要注意的一些关键技术。

### 线程组件

尽管线程的底层实现机制是Mach线程，但很少（如果有的话）在Mach层面上使用线程。相反，我们通常使用更方便的POSIX API或其衍生工具之一。Mach实现确实提供了所有线程的基本特征，包括抢先执行模型和调度线程使它们彼此独立的能力。

下表列出了可以在应用程序中使用的线程技术。

| Technology | Description |
|--------------|---------------|
| Cocoa threads | Cocoa使用`NSThread`类实现线程。Cocoa也在`NSObject`类中提供了方法来生成新线程并在已经运行的线程上执行代码。 |
| POSIX threads | POSIX线程提供了基于C语言的接口来创建线程。如果我们不是在编写一个Cocoa应用程序，则这是创建线程的最佳选择。POSIX接口使用起来相对简单，并为配置线程提供了足够的灵活性。 |
| Multiprocessing<br>Services | Multiprocessing Services（多处理服务）是传统的基于C语言的接口，其被从旧版本Mac OS系统中过渡来的应用程序所使用。这项技术仅适用于OS X，应该避免在任何新的开发中使用它。相反，应该使用`NSThread`类或者POSIX线程。 |

启动线程后，线程将以三种主要状态中的一种来运行：运行中，准备就绪或者阻塞。如果一个线程当前没有运行，那么它可能处于阻塞状态并等待输入，或者它已准备好运行，但尚未安排执行。线程持续在这些状态之间来回切换，直到它最终退出并切换到终止状态。

当创建一个新的线程时，必须为该线程指定一个入口函数（或者Cocoa线程的入口方法）。这个入口函数构成了我们想要在线程上运行的代码。当函数返回时，或者当我们明确终止线程时，该线程会永久停止并被系统回收。由于线程的创建在内存和时间方面相当昂贵，所有建议在入口函数中执行大量工作或者设置run loop以允许执行重复性工作。

### Run Loop

run loop（运行循环）是用于管理事件异步到达线程的基础架构的一部分。run loop通过监听线程的一个或者多个事件源来工作。当事件到达时，系统会唤醒线程并调度事件到run loop，run loop再调度这些事件给我们指定的处理程序。如果没有事件存在，也没有事件准备好被处理，则run loop将线程置于休眠状态。

不需要在创建任何线程时都使用run loop，但使用run loop可以为用户提供更好的体验。run loop使得创建使用最少量资源的长期存活线程成为可能。因为在没有事件传入时，run loop会将线程置于休眠状态。所以它不需要执行浪费CPU周期的轮询，并能防止处理器本身进入休眠状态来节省功耗。

要配置run loop，只需要启动线程，获取对run loop对象的引用，然后安装事件处理程序并告知run loop开始运行。OS X提供的基础架构自动帮我们处理主线程run loop的配置。如果打算创建长期存活的辅助线程，则必须自行为这些线程配置run loop。

### 同步工具

线程编程的一个风险是多线程之间的资源争夺。如果多个线程同时试图使用或修改相同的资源，则可能会出现问题。缓解问题的一种方法是完全避免共享资源，并确保每个线程都操作自己独特的资源集合。但是当保持完全独立的资源不能满足需求时，可以使用锁，条件，原子操作和其他技术来同步对资源的访问。

锁为一次只能由一个线程执行的代码提供了蛮力形式的保护。最常见的锁是互斥锁。当一个线程试图获取另一个线程当前拥有的互斥锁时，该线程会被阻塞，直到另一个线程释放该互斥锁。一些系统框架为互斥锁提供了支持，尽管它们都基于相同的基础技术。另外，Cocoa提供了互斥锁的几种变体来支持不同类型的行为，例如递归。

除了锁之外，系统还为条件（condition）提供支持，以确保在应用程序中对任务进行正确排序。条件充当守门人，阻塞指定的线程，知道它所代表的条件变为`ture`。当这种情况发生时，条件释放线程并运行其继续运行。POSIX层和Foundation框架都为条件提供了直接支持。（如果使用操作对象，则可以配置操作对象之间的依赖关系来对任务的执行排序，这与条件提供的行为非常相似。）

虽然锁和条件在并发设计中非常常见，但原子操作是保护和同步数据访问的另一种方式。当对标量数据类型进行数学或逻辑运算时，原子操作提供了一种轻量级的替代锁的方案。原子操作使用特殊的硬件指令来确保在其他线程有机会访问变量之前完成对该变量的修改。

### 线程间通信

尽管一个好的设计可以最大限度地减少所需的通信次数，但是在某些时候，线程之间的通信是必要的。线程可能需要处理新的工作请求或者将工作进度报告给应用程序的主线程。在这些情况下，我们需要一种从一个线程向另一个线程获取信息的方法。幸运的是，线程共享相同进程空间的事实意味着我们有很多通信选项。

线程之间的通信方式有许多种，每种方式都有自己的优点和缺点。下表列出了可以在OS X中使用的最常用的通信机制（除了消息队列和Cocoa分布式对象，其他技术在iOS中也可用。），此表中的技术按照复杂性增加的顺序列出。

| 机制 | 描述 |
|-------|------|
| 直接传递消息 | Cocoa应用程序支持直接在其他线程上执行方法选择器的功能。这个能力意味着一个线程实质上可以在任何其他线程上执行一个方法。由于它们是在目标线程的上下文中执行的，所以以这种方式发送的消息会自动在该线程上序列化。 |
| 全局变量，共享内存和对象 | 在两个线程之间传递信息的另一种简单方法是使用全局变量，共享对象或共享内存块。虽然共享变量很快很简单，但它们比直接传递消息更脆弱。共享变量必须用锁或其他同步机制来小心保护，以确保代码的正确性。不这样做可能会导致竞争状况，数据损坏或者崩溃。 |
| 条件 | 条件是一个同步工具，可以使用它来控制线程何时执行代码的特定部分。可以将条件视为守门员，让线程只有在符合条件时才能运行。 |
| Run loop sources | 自定义run loop source是为了在线程上接收专用消息而设置的。因为它们是事件驱动的，所以当没有任何事件可以执行时，run loop source会将线程置于休眠状态，这可以提高线程的效率。 |
| Ports and sockets | 基于端口的通信是两个线程之间通信的更复杂的方式，但它是一种非常可靠的技术。更重要的是，端口和套接字可用于与外部实体（如其他进程和服务）进行通信。为了提高效率，端口是使用run loop source实现的，所以当没有数据在端口上等待时，线程会休眠。 |
| 消息队列 | 传统的多处理服务定义了用于管理传入和传出数据的先进先出（FIFO）的队列抽象概念。尽管消息队列简单方便，但并不像其他通信技术那样高效。 |
| Cocoa分布式对象 | 分布式对象是一种Cocoa技术，提供基于端口通信的高级实现。尽管有可能使用这种技术进行线程间通信，但是由于其产生的开销很大，所以并不鼓励这样做。分布式对象更适用于与其他进程进行通信，其中进程之间的开销已经很高。 |

## 设计技巧

### 避免明确地创建线程

手动编写线程创建代码非常繁琐而且可能容易出错，应该尽量避免这样做。OS X和iOS其他API为并发提供隐式支持。可以考虑使用异步API，GCD或操作对象来完成工作，而不是自己创建线程。这些技术在幕后做与线程相关的工作，并保证正确执行。另外，像GCD和操作对象这样的技术可以根据当前系统负载调整当前活跃线程的数量，从而比我们自己的代码更高效地管理线程。

### 合理地保持我们的线程处于忙碌状态

如果决定手动创建和管理线程，请记住线程会占用宝贵的系统资源。应该尽最大努力确保分配给线程的任何任务是长期存活的和能工作的。同时，不应该害怕终止那些大多数时间处于闲置状态的线程。线程会占用大量的内存，因此释放一个空闲线程不仅有助于减少应用程序的内存占用量，还可以释放更多物理内存供其他系统进程使用。

> **提示**：在开始终止空闲线程之前，应该始终记录应用程序当前性能的一组基础测量结果。在尝试更改之后，请进行其他测量以验证这些更改是否实际上改善了性能，而不是损害了性能。

### 避免共享数据结构

避免与线程相关的资源冲突的最简单和最容易的方法是为程序中的每个线程提供它所需的任何数据的副本。当我们最小化线程间的通信和资源竞争时，并行代码的工作效果最佳。

创建多线程应用程序非常困难。即使我们非常小心并且在代码中在所有正确的时刻锁定了共享的数据结构，我们的代码仍然可能在语义上是不安全的。例如，如果希望共享数据结构按照特定顺序修改，我们的代码可能会遇到问题。将代码更改为基于交易的模型以进行补偿随后可能让具有多个线程的性能优势消失。首先消除资源争夺会让设计更加简单并且性能优异。

### 线程和我们的用户界面

如果应用程序具有图形用户界面，则建议从应用程序的主线程接收与用户相关的事件并启动界面更新。这种途径有助于避免与处理用户事件和绘制窗口内容相关的同步问题。一些框架，例如Cocoa，通常需要这种行为，但即使对于那些不这样做的行为，在主线程上保持这种行为也有简化用于管理用户界面的逻辑的优点。

有一些值得注意的例外是从其他线程执行图形操作是有利的。例如，可以使用辅助线程来创建和处理图像并执行其他图像相关的计算。使用辅助线程进行这些操作可以大大提高性能。如果不确定特定的图形操作，请在主线程执行此操作。

### 在退出时知道线程行为

一个进程运行直到所有非分离线程退出。默认情况下，只有应用程序的主线程是非分离的，但是也可以创建其他的非分离线程。当用户退出应用程序时，通常被认为是适当的行为是立即终止所有分离线程，因为分离线程完成的工作被认为是可选的。然而，如果我们的应用程序使用后台线程将数据保存到磁盘或者执行其他关键工作，则可能需要创建非分离线程，以防止应用程序退出时丢失数据。

创建非分离（也称为可连接）线程需要额外的工作。由于大多数高级线程技术在默认情况下不会创建可连接线程，所以我们可能必须使用POSIX API来创建线程。另外，我们必须添加代码到应用程序的主线程，以便主线程最终退出时将其与非分离线程连接起来。

如果我们正在编写一个Cocoa应用程序，则也可以使用`applicationShouldTerminate:`代理方法来延迟应用程序的终止直到以后某个时间或者完全取消延迟。当延迟应用程序的终止时，应用程序需要等待直到任何临界线程完成其任务，然后调用`replyToApplicationShouldTerminate:`方法。

### 处理异常

当抛出一个异常时，异常处理机制依赖于当前的调用堆栈来执行任何必要的清理。因为每个线程都有自己的调用堆栈，所以每个线程都负责捕获它自己的异常。当拥有的进程已经终止，在主线程和辅助线程中都是无法捕获到异常的。我们不能将一个未捕获的异常抛出到不同的线程进行处理。

如果需要通知另一个线程（例如主线程）当前线程中的异常情况，则应该捕获该异常并简单地向另一个线程发送消息表明发生了什么。取决于我们的模型以及我们试图执行的操作，捕获异常的线程可以继续处理（如果可能的话）、等待指令或者干脆退出。

> **注意**：在Cocoa中，`NSException`对象是一个自包含的对象，一旦它被捕获，它就可以从一个线程传递到另一个线程。

在某些情况下，可能会为我们自动创建异常处理程序。例如，Objective-C中的`@synchronized`指令包含一个隐式异常处理程序。

### 干净地终止我们的线程

让线程自然退出的最好方式是让其到达主入口点工作的末尾。虽然有函数能够立即终止线程，但这些函数只能作为最后的手段使用。在线程到达其自然终点之前终止它会阻止线程清理自身。如果线程已经分配内存、打开文件或者获取其他类型的资源，则我们的代码可能无法回收这些资源，从而导致内存泄露或者其他潜在问题。

### 库（Library）中的线程安全

虽然应用程序开发者可以控制应用程序是否使用多个线程执行，但库开发人员却不行。开发库时，我们必须假定调用库的应用程序是多线程的或者可以随时切换为多线程的。因此，我们应该始终为代码的临界区使用锁。

对于库开发人员来说，仅在应用程序变为多线程时才创建锁是不明智的。如果我们需要在某个时刻锁定我们的代码，请在使用库时尽早创建锁对象，最好在某个显示调用中初始化库。虽然也可以使用静态库初始化函数来创建此类锁，但只有在没有其他方式时才尝试这样做。初始化函数的执行会增加加载库所需的时间，并可能对性能产生负面影响。

> **注意**：始终记住锁定和解锁库中的互斥锁的调用要保持平衡，还应该记住要锁定库数据结构，而不是依赖调用代码来提供线程安全的环境。

如果我们正在开发一个Cocoa库并希望应用程序在变为多线程时能够收到通知，可以为`NSWillBecomeMultiThreadedNotification`通知注册一个观察者。但不应该依赖收到此通知，因为在我们的库代码被调用之前，可能已经发送了此通知。


# 线程编程指南 --  线程管理

OS X和iOS中的每个进程（应用程序）都由一个或多个线程组成，每个线程代表通过应用程序的代码执行的单个路径。每个应用程序都以单个线程开始，该线程运行应用程序的主要功能。应用程序可以创建额外的线程，这些线程执行特定功能的代码。

当一个应用程序创建一个新的线程时，该线程将成为应用程序进程空间内的一个独立的实体。每个线程都有其自己的执行堆栈，并由内核独立调度运行时间。一个线程可以与其他线程和其他进程通信，执行I/O操作和执行其他任何我们可能需要的操作。但是，由于它们在同一个进程空间内，所以单个应用程序中的所有线程共享相同的虚拟内存空间，并具有与进程本身相同的访问权限。

本章提供了OS X和iOS中可用线程技术的概述以及如何在应用程序中使用这些技术的示例。

## 线程开销

线程在内存使用和性能方面对应用程序（和系统）有实际的成本。每个线程会在内核内存空间和程序的内存空间中请求内存分配。管理线程和协调线程调度所需的核心结构使用wired memory存储在内核中。线程的堆栈空间和per-thread数据存储在应用程序的内存空间中。当我们首次创建线程时，这些结构的大多数才会被创建并初始化。由于必需的与内核的交互，进程可能相对更昂贵。

下表量化了与在应用程序中创建新的用户级别的线程相关的大概成本。其中一些成本是可配置的，例如为辅助线程分配的堆栈空间数量。创建线程的时间成本是一个粗略的近似值，应仅用于相互比较。创建线程的时间成本可能因处理器负载、 计算机的速度以及可用系统和程序内存的数量而有很大的差异。

| Item | Approximate | Notes |
|-------|----------------|--------|
| 内核数据结构 | 大约1 KB | 该内存用于存储线程数据结构和属性，其中大部分分配为wired memory，因此无法被分页到磁盘。 |
| 堆栈空间 | 512 KB（辅助线程）<br>8 MB（OS X 主线程）<br>1 MB（iOS 主线程） | 辅助线程允许的最小堆栈大小为16 KB，堆栈大小必须是4 KB的倍数。这个内存的空间在创建线程的时候被放置在进程空间中，但是与该内存相关联的实际页面只有在需要的时候才会被创建。 |
| 创建耗时 | 大约90微秒 | 该值反映了创建线程的初始调用到线程入口点开始执行的时间间隔。该数据是通过分析在基于Intel的使用2 GHz Core Duo处理器和运行OS X v10.5 的RAM为1 GB的iMac上创建线程时生成的平均值和中值而确定的。 |

> **注意**：由于底层内核的支持，操作对象通常可用更快地创建线程。它们不是每次都从头开始创建线程，而是使用已驻留在内核中的线程池来节省分配时间。有关如何使用操作对象的更多信息，请参看[Operation Queues](https://www.jianshu.com/p/65ab102cac60)。

编写线程代码时需要考虑的另一个成本是生产成本。设计线程应用程序有时可能需要对组织应用程序数据结构的方式进行根本性更改。为了避免同步的使用，进行这些更改可能是必要的。这些更改可能会对设计不当的应用程序带来巨大的性能损耗。设计这些数据结构和调试线程代码中的问题可能会增加开发线程应用程序所需的时间。但是，避免这些成本会在运行时产生更大的问题。

## 创建线程

创建低级线程相对简单。在任何情况下，都必须有一个函数或者方法来充当线程的主入口点，并且必须使用可用线程例程中的一个来启动线程。以下部分显示了更常用的线程技术的基本创建过程。使用这些技术创建的线程将继承默认的一组属性，这些属性由我们使用的技术决定。

### 使用NSThread

有两种使用`NSThread`类创建一个线程的方法：
- 使用`detachNewThreadSelector:toTarget:withObject:`类方法来生成新的线程。
- 创建一个新的`NSThread`对象并调用其`start`方法。（仅在iOS和OS X v10.5之后支持。）

这两种技术都会在应用程序中创建一个分离线程。分离线程意味着线程退出时线程的资源会被系统自动回收。

因为`detachNewThreadSelector:toTarget:withObject:`方法在所有版本的OS X中都受支持，所以在现有的使用线程的Cocoa应用程序中经常会见到它。要分离一个新线程，只需提供想要用作线程入口点的方法名称（指定为选择器）、 定义该方法的对象以及要在启动时传递给线程的任何数据。以下示例显示了此方法的基本调用，该方法使用当前对象的自定义方法生成线程。
```
[NSThread detachNewThreadSelector:@selector(myThreadMainMethod:) toTarget:self withObject:nil];
```
在OS X v10.5之前，主要使用`NSThread`类来生成线程。虽然我们可以得到一个`NSThread`对象并访问一些线程属性，但是只能在线程本身运行后才能这样做。在OS X v10.5中，添加了用于创建`NSThread`对象而不立即生成相应的新线程的支持。（此支持在iOS中也可用。）此支持使得在启动线程之前可以获取和设置各种线程属性成为可能，它还使得可以使用该线程对象稍后引用正在运行的线程成为可能。

在OS X v10.5及更高版本中初始化`NSThread`对象的简单方法是使用`initWithTarget:selector:object:`方法。此方法使用与` detachNewThreadSelector:toTarget:withObject:`方法完全相同的信息来初始化新的`NSThread`实例。但是，它不会立即启动线程。要启动线程，请明确调用线程对象的`start`方法，如下所示：
```
NSThread* myThread = [[NSThread alloc] initWithTarget:self selector:@selector(myThreadMainMethod:) object:nil];

[myThread start];  // Actually create the thread
```
> **注意**：一种使用`initWithTarget:selector:object:`方法的替代方案是对`NSThread`进行子类化并覆写其`main`方法。可以使用`main`方法的重写版本来实现线程的主入口点。更多信息，请参看[NSThread Class Reference](https://developer.apple.com/documentation/foundation/thread)。

如果我们有一个其当前线程正在运行的`NSThread`对象，则一种发送消息到该线程的方法是使用应用程序中几乎任何对象的`performSelector:onThread:withObject:waitUntilDone:`方法。在OS X v10.5中引入了对线程（主线程除外）执行选择器的支持，这是在线程之间进行通信的便捷方式。（此支持在iOS中也可用。）使用该技术发送的消息由其他线程直接执行，作为目标线程正常运行循环处理的一部分。（当然，这意味着目标线程必须在其run loop中运行。）当我们以这种方式进行通信时，可能仍然需要某种形式的同步，但它比在线程之间设置端口要简单。

> **注意**：虽然`performSelector:onThread:withObject:waitUntilDone:`方法适用于线程之间的偶尔通信，但不应该使用该方法来处理线程之间的时间至关重要或频繁的通信。

### 使用 POSIX 线程

OS X和iOS为使用POSIX线程API来创建线程提供了基于C语言的支持。该技术实际上可以用于任何类型的应用程序（包括Cocoa和Cocoa Touch应用程序），如果我们正在为多个平台编写软件，该技术可能会更方便。

以下代码显示了两个使用POSIX调用的自定义函数。LaunchThread函数创建一个新的线程，其主例程在PosixThreadMainRoutine函数中实现。由于POSIX默认将线程创建为可连接，因此此示例更改了线程的属性来创建分离线程。将线程标记为分离，可以让系统在该线程退出时立即回收资源。
```
#include <assert.h>
#include <pthread.h>

void* PosixThreadMainRoutine(void* data)
{
    // Do some work here.

    return NULL;
}

void LaunchThread()
{
    // Create the thread using POSIX routines.
    pthread_attr_t  attr;
    pthread_t       posixThreadID;
    int             returnVal;

    returnVal = pthread_attr_init(&attr);
    assert(!returnVal);
    returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    assert(!returnVal);

    int     threadError = pthread_create(&posixThreadID, &attr, &PosixThreadMainRoutine, NULL);

    returnVal = pthread_attr_destroy(&attr);
    assert(!returnVal);
    if (threadError != 0)
    {
        // Report an error.
    }
}
```
如果将以上代码添加到某个源文件并调用LaunchThread函数，这样会在应用程序中创建一个新的分离线程。当然，使用这段代码创建的新线程不会做任何有用的事情。线程将启动并立即退出。为了使事情更有趣，我们需要将代码添加到PosixThreadMainRoutine函数中以完成一些实际工作。为了确保线程知道要做什么工作，可以在创建时传递一些数据的指针给它。将此指针作为`pthread_create`函数的最后一个参数传递。

为了将新创建的线程的信息传递回应用程序的主线程，需要在目标线程之间建立通信路径。对于基于C的应用程序，线程之间有多种通信方式，包括使用端口、 条件或共享内存。对于长寿命的线程，几乎总是应该建立某种线程间通信机制，以便让应用程序的主线程检查线程的状态或者在应用程序退出时干净地关闭线程。

### 使用NSObject来生成一个线程

在iOS和OS X v10.5及更高版本中，所有对象都能够生成一个新线程，并使用该线程来执行对象的方法中的一个。`performSelectorInBackground:withObject:`方法创建一个新的分离线程，并使用指定的方法作为该线程的入口点。例如，如果我们有一些对象（由变量myObj表示），并且这些对象有一个名为doSomething的方法，我们想要在后台线程中运行该方法，则可以使用以下代码执行此操作：
```
[myObj performSelectorInBackground:@selector(doSomething) withObject:nil];
```
调用此方法的效果与将当前对象、选择器和参数对象作为参数调用`detachNewThreadSelector:toTarget:withObject:`方法的效果相同。会立即使用默认配置生成新线程，并启动运行新线程。在选择器内部，必须像任何线程一样配置线程。例如，需要设置一个自动释放池并且配置线程的run loop（如果打算使用它的话）。

### 在Cocoa应用程序中使用POSIX线程

虽然`NSThread`类是在Cocoa应用程序中创建线程的主要接口，但是我们也可以自由使用POSIX线程（如果这样做更加方便的话）。如果打算在Cocoa应用程序中使用POSIX线程，仍然应该了解Cocoa和线程之间的交互，并遵循以下部分的指导原则。

#### 保护Cocoa框架

对于多线程的应用程序，Cocoa框架使用锁和其他形式的内部同步来确保它们的行为正确。但是，为了防止这些锁在单线程的情况下降低性能，Cocoa不会在应用程序使用`NSThread`类生成其第一个新线程之前创建它们。如果我们仅使用POSIX线程例程生成新线程，则Cocoa不会收到告知它我们的应用程序现在是多线程的通知。当发生这种情况时，涉及Cocoa框架的操作可能会破坏应用程序的稳定性或者崩溃。

为了让Cocoa知道我们打算使用多线程，需要使用`NSThread`类生成一个单线程，并让该线程立即退出，线程入口点不需要做任何事情。使用`NSThread`生成线程的行为足以确保创建Cocoa框架所需的锁。

如果不确定Cocoa是否认为我们应用程序是多线程的，则可以使用`NSThread`的`isMultiThreaded`方法进行检查。

#### 混合使用POSIX和Cocoa锁

在同一个应用程序中混合使用POSIX和Cocoa锁是安全的。Cocoa锁和条件对象本质上只是POSIX互斥锁和条件的包装器。但是，对于给定的锁，必须使用相同的接口来创建和操作该锁。换句话说，不能使用Cocoa NSLock对象来操作使用`pthread_mutex_init`函数创建的互斥锁，反之亦然。

## 配置线程属性

在创建线程之后（有时在之前），可能需要配置线程环境的不同部分。以下各节介绍了可以进行的一些更改以及何时可以进行更改。

### 配置线程的堆栈大小

对于我们创建的每个新线程，系统都会在我们的进程空间中分配特定数量的内存来充当该线程的堆栈。堆栈管理栈帧，也是声明线程的任何局部变量的地方。分配给线程的内存数量在[线程开销](turn)已列出。

如果想要更改给定线程的堆栈大小，则必须在创建线程之前执行此操作。虽然使用`NSThread`设置堆栈大小仅适用于iOS和OS X v10.5及更高版本，但是所有线程技术都提供了一些设置堆栈大小的方法。下表列出了每种技术的不同选项。

| Technology | Option |
|---------------|---------|
| Cocoa | 在iOS和OS X v10.5及更高版本中，分配并初始化一个`NSThread`对象（不要使用`detachNewThreadSelector:toTarget:withObject:`方法）。在调用线程对象的`start`方法之前，请使用`setStackSize:`方法来指定新的堆栈大小。 |
| POSIX | 创建一个新的`pthread_attr_t`结构体并使用`pthread_attr_setstacksize`函数更改默认堆栈大小。创建线程时，将属性传递给`pthread_create`函数。 |
| Multiprocessing Services | 在创建线程时将相应的堆栈大小值传递给`MPCreateTask`函数。 |

### 配置线程局部存储

每个线程维护着一个可以从任何位置访问的键-值对的字典。可以使用此字典来存储希望在整个线程执行期间都存在的信息。例如，我们可以使用它通过线程的run loop的多次迭代来保存状态信息。

Cocoa和POSIX以不同的方式存储线程字典，所以不能混合和匹配这两种技术。但是，只要在线程代码中坚持使用一种技术，最终结果应该是相似的。在Cocoa中，使用`NSThread`对象的`threadDictionary`方法来检索一个`NSMutableDictionary`对象，可以向其中添加线程所需的任何key。在POSIX中，使用`pthread_setspecific`和`pthread_getspecific`函数来设置和获取线程的key和value。

### 设置线程的分离状态

大多数高级线程技术默认创建分离的线程。在大多数情况下，分离线程是首选，因为它们运行系统在线程完成其工作后立即释放线程的数据的数据结构。分离线程也不需要与应用程序进行明确地交互，这意味着是否从线程中检索结果由我们自行决定。相比之下，系统不会回收可连接线程的资源，直到另一个线程显示地与该线程连接，并且进程可能会阻塞执行连接的线程。

可以考虑将可连接线程看作类似于子线程。虽然它们仍然作为独立线程运行，但可连接线程必须由另一个线程在其资源可能被系统回收之前连接。可连接线程还提供了一种方式将数据从一个正在退出的线程传递到另一个线程。在线程退出之前，可连接线程可以将数据指针或其他返回值传递给`pthread_exit`函数。然后另一个线程可以通过调用`pthread_join`函数来获取这些数据。

> **重要提示**：在应用程序退出时，分离线程会被立即终止，但是可连接线程不会被立即终止。每个可连接线程必须在允许退出进程之前连接。所以，在线程正在执行不应中断的关键工作（如将数据保存到磁盘）的情况下，可连接线程可能更可取。

如果想要创建可连接的线程，唯一的方法是使用POSIX线程。POSIX默认将线程创建为可连接。要将线程标记为分离或可连接，请在创建线程之前使用`pthread_attr_setdetachstate`函数修改线程属性。线程启动后，可以通过调用`pthread_detach`函数来将可连接线程更改为分离线程。

### 设置线程优先级

创建的任何新线程都具有与其关联的默认优先级。内核的调度算法在确定要运行哪些线程时会考虑线程优先级，优先级较高的线程比较低优先级的线程更可能运行。较高的优先级并不能保证线程的具体执行时间，只是与较低优先级的线程相比，调度程序更有可能选择它。

> **重要提示**：将线程的优先级保留为默认值通常是一个好主意。增加一些线程的优先级也增加了在较低优先级的线程中出现饥饿状况的可能性。如果应用程序包含必须彼此交互的高优先级和低优先级线程，则较低优先级线程的饥饿可能会阻塞其他线程并导致性能瓶颈。

如果确实想修改线程优先级，Cocoa和POSIX都可以这样做。对于Cocoa线程，可以使用`NSThread`的`setThreadPriority:`类方法来设置当前正在运行的线程的优先级。对于POSIX线程，可以使用`pthread_setschedparam`函数。

## 编写线程的入口例程

大多数情况下，OS X中的线程入口点例程的结构与其他平台上的相同。初始化数据结构，做一些工作或者可选地配置一个run loop，并在线程代码完成时清理。根据我们的设计，在编写入门例程时可能需要执行一些额外的步骤。

### 创建自动释放池

链接了Objective-C框架的应用程序通常必须在其每个线程中至少创建一个自动释放池。如果应用程序使用管理模型 -- 应用程序处理保留和释放对象的地方 -- 自动释放池将捕获该线程中自动释放的所有对象。

如果应用程序使用垃圾回收而不是管理内存模型，则不需要创建自动释放池。自动释放池的存在并不会对垃圾回收应用程序造成危害，大多数情况下都会被忽略。在允许代码模块必须同时支持垃圾回收和管理内存模型的情况下，自动释放池必须存在以便支持管理内存模型代码，并且如果应用程序在启用垃圾回收的情况下运行，则会被忽略。

如果应用程序使用管理内存模型，则创建自动释放池是在线程入口例程中首先执行的操作。同样，销毁这个自动释放池应该是在线程中做的最后一件事。该池确保自动释放的对象被捕获，在线程本身退出之前它不会释放它们。以下代码显示了使用自动释放池的基本线程入口例程的结构。
```
- (void)myThreadMainRoutine
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool

    // Do thread work here.

    [pool release];  // Release the objects in the pool.
}
```
**由于顶层自动释放池在线程退出之前不会释放其对象，因此长期线程应创建更多的自动释放池来更频繁地释放对象。例如，使用run loop的线程可能会在每次运行循环时创建和释放自动释放池。更频繁地释放对象可防止应用程序的内存占用过大，从而导致性能问题。与任何与性能相关的行为一样，应该测量代码的实际性能，并适当调整自动释放池的使用。**

有关内存管理和自动释放池的更多信息，请参看[Advanced Memory Management Programming Guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/MemoryMgmt.html#//apple_ref/doc/uid/10000011i)。

### 设置异常处理程序

如果应用程序捕获并处理异常，则应准备好线程代码以便捕获可能发生的任何异常。尽管在发生异常的地方处理异常是最好的，但如果未能在线程中捕获抛出的异常，则会导致应用程序退出。在线程入口例程中安装最终的**try/catch**可以让我们捕获任何未知的异常并提供适当的响应。

在Xcode中构建项目时，可以使用C++或Objective-C异常处理样式。有关设置如何在Objective-C中引发和捕获异常的信息，请参看[Exception Programming Topics](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Exceptions/Exceptions.html#//apple_ref/doc/uid/10000012i)。

### 设置Run Loop

当编写想要在单独的线程上运行的代码时，我们有两种选择。第一种选择是将线程的代码编写为一个很少或者根本不中断的长期任务，并在该任务完成时退出线程。第二种选择是把线程放到一个循环中，当有请求到达时，动态处理请求。第一种选择不需要为代码进行特殊配置，只需要开启执行想要执行的工作。但是，第二种选择涉及到设置线程的run loop。

OS X和iOS为在每个线程中实现run loop提供了内置支持。应用程序框架自动启动应用程序主线程的run loop。如果为创建的任何辅助线程配置了run loop，则需要手动启动该run loop。

## 终止线程

建议退出线程的方式是让其正常退出入口点例程，虽然Cocoa，POSIX和Multiprocessing Services提供了直接杀死线程的例程，但是强烈建议不要使用这样的例程。杀死一个线程阻止了该线程清理自身的行为。由该线程分配的内存可能会泄漏，并且线程当前正在使用的任何其他资源可能无法被正确清理，之后可能会造成潜在问题。

如果预计需要在操作过程中终止线程，则应该从一开始就设计线程来响应取消或者退出消息。对于长时间运行的操作，这可能意味着要定期停止工作并检查是否收到了这样的消息。如果收到消息要求线程退出，线程将有机会执行任何需要的清理和正常退出。否则，它可能会重新开始工作并处理下一个数据块。

响应取消消息的一种方式是使用run loop输入源来接收此类消息。以下示例显示了这个代码在线程的主入口例程中的外观结构。（该示例仅显示主循环部分，不包括设置自动释放池或配置实际工作的步骤。）该示例在run loop中安装了一个自定义输入源，该输入源可以从另一个线程向该线程发送消息。在执行完总的工作量的一部分后，线程会简要地运行run loop来查看有没有消息到达输入源。如果没有，run loop会立即退出，并循环继续下一个工作。由于处理程序不能直接访问`exitNow`局部变量，所以退出条件通过线程字典中的键值对传递。
```
- (void)threadMainRoutine
{
    BOOL moreWorkToDo = YES;
    BOOL exitNow = NO;
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];

    // Add the exitNow BOOL to the thread dictionary.
    NSMutableDictionary* threadDict = [[NSThread currentThread] threadDictionary];
    
    [threadDict setValue:[NSNumber numberWithBool:exitNow] forKey:@"ThreadShouldExitNow"];

    // Install an input source.
    [self myInstallCustomInputSource];

    while (moreWorkToDo && !exitNow)
    {
        // Do one chunk of a larger body of work here.
        // Change the value of the moreWorkToDo Boolean when done.

        // Run the run loop but timeout immediately if the input source isn't waiting to fire.
        [runLoop runUntilDate:[NSDate date]];

        // Check to see if an input source handler changed the exitNow value.
        exitNow = [[threadDict valueForKey:@"ThreadShouldExitNow"] boolValue];
    }
}
```

# 线程编程指南 -- Run Loop

Run loop（运行循环）是与线程相关的基础架构的一部分。它是一个事件处理循环，用于调度工作和协调传入事件的接收。run loop的目的是在有工作做时让线程忙碌，并在没有工作可做时让线程进入休眠状态。

Run loop管理不是完全自动的，必须设计线程代码以便在适当的时间启动run loop并响应传入的事件。Cocoa和Core Foundation都提供了run loop对象来帮助我们配置和管理线程的run loop。应用程序不需要明确创建run loop对象，每个线程（包括应用程序的主线程）都有一个关联的run loop对象。但是，只有辅助线程需要显式运行其run loop。作为应用程序启动过程的一部分，应用程序框架自动设置并在主线程上运行run loop。

以下内容提供了有关run loop的更多信息以及如何为应用程序配置run loop。有关run loop对象的更多信息，请参看[NSRunLoop Class Reference](https://developer.apple.com/documentation/foundation/nsrunloop)和[CFRunLoop Reference](https://developer.apple.com/documentation/corefoundation/cfrunloop)。

## Run Loop详解

Run loop是一个线程进入循环，使用它来运行事件处理程序以便响应传入的事件。我们的代码提供了用于实现run loop的实际循环部分的控制语句——换句话说， 我们的代码提供了驱动run loop的while或者for循环。在循环中，使用run loop对象“执行”用于接收事件和调用已安装的处理程序的事件处理代码。

Run loop从两种不同类型的源中接收事件。输入源传递异步事件，这些事件通常是来自另一个线程或不同应用程序的消息。定时器源传递在预定的时间或者重复的间隔发生的同步事件。这两种类型的源都使用应用程序特定的处理程序来处理到达的事件。

下图显示了run loop和各种源的概念上的结构。输入源传递异步事件给对应的处理程序，并导致`runUntilDate:`方法（在线程关联的`NSRunloop`对象上调用）退出。定时器源传递事件到其处理例程，但是不会导致run loop退出。

![Structure of a run loop and its sources.png](https://upload-images.jianshu.io/upload_images/4906302-383c2c603bbf18b8.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

除了处理输入的源之外，run loop还会生成有关run loop行为的通知。已注册的run loop观察者能够接收通知，并使用它们对线程执行附加处理。使用Core Foundation来在线程上安装run loop观察者。

以下部分提供了与run loop的组件和它们的运转模式相关的更多信息，还描述了处理事件期间在不同时间生成的通知。

### Run Loop模式

Run loop模式是要监听的输入源和定时器的集合以及要通知的run loop观察者的集合。每次运行run loop时，都要明确或隐式地指定要运行的特定“模式”。在运行循环过程中，只监听与该模式有关的源并允许其传递事件。（同样，只有与该模式相关的观察者才会收到run loop的进度的通知。）与其他模式关联的源会保留任何新事件，直到随后以适当的模式通过循环为止。

在代码中，可以通过名称来识别模式。Cocoa和Core Foundation都定义了一个默认模式和几个常用模式，以及用于在代码中指定这些模式的字符串。可以通过简单地为模式名称指定一个自定义字符串来自定义模式。虽然分配给自定义模式的名称是任意的，但这些模式的内容不是。必须确保将一个或多个输入源、 定时器或run loop观察者添加到为它们创建的任何模式中，使它们生效。

可以使用模式在通过run loop的特定关口期间过滤掉不需要的源中的事件。大多数情况下，需要在系统定义的“默认”模式下运行run loop。但是，modal panel可能会以“模态”模式运行run loop。在此模式下，只有与modal panel相关的源才会将事件传递给线程。对于辅助线程，可以使用自定义模式来防止低优先级的源在时间至关重要的操作期间传递事件。

> **注意**：模式基于事件源来进行区分，而不是事件的类型。例如，不会使用模式来仅仅匹配鼠标按下事件或者仅匹配键盘事件。可以使用模式来监听不同的端口集、 暂时暂停定时器或者更改当前正在监听的源和run loop观察者。

下表列出了Cocoa和Core Foundation定义的标准模式以及何时使用该模式的说明。名称列列出了用于在代码中指定模式的实际常量。

| Mode | Name | Description |
|--------|--------|---------------|
| Default | NSDefaultRunLoopMode(Cocoa)<br>kCFRunLoopDefaultMode(Core Foundation) | 默认模式是用于大多数操作的模式。大多数情况下，应该使用此模式启动run loop和配置输入源。 |
| Connection | NSConnectionReplyMode (Cocoa) | Cocoa将此模式与`NSConnection`对象一起使用来监听应答。很少需要自己使用这种模式。 |
| Modal | NSModalPanelRunLoopMode (Cocoa) | Cocoa使用这种模式来识别用于modal panel的事件。 |
| Event tracking | NSEventTrackingRunLoopMode (Cocoa) | Cocoa使用这种模式来限定在鼠标拖拽循环和其他类型的用户界面跟踪循环期间传入的事件。 |
| Common modes | NSRunLoopCommonModes (Cocoa)<br>kCFRunLoopCommonModes (Core Foundation) | 这是一个常用模式的可配置组。将输入源与此模式相关联也会将其与组中的每个模式相关联。对于Cocoa应用程序，默认情况下，此集合包含默认、 模态和事件跟踪模式。Core Foundation最初只包含默认模式。可以使用`CFRunLoopAddCommonMode`函数将自定义模式添加到该集合中。 |


### 输入源

输入源异步传递事件给线程。事件源取决于输入源的类型，它通常是两类中的一类。基于端口的输入源监听应用程序的Mach端口。自定义输入源监听自定义事件源。对run loop而言，输入源是基于端口还是自定义的是无所谓的。系统通常实现两种类型的输入源，可以按照原样使用它们。两种源之间的唯一区别是它们如何发出信号。基于端口的源由内核自动发出信号，自定义源必须从另一个线程手动发生信号。

创建输入源时，可以将其分配给run loop的一个或者多个模式。模式能够影响在任何特定时刻哪些输入源会被监听。大多数情况下，在默认模式下运行run loop，但是也可以指定在自定义模式下运行。如果输入源不会被当前模式监听，它产生的任何事件都会被保留，直到run loop以正确的模式运行。

以下各节描述了一些输入源。

#### 基于端口的源

Cocoa和Core Foundation为使用与端口相关的对象创建的基于端口的输入源提供了内置支持。例如，在Cocoa中，根本不需要直接创建输入源。只需要创建一个端口对象，并使用`NSPort`类的方法将该端口添加到run loop。端口对象为我们处理所需输入源的创建和配置。

在Core Foundation中，必须手动创建端口及其run loop源。在这两种情况下，都使用与端口不透明类型关联的函数（`CFMachPortRef`，`CFMessagePortRef`或者`CFSocketRef`）来创建对应的对象。

有关如何设置和配置基于自定义端口的源的示例，请参看[配置基于端口的输入源](turn)。

#### 自定义输入源

要创建自定义输入源，必须使用Core Foundation中的与`CFRunLoopSourceRef`不透明类型相关联的函数。可以使用多个回调函数来配置自定义输入源，Core Foundation会在不同的地方调用这些函数来配置该输入源，处理所有传入的事件以及在从run loop中移除该输入源时销毁该输入源。

除了在事件到达时定义自定义源的行为之外，还必须定义事件传递机制。输入源的此部分在一个单独的线程上运行，负责为输入源提供数据，并在数据准备好处理时用信号通知它。事件传递机制由我们决定，但不必过于复杂。

有关如何创建自定义输入源的示例，请参看[定义自定义输入源](turn)。有关自定义输入源的参考信息，请参看[CFRunLoopSource Reference](https://developer.apple.com/documentation/corefoundation/cfrunloopsource-rhr)。

#### Cocoa执行选择器源（Cocoa Perform Selector Sources）

除了基于端口的源之外，Cocoa还定义了一个自定义输入源，允许我们在任何线程上执行选择器（Selector）。与基于端口的源一样，执行选择器请求在目标线程上被序列化，从而避免了在一个线程上运行多个方法时可能引发的许多同步问题。与基于端口的源不同，执行选择器源在执行其选择器后会将自己从run loop中移除。

> **注意**：在OS X v10.5之前，执行选择器源主要用于将消息发送到主线程，但在OS X v10.5及更高版本和iOS中，可以使用它们向任何线程发送消息。

在另一个线程上执行选择器时，目标线程必须具有激活的run loop。对于创建的线程，这意味着会等待执行选择器，直到我们明确地启动run loop。由于主线程自动启动其run loop，因此只要应用程序调用应用程序委托的`applicationDidFinishLaunching:`方法后，就可以在主线程上发出调用。run loop会在每次通过循环时处理所有排队的执行选择器调用，而不是在每次循环迭代期间只处理一个。

下表列出了`NSObject`中定义的可用于在其他线程上执行选择器的方法。由于这些方法是在`NSObject`中声明的，所以可以在任何有权访问Objective-C对象的线程中使用它们，包括POSIX线程。这些方法实际上不会创建一个新线程来执行选择器。

| Methods | Description |
|------------|--------------|
|`performSelectorOnMainThread:withObject:waitUntilDone:`<br>`performSelectorOnMainThread:withObject:waitUntilDone:modes:` | 在该线程的下一个run loop周期中执行应用程序主线程上的指定选择器。这些方法使我们可以选择阻塞当前线程，直到选择器被执行。 |
| `performSelector:onThread:withObject:waitUntilDone:`<br>`performSelector:onThread:withObject:waitUntilDone:modes:` | 在任何线程上执行指定的选择器。这些方法使我们可以选择阻塞当前线程，直到选择器被执行。 |
| `performSelector:withObject:afterDelay:`<br>`performSelector:withObject:afterDelay:inModes:` | 在下一个run loop周期中和可选的延迟周期之后，在当前线程上执行指定的选择器。由于会等到下一个run loop周期执行选择器，所以这些方法会从当前正在执行的代码中提供一个自动微小延迟。多个排队的选择器按照它们排队的顺序依次执行。 |
| `cancelPreviousPerformRequestsWithTarget:`<br>`cancelPreviousPerformRequestsWithTarget:selector:object:` | 允许我们取消使用`performSelector:withObject:afterDelay:`或者`performSelector:withObject:afterDelay:inModes:`方法发送给当前线程的消息。 |

有关每种方法的详细信息，请参看[NSObject Class Reference](https://developer.apple.com/documentation/objectivec/nsobject)。

### 定时器源

定时器源在未来的预设时间同步传递事件给我们的线程。定时器是线程通知自己做某事的一种方式。例如，搜索输入框可以使用定时器在用户连续敲击键盘之间经过一段时间后启动自动搜索。使用此延迟时间使用户有机会在开始搜索之前尽可能多地输入所需的搜索字符串。

虽然定时器源生成基于时间的通知，但定时器不是基于实时机制的。与输入源一样，定时器与与run loop的特定模式相关联。如果定时器为处于当前正在被run loop监听的模式下，则只有在定时器支持的其中一种模式下运行run loop时，才会启动定时器。同样，如果在run loop处于执行处理例程的过程中启动定时器，则定时器会等到下一次通过run loop时调用其处理例程。如果run loop根本没有运行，则定时器永远不会启动。

可以将定时器配置为仅生成一次或重复生成事件。重复定时器会基于调度的触发时间自动重新调度其本身，而不是基于实际的触发时间。例如，如果定时器计划在特定时间以及之后每隔5秒触发一次，则即使实际触发时间延迟了，计划的触发时间也会始终以原来的5秒时间间隔进行。如果触发时间延迟太多以至于错过了一个或多个预定的触发时间，则定时器在错过的时间段内仅被触发一次。在错过的时间触发后，定时器重新调度下一个预定的触发时间。

有关配置定时器源的更多信息，请参看[配置定时器源](turn)。有关参考信息，请参看[NSTimer Class Reference](https://developer.apple.com/documentation/foundation/timer)或者[CFRunLoopTimer Reference](https://developer.apple.com/documentation/corefoundation/cfrunlooptimer-rhk)。

### Run Loop观察者

与当一个对应的异步或同步事件发生时就会触发的源相比，run loop观察者会在run loop本身执行过程中在特定位置触发。可以使用run loop观察者来准备好线程以处理给定的事件，或者在线程进入休眠之前准备好线程。可以将run loop观察者与run loop中的以下事件相关联：
- 进入run loop。
- run loop即将处理定时器时。
- run loop即将处理输入源时。
- run loop即将进入休眠状态时。
- run loop被唤醒但在处理唤醒它的事件之前。
- 退出run loop。

可以使用Core Foundation将run loop观察者添加到引用程序中。要创建run loop观察者，可以创建`CFRunLoopObserverRef`不透明类型的新实例。此类型会跟踪我们的自定义回调函数以及它感兴趣的活动。

与定时器类似，run loop观察者可以使用一次或者重复使用。一次性的观察者在其触发后会将其自身从run loop中移除，而重复性的观察者仍然会存在于run loop中。在创建观察者时，可以指定其是运行一次还是反复运行。

有关如何创建run loop观察者的示例，请参看[配置Run Loop](turn)。有关参考信息，请参看[CFRunLoopObserver](https://developer.apple.com/documentation/corefoundation/cfrunloopobserver)。

### Run Loop事件处理循环的顺序

每当运行线程的run loop时，它都会处理未决事件，并为任何附加的观察者生成通知。其执行这些操作的顺序非常具体，如下所示：
1. 通知观察者已经进入run loop。
2. 通知观察者任何准备好的定时器即将触发。
3. 通知观察者任何不是基于端口的输入源即将触发。
4. 触发任何可以触发的不是基于端口的输入源。
5. 如果一个基于端口的输入源已经准备好并且正在等待触发，则立即处理该事件。跳到第9步。
6. 通知观察者线程即将进入休眠状态。
7. 将线程置于休眠状态，直到发生以下事件之一：
    - 与基于端口的输入源相关的事件到达。
    - 定时器触发。
    - 为run loop设置的超时值已过期。
    - run loop被明确地唤醒。
8. 通知观察者线程刚被唤醒。
9. 处理未决事件。
    - 如果用户定义的定时器触发，处理定时器事件并重新启动循环。跳到步骤2。
    - 如果输入源触发，则传递事件。
    - 如果run loop被显式唤醒但尚未超时，则重新启动循环。跳到第2步。
10. 通知观察者已经退出run loop。

由于定时器和输入源的观察者通知会在那些事件实际发生之前就被发送，所以通知的时间与实际事件的事件之间可能存在间隔。如果这些事件之间的时间至关重要，则可以使用休眠和从休眠中唤醒的通知来帮助将实际事件之间的时间关联起来。

由于定时器和其他周期性事件是在运行run loop时被传递的，所以要规避会扰乱这些事件的传递的循环。会发生这种行为的典型示例就是通过进入一个循环并从应用程序中重复请求事件来实现鼠标跟踪例程。因为我们的代码会直接捕获事件而不是让应用程序正常调度这些事件，所以在鼠标跟踪例程退出并将控制权返回给应用程序之前，激活的定时器将无法触发。

使用run loop对象能够显式地唤醒run loop，其他事件也可能导致run loop被唤醒。例如，添加一个不是基于端口的输入源会唤醒run loop以便输入源能够被立即处理，而不是等待直到发生其他事件。

## 何时使用Run Loop？

唯一需要我们明确运行run loop的时候是为应用程序创建辅助线程时。应用程序主线程的run loop是基础架构中至关重要的一部分。因此，应用程序框架提供运行主应用程序循环并自动启动该循环的代码。iOS中的`UIApplication`（或者OS X中的`NSApplication`）的运行方法启动应用程序的主循环，作为正常启动顺序的一部分。如果使用Xcode模版项目来创建应用程序，则不应该明确地调用这些例程。

对于辅助线程，我们需要确定run loop是否是必要的。如果需要，则自行配置并启动run loop。如果使用线程执行一些长时间运行且预先确定的任务，则应该避免启动run loop。run loop适用于需要与线程进行更多交互的情况。例如，如果打算执行以下任何操作，则需要启动run loop：
- 使用端口或者自定义输入源来与其他线程进行通信。
- 在线程中使用定时器。
- 使用Cocoa应用程序中的任何一种`performSelector…`方法。
- 让线程执行周期任务。

如果选择使用run loop，则其配置和设置非常简单。像所有线程编程一样，应当有一个机会来在适当的情况下退出辅助线程。通过自然退出线程而不是强制终止一个线程总是更好。有关如何配置和退出run loop的信息，请参看[使用Run Loop对象](turn)。

## 使用Run Loop对象

run loop对象提供了添加输入源、定时器和run loop观察者到run loop并启动run loop的主要接口。每个线程都一个与之关联的run loop对象。在Cocoa中，这个对象是`NSRunLoop`类的一个实例。在低级应用程序中，它是一个指向`CFRunLoopRef`不透明类型的指针。

### 获取Run Loop对象

要获取当前线程的run loop，请使用以下选项之一：
- 在Cocoa应用程序中，使用`NSRunLoop`的`currentRunLoop`类方法来获取`NSRunLoop`对象。
- 使用`CFRunLoopGetCurrent`函数。

尽管它们不是自由桥接类型，但在需要时，可以从`NSRunLoop`对象获取`CFRunLoopRef`不透明类型。`NSRunLoop`类定义了一个`getCFRunLoop`方法，该方法返回可以传递给Core Foundation例程的`CFRunLoopRef`类型。因为两个对象都引用同一个run loop，所以可以根据需要混合调用`NSRunLoop`对象和`CFRunLoopRef`不透明类型。

### 配置Run Loop

在辅助线程上运行run loop之前，必须至少添加一个输入源或定时器。如果run loop没有任何要监听的源，当我们尝试运行run loop时，它会立即退出。有关如何将源添加到run loop的示例，请参看[配置Run Loop源](turn)。

除了安装源之外，还可以安装run loop观察者并使用它们来监听run loop的不同执行阶段。要安装run loop观察者，需要创建一个`CFRunLoopObserverRef`不透明类型并使用`CFRunLoopAddObserver`函数将其添加到run loop。run loop观察者必须使用Core Foundation创建，即使对于Cocoa应用程序也是如此。

以下代码显示了一个将run loop观察者附加到其run loop的线程的主要例程。该示例的目的是展示如何创建run loop观察者，因此代码简单地设置了一个run loop观察者来监听所有run loop活动。基础处理例程（未显示）在run loop处理定时器请求时简单地记录了run loop活动。
```
- (void)threadMain
{
    // The application uses garbage collection, so no autorelease pool is needed.
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];

    // Create a run loop observer and attach it to the run loop.
    CFRunLoopObserverContext  context = {0, self, NULL, NULL, NULL};
    CFRunLoopObserverRef    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
    kCFRunLoopAllActivities, YES, 0, &myRunLoopObserver, &context);

    if (observer)
    {
        CFRunLoopRef    cfLoop = [myRunLoop getCFRunLoop];
        CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);
    }

    // Create and schedule the timer.
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doFireTimer:) userInfo:nil repeats:YES];

    NSInteger    loopCount = 10;
    do
    {
        // Run the run loop 10 times to let the timer fire.
        [myRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        loopCount--;
        
    }while (loopCount);
}
```
为长期存活的线程配置run loop时，最好添加至少一个输入源来接收消息。尽管仅仅附加一个定时器就能进入run loop，但是一旦定时器触发，定时器通常会失效，然后会导致run loop退出。附加重复定时器可以使run loop长时间运行，但是这意味着要定期触发定时器来唤醒线程，这实际上是另一种轮询方式。相反，输入源会等待事件发生，并让线程休眠直到发生事件。

### 启动Run Loop

启动run loop仅仅对于应用程序中的辅助线程才是必要的。run loop必须至少附加一个输入源或者定时器来监听。如果一个都没有，则run loop会立即退出。

启动run loop的方式包括以下几种：
- 无条件启动。
- 设定一个时限。
- 在特定模式下启动。

无条件地进入run loop是最简单地选择，但也是最不可取的。无条件地运行run loop会将线程置于一个永久循环中，这使得我们很难控制run loop本身。可以添加和删除输入源和定时器，但是停止run loop的唯一方法是杀死它。在自定义模式下也是无法运行run loop的。

最好使用超时值运行run loop，而不是无条件地运行run loop。当使用超时值时，run loop会一直运行直到有事件到达或分配的时间到期。如果一个事件到达，则将该事件调度给处理程序进行处理，然后run loop退出。之后，我们的代码可以重新启动run loop来处理下一个事件。如果分配的时间到期，可以简单地重新启动run loop或者使用该时间来完成任何需要的清理工作。

除了超时值之外，还可以使用特定模式运行run loop。模式和超时值不是互斥的，可以同时使用它们来启动run loop。模式限制了传递事件到run loop的源的类型，有关模式的详细信息请参看[Run Loop模式](turn)。

以下代码显示了一个线程的主要入口例程的粗略版本。这个示例的关键部分显示了run loop的基本结构。本质上，我们将输入源和定时器添加到run loop，然后重复调用其中一个例程来启动run loop。每次run loop例程返回时，都会检查是否有任何可能导致退出线程的情况。该示例使用Core Foundation的run loop例程，以便它可以检查返回结果并确定run loop退出的原因。如果使用Cocoa并且不需要检查返回值，则也可以使用`NSRunLoop`类的方法以类似的方式来运行run loop。
```
- (void)skeletonThreadMain
{
    // Set up an autorelease pool here if not using garbage collection.
    BOOL done = NO;

    // Add your sources or timers to the run loop and do any other setup.

    do
    {
        // Start the run loop but return after each source is handled.
        SInt32    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, YES);

        // If a source explicitly stopped the run loop, or if there are no
        // sources or timers, go ahead and exit.
        if ((result == kCFRunLoopRunStopped) || (result == kCFRunLoopRunFinished))
        
            done = YES;

        // Check for any other exit conditions here and set the
        // done variable as needed.
    }
    while (!done);

    // Clean up code here. Be sure to release any allocated autorelease pools.
}
```
还可以递归运行一个run loop。换句话说，可以调用`CFRunLoopRun`、`CFRunLoopRunInMode`或者`NSRunLoop`的方法来在输入源或定时器的处理例程中启动run loop。这样做时，可以使用任何需要的run loop模式来运行嵌套run loop，包括外部run loop使用的模式。

### 退出Run Loop

有两种方法能使run loop在其处理事件之前退出：
- 配置run loop以超时值运行。
- 告知run loop退出。

如果我们能够管理超时值，那么使用超时值肯定是首选。指定超时值可以让run loop完成所有正常处理，包括在退出之前将通知发送给run loop观察者。

使用`CFRunLoopStop`函数显式地停止运行run loop会产生类似于超时的结果。run loop会发送出任何其余的run loop通知，然后退出。不同的是，可以在对无条件启动的run loop使用此技术。

虽然移除run loop的输入源和定时器也可能导致run loop退出，但这并不是停止run loop的可靠方法。一些系统例程会将输入源添加到run loop以处理所需的事件。由于我们的代码可能无法知道这些输入源，所有就无法移除它们，这样run loop是不会退出的。

### 线程安全和Run Loop对象

线程安全取决于我们使用哪个API来操作run loop。Core Foundation中的函数通常是线程安全的，可以在任何线程中调用。但是，如果正在执行更改run loop配置的操作，则尽可能在持有该run loop的线程中执行此操作。

Cocoa中`NSRunLoop`类并不像其在Core Foundation中的副本那样是线程安全的。如果使用`NSRunLoop`类来修改run loop，则应该仅仅只在持有该run loop的线程中这样做。在不同的线程中将输入源或定时器添加到run loop可能会导致代码崩溃或以意外的方式运行。

## 配置Run Loop源

以下部分显示了如何在Cocoa和Core Foundation中设置不同类型的输入源的示例。

### 定义自定义输入源

创建自定义输入源涉及到以下内容：
- 想让输入源处理的信息。
- 能让感兴趣的客户端知道如何与输入源联系的调度例程。
- 能用于执行任何客户端发送的请求的处理例程。
- 能让输入源无效的取消例程。

要创建一个自定义输入源来处理自定义信息，应该灵活设计实际的配置。调度、处理和取消例程是用于自定义输入源的关键例程。然而，输入源行为的其余部分的大部分都发生在这些处理例程之外。例如，为传递数据到输入源和将输入源的存在传达给其他线程定义机制是由我们自己决定的。

下图显示了自定义输入源的示例配置。在本示例中，应用程序的主线程保持对输入源、该输入源的自定义命令缓冲区以及安装该输入源的run loop的引用。当主线程有一个任务想要切换到工作线程时，它将命令和工作线程启动该任务所需的任何信息一起发送到命令缓冲区。（因为主线程和工作线程的输入源都可以访问命令缓冲区，所以访问必须同步）。一旦命令发送，主线程就会发送信号给输入源并唤醒工作线程的run loop。在接收到唤醒命令后，run loop会调用输入源的处理程序，它会处理在命令缓冲区中找到的命令。

![Operating a custom input source.png](http://upload-images.jianshu.io/upload_images/4906302-6f9b7ed6a633df16.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

以下各节将解释上图中自定义输入源的实现，并展示需要实现的关键代码。

#### 定义输入源

定义自定义输入源需要使用Core Foundation例程来配置run loop源并将其附加到run loop。虽然基础处理程序是基于C语言的函数，但是这并不妨碍我们为这些函数编写包装器并使用Objective-C或者C++来实现代码的主体。

上图中介绍的输入源使用Objective-C对象来管理命令缓冲区并与run loop进行协调。以下代码显示了这个对象的定义。RunLoopSource对象管理命令缓冲区，并使用该缓冲区接收来自其他线程的消息。以下代码还显示了RunLoopContext对象的定义，该对象实际上是一个容器对象，用于将RunLoopContext对象和run loop引用传递给应用程序的主线程。
```
@interface RunLoopSource : NSObject
{
    CFRunLoopSourceRef runLoopSource;
    NSMutableArray* commands;
}

- (id)init;
- (void)addToCurrentRunLoop;
- (void)invalidate;

// Handler method
- (void)sourceFired;

// Client interface for registering commands to process
- (void)addCommand:(NSInteger)command withData:(id)data;
- (void)fireAllCommandsOnRunLoop:(CFRunLoopRef)runloop;

@end

// These are the CFRunLoopSourceRef callback functions.
void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);
void RunLoopSourcePerformRoutine (void *info);
void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);

// RunLoopContext is a container object used during registration of the input source.
@interface RunLoopContext : NSObject
{
    CFRunLoopRef        runLoop;
    RunLoopSource*        source;
}
@property (readonly) CFRunLoopRef runLoop;
@property (readonly) RunLoopSource* source;

- (id)initWithSource:(RunLoopSource*)src andLoop:(CFRunLoopRef)loop;
@end
```
虽然Objective-C代码管理输入源的自定义数据和将输入源附加到run loop所需要的基于C语言的回调函数。当将输入源实际附加到run loop时，这些函数中的第一个会被调用，如下所示。由于此输入源只有一个客户端（主线程），因此它使用RunLoopSourceScheduleRoutine函数发送消息来在该线程上向应用程序委托对象注册自己。当委托对象想要与输入源通信时，它使用RunLoopContext对象中的信息来执行此操作。
```
void RunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    RunLoopSource* obj = (RunLoopSource*)info;
    AppDelegate*   del = [AppDelegate sharedAppDelegate];
    RunLoopContext* theContext = [[RunLoopContext alloc] initWithSource:obj andLoop:rl];

    [del performSelectorOnMainThread:@selector(registerSource:) withObject:theContext waitUntilDone:NO];
}
```
最重要的回调例程之一是用于在输入源发送信号时处理自定义数据的回调例程。以下代码显示了与RunLoopSource对象关联的RunLoopSourcePerformRoutine回调。该函数只是将执行工作的请求发送给sourceFired方法，该方法随后会处理命令缓冲区中存在的任何命令。
```
void RunLoopSourcePerformRoutine (void *info)
{
    RunLoopSource*  obj = (RunLoopSource*)info;
    [obj sourceFired];
}
```
如果使用`CFRunLoopSourceInvalidate`函数将输入源从其run loop中移除，则系统将调用输入源的取消例程。可以使用此例程来通知客户端其输入源不再有效，并且应该删除对它的任何引用。以下代码显示了使用RunLoopSource对象注册的取消回调例程。该函数将另一个RunLoopContext对象发送给应用程序委托对象，但是这次会要求委托对象删除对run loop源的引用。
```
void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    RunLoopSource* obj = (RunLoopSource*)info;
    AppDelegate* del = [AppDelegate sharedAppDelegate];
    RunLoopContext* theContext = [[RunLoopContext alloc] initWithSource:obj andLoop:rl];

    [del performSelectorOnMainThread:@selector(removeSource:) withObject:theContext waitUntilDone:YES];
}
```
> **提示**：应用程序委托对象的registerSource:和removeSource:方法的代码在[协调输入源的客户端](turn)中展示。

#### 在Run Loop中安装输入源

以下代码展示了RunLoopSource类的init和addToCurrentRunLoop方法。init方法创建必须被实际附加到run loop的`CFRunLoopSourceRef`不透明类型。它将RunLoopSource对象本身作为上下文信息传递，以便回调例程具有指向该对象的指针。不会安装输入源到run loop直到工作线程调用addToCurrentRunLoop方法，此时将调用RunLoopSourceScheduleRoutine回调函数。一旦输入源被添加到run loop中，线程就可以运行它的run loop来等待输入源传递的事件。
```
- (id)init
{
    CFRunLoopSourceContext context = {0, self, NULL, NULL, NULL, NULL, NULL, &RunLoopSourceScheduleRoutine, RunLoopSourceCancelRoutine, RunLoopSourcePerformRoutine};

    runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
    
    commands = [[NSMutableArray alloc] init];

    return self;
}

- (void)addToCurrentRunLoop
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
}
```

#### 协调输入源的客户端

为了让输入源生效，需要操作它并从另一个线程发送信号给它。输入源的全部要点在于将关联的线程置于休眠状态直到有事件需要处理时。这一事实使得让应用程序中其他线程能够知道输入源并有一种方式来与其通信成为了必要。

将输入源告知给客户端的一种方式是在首次安装输入源到run loop时发出注册请求。可以根据需要为输入源注册尽可能多的客户端，或者可以将其注册到某个中心机构，然后将输入源发送给感兴趣的客户端。以下代码显示了由应用程序委托对象定义的在调用RunLoopSource对象的调度函数时调用的注册方法。该方法接收RunLoopSource对象提供的RunLoopContext对象，并将其添加到源列表中。以下代码还显示了用于在从run loop中移除输入源时取消注册输入源的例程。
```
- (void)registerSource:(RunLoopContext*)sourceInfo;
{
    [sourcesToPing addObject:sourceInfo];
}

- (void)removeSource:(RunLoopContext*)sourceInfo
{
    id    objToRemove = nil;

    for (RunLoopContext* context in sourcesToPing)
    {
        if ([context isEqual:sourceInfo])
        {
            objToRemove = context;
            break;
        }
    }

    if (objToRemove)
        [sourcesToPing removeObject:objToRemove];
}
```

#### 发送信号到输入源

在客户端传递数据给输入源后，客户端必须发送信号到输入源并唤醒输入源的run loop。发送信号到输入源让run loop知道输入源已经准备好被处理。并且由于线程可能在发送信号时处于休眠状态，所以应该始终明确地唤醒run loop。如果不这样做，可能会导致run loop延迟处理输入源。

以下代码显示了RunLoopSource对象的fireCommandsOnRunLoop方法。当客户端准备好输入源来处理被添加到缓冲区的命令时，客户端会调用此方法。
```
- (void)fireCommandsOnRunLoop:(CFRunLoopRef)runloop
{
    CFRunLoopSourceSignal(runLoopSource);
    CFRunLoopWakeUp(runloop);
}
```
> **注意**：绝对不要尝试通过使用自定义输入源来处理`SIGHUP`或者其他类型的过程级信号。Core Foundation中用于唤醒线程的函数不是信号安全的，不应该在应用程序的信号处理例程中使用它们。

### 配置定时器源

要创建一个定时器源，需要创建一个定时器对象并将其调度到run loop中。在Cocoa中，使用`NSTimer`类来创建新的定时器对象，而在Core Foundation中使用`CFRunLoopTimerRef`不透明类型。`NSTimer`类只是Core Foundation的扩展，其提供了一些便利功能。例如，使用同一个方法来创建和调度定时器。

在Cocoa中，可以使用以下类方法中的一种来创建和调度定时器：
-  `scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:`
-  `scheduledTimerWithTimeInterval:invocation:repeats:`

这些方法会创建定时器，并将其添加到当前线程的默认模式（`NSDefaultRunLoopMode`）下的run loop中。如果想要手动调度定时器，可以创建`NSTimer`对象，然后使用`NSRunLoop`的`addTimer:forMode:`方法将其添加到run loop中。这两种技术基本上会做相同的事情，但是提供了对于定时器配置的不同级别的控制。例如，创建一个定时器并手动将其添加到run loop中，则可以使用默认模式之外的模式来执行此操作。以下代码显示了如何使用这两种技术创建定时器。第一个定时器的初始延迟时间为1秒，但是之后每隔0.1秒定时触发一次。第二个定时器在延迟0.2秒后开发触发，然后每隔0.2秒定时触发一次。
```
NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];

// Create and schedule the first timer.
NSDate* futureDate = [NSDate dateWithTimeIntervalSinceNow:1.0];

NSTimer* myTimer = [[NSTimer alloc] initWithFireDate:futureDate interval:0.1 target:self selector:@selector(myDoFireTimer1:) userInfo:nil repeats:YES];

[myRunLoop addTimer:myTimer forMode:NSDefaultRunLoopMode];

// Create and schedule the second timer.
[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(myDoFireTimer2:) userInfo:nil repeats:YES];
```
以下代码显示了使用Core Foundation函数配置定时器所需要的代码。虽然此示例没有在上下文结构中传递任何用户定义的信息，但我们可以使用此结构来传递定时器所需的任何自定义数据。有关此结构的内容的更多信息，请参看[CFRunLoopTimer Reference](https://developer.apple.com/documentation/corefoundation/cfrunlooptimer-rhk)。
```
CFRunLoopRef runLoop = CFRunLoopGetCurrent();
CFRunLoopTimerContext context = {0, NULL, NULL, NULL, NULL};
CFRunLoopTimerRef timer = CFRunLoopTimerCreate(kCFAllocatorDefault, 0.1, 0.3, 0, 0,
&myCFTimerCallback, &context);

CFRunLoopAddTimer(runLoop, timer, kCFRunLoopCommonModes);
```

### 配置基于端口的输入源

Cocoa和Core Foundation都提供了用于线程或者进程之间通信的基于端口的对象。以下部分介绍如何使用几种不同类型的端口设置端口通信。

#### 配置NSMachPort对象

要使用`NSMachPort`对象建立本地连接，需要创建端口对象并将其添加到主线程的run loop中。在启动辅助线程时，将该端口对象传递给辅助线程的入口函数。辅助线程可以使用该端口对象将消息发送回主线程。

##### 实现主线程代码

以下代码显示了启动辅助工作线程的主线程代码。由于Cocoa框架为配置端口和run loop执行了许多中间步骤，所以launchThread方法的代码量明显少于其在Core Foundation的等价函数的代码量。但是，两者的行为几乎完全相同。不同的是，该方式不是将本地端口的名称发送给工作线程，而是直接发送`NSPort`对象。
```
- (void)launchThread
{
    NSPort* myPort = [NSMachPort port];
    if (myPort)
    {
        // This class handles incoming port messages.
        [myPort setDelegate:self];

        // Install the port as an input source on the current run loop.
        [[NSRunLoop currentRunLoop] addPort:myPort forMode:NSDefaultRunLoopMode];

        // Detach the thread. Let the worker release the port.
        [NSThread detachNewThreadSelector:@selector(LaunchThreadWithPort:) toTarget [MyWorkerClass class] withObject:myPort];
    }
}
```
为了在线程之间建立一个双向通信通道，可能需要工作线程在check-in消息中发送自己的本地端口到主线程。接收check-in消息使得主线程知道在启动辅助线程时一切顺利，并且还提供了一种方式将更多消息发送到主线程。

以下代码显示了主线程的`handlePortMessage:`方法。当数据到达线程自己的本地端口时，会调用此方法。当check-in消息到达时，该方法直接从端口消息中检索辅助线程的端口，并将其保存以供以后使用。
```
#define kCheckinMessage 100

// Handle responses from the worker thread.
- (void)handlePortMessage:(NSPortMessage *)portMessage
{
    unsigned int message = [portMessage msgid];
    
    NSPort* distantPort = nil;

    if (message == kCheckinMessage)
    {
        // Get the worker thread’s communications port.
        distantPort = [portMessage sendPort];

        // Retain and save the worker port for later use.
        [self storeDistantPort:distantPort];
        
    }else
    {
        // Handle other messages.
    }
}
```

##### 实现辅助线程代码

对于辅助工作线程，必须配置该线程并使用指定的端口将消息传回主线程。

以下代码显示了设置工作线程的代码。在为线程创建一个自动释放池之后，此方法创建一个工作者对象来驱动线程执行。工作者对象的`sendCheckinMessage:`方法为工作线程创建一个本地端口，并将一个check-in消息发送回主线程。
```
+(void)LaunchThreadWithPort:(id)inData
{
    NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];

    // Set up the connection between this thread and the main thread.
    NSPort* distantPort = (NSPort*)inData;

    MyWorkerClass*  workerObj = [[self alloc] init];
    [workerObj sendCheckinMessage:distantPort];
    [distantPort release];

    // Let the run loop process things.
    do
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
        beforeDate:[NSDate distantFuture]];
    }
    while (![workerObj shouldExit]);

    [workerObj release];
    [pool release];
}
```
在使用`NSMachPort`时，本地和远程线程可以使用相同的端口对象进行线程之间的单向通信。换句话说，由一个线程创建的本地端口对象成为另一个线程的远程端口对象。

以下代码显示了辅助线程的check-in例程。此方法为将来的通信设置了自己的本地端口，然后将check-in消息发送回主线程。此方法使用`LaunchThreadWithPort:`中收到的端口对象作为消息的目标。
```
// Worker thread check-in method
- (void)sendCheckinMessage:(NSPort*)outPort
{
    // Retain and save the remote port for future use.
    [self setRemotePort:outPort];

    // Create and configure the worker thread port.
    NSPort* myPort = [NSMachPort port];
    [myPort setDelegate:self];
    [[NSRunLoop currentRunLoop] addPort:myPort forMode:NSDefaultRunLoopMode];

    // Create the check-in message.
    NSPortMessage* messageObj = [[NSPortMessage alloc] initWithSendPort:outPort receivePort:myPort components:nil];

    if (messageObj)
    {
        // Finish configuring the message and send it immediately.
        [messageObj setMsgId:setMsgid:kCheckinMessage];
        [messageObj sendBeforeDate:[NSDate date]];
    }
}
```

#### 配置NSMessagePort对象

要使用`NSMessagePort`对象建立本地连接，不能只是简单地在线程之间传递端口对象，必须按名称获取远程消息端口。在Cocoa中实现这一点需要使用特定名称来注册本地端口，然后将该名称传递给远程线程，以便它可以获取对应的端口对象进行通信。以下代码显示了在使用消息端口的情况时，端口的创建和注册过程。
```
NSPort* localPort = [[NSMessagePort alloc] init];

// Configure the object and add it to the current run loop.
[localPort setDelegate:self];

[[NSRunLoop currentRunLoop] addPort:localPort forMode:NSDefaultRunLoopMode];

// Register the port using a specific name. The name must be unique.
NSString* localPortName = [NSString stringWithFormat:@"MyPortName"];

[[NSMessagePortNameServer sharedInstance] registerPort:localPort name:localPortName];
```

#### 在Core Foundation中配置基于端口的输入源

本节介绍如何使用Core Foundation在应用程序的主线程和工作线程之间建立双向通信通道。

以下代码显示了应用程序主线程调用的启动工作线程的代码。首先设置一个`CFMessagePortRef`类型来监听来自工作线程的消息。工作线程需要端口的名称来建立连接，所以字符串值被传递给工作线程的入口函数。端口名称在当前用户上下文中通常应该是唯一的，否则可能会遇到冲突。
```
#define kThreadStackSize        (8 *4096)

OSStatus MySpawnThread()
{
    // Create a local port for receiving responses.
    CFStringRef myPortName;
    CFMessagePortRef myPort;
    CFRunLoopSourceRef rlSource;
    CFMessagePortContext context = {0, NULL, NULL, NULL, NULL};
    Boolean shouldFreeInfo;

    // Create a string with the port name.
    myPortName = CFStringCreateWithFormat(NULL, NULL, CFSTR("com.myapp.MainThread"));

    // Create the port.
    myPort = CFMessagePortCreateLocal(NULL, myPortName, &MainThreadResponseHandler, &context, &shouldFreeInfo);

    if (myPort != NULL)
    {
        // The port was successfully created.
        // Now create a run loop source for it.
        rlSource = CFMessagePortCreateRunLoopSource(NULL, myPort, 0);

        if (rlSource)
        {
            // Add the source to the current run loop.
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSource, kCFRunLoopDefaultMode);

            // Once installed, these can be freed.
            CFRelease(myPort);
            CFRelease(rlSource);
        }
    }

    // Create the thread and continue processing.
    MPTaskID        taskID;
    return(MPCreateTask(&ServerThreadEntryPoint, (void*)myPortName, kThreadStackSize, NULL, NULL, NULL, 0, &taskID));
}
```
在安装端口并启动线程之后，在等待线程的check-in消息时，主线程会继续定期执行。当check-in消息到达时，其被调度到主线程的MainThreadResponseHandler函数，如下所示。此函数提供工作线程的端口名称并为将来的通信创建管道。
```
#define kCheckinMessage 100

// Main thread port message handler
CFDataRef MainThreadResponseHandler(CFMessagePortRef local, SInt32 msgid,
CFDataRef data, void* info)
{
    if (msgid == kCheckinMessage)
    {
        CFMessagePortRef messagePort;
        CFStringRef threadPortName;
        CFIndex bufferLength = CFDataGetLength(data);
        UInt8* buffer = CFAllocatorAllocate(NULL, bufferLength, 0);

        CFDataGetBytes(data, CFRangeMake(0, bufferLength), buffer);
        threadPortName = CFStringCreateWithBytes (NULL, buffer, bufferLength, kCFStringEncodingASCII, FALSE);

        // You must obtain a remote message port by name.
        messagePort = CFMessagePortCreateRemote(NULL, (CFStringRef)threadPortName);

        if (messagePort)
        {
            // Retain and save the thread’s comm port for future reference.
            AddPortToListOfActiveThreads(messagePort);

            // Since the port is retained by the previous function, release
            // it here.
            CFRelease(messagePort);
        }

        // Clean up.
        CFRelease(threadPortName);
        CFAllocatorDeallocate(NULL, buffer);
    }
    else
    {
        // Process other messages.
    }

    return NULL;
}
```
在配置主线程之后，剩余的唯一事情是新创建的工作线程创建其自己的端口并check in。以下代码显示了工作线程的入口函数，该函数提前主线的端口名称并使用它创建远程连接回到主线程。然后该函数为自己创建一个本地端口，在该线程的run loop中安装该端口，并向包含本地端口名称的主线程发送一个check-in消息。
```
OSStatus ServerThreadEntryPoint(void* param)
{
    // Create the remote port to the main thread.
    CFMessagePortRef mainThreadPort;
    CFStringRef portName = (CFStringRef)param;

    mainThreadPort = CFMessagePortCreateRemote(NULL, portName);

    // Free the string that was passed in param.
    CFRelease(portName);

    // Create a port for the worker thread.
    CFStringRef myPortName = CFStringCreateWithFormat(NULL, NULL, CFSTR("com.MyApp.Thread-%d"), MPCurrentTaskID());

    // Store the port in this thread’s context info for later reference.
    CFMessagePortContext context = {0, mainThreadPort, NULL, NULL, NULL};
    Boolean shouldFreeInfo;
    Boolean shouldAbort = TRUE;

    CFMessagePortRef myPort = CFMessagePortCreateLocal(NULL, myPortName, &ProcessClientRequest, &context, &shouldFreeInfo);

    if (shouldFreeInfo)
    {
        // Couldn't create a local port, so kill the thread.
        MPExit(0);
    }

    CFRunLoopSourceRef rlSource = CFMessagePortCreateRunLoopSource(NULL, myPort, 0);
    if (!rlSource)
    {
        // Couldn't create a local port, so kill the thread.
        MPExit(0);
    }

    // Add the source to the current run loop.
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rlSource, kCFRunLoopDefaultMode);

    // Once installed, these can be freed.
    CFRelease(myPort);
    CFRelease(rlSource);

    // Package up the port name and send the check-in message.
    CFDataRef returnData = nil;
    CFDataRef outData;
    CFIndex stringLength = CFStringGetLength(myPortName);
    UInt8* buffer = CFAllocatorAllocate(NULL, stringLength, 0);

    CFStringGetBytes(myPortName, CFRangeMake(0,stringLength), kCFStringEncodingASCII, 0, FALSE, buffer, stringLength, NULL);

    outData = CFDataCreate(NULL, buffer, stringLength);

    CFMessagePortSendRequest(mainThreadPort, kCheckinMessage, outData, 0.1, 0.0, NULL, NULL);

    // Clean up thread data structures.
    CFRelease(outData);
    CFAllocatorDeallocate(NULL, buffer);

    // Enter the run loop.
    CFRunLoopRun();
}
```
一旦工作线程进入其run loop，发送到线程的端口的所有未来事件都将由ProcessClientRequest函数处理。该函数的实现取决于线程所执行的工作类型，在此不显示。

# 线程编程指南 -- 同步

对于从多个执行线程安全访问资源，应用程序中多个线程的存在会导致潜在的问题。修改相同资源的两个线程可能会以出乎意料的方式相互干扰。例如，一个线程可能会覆盖另一个线程的更改或者将应用程序置于未知和可能无效的状态。如果幸运的话，损坏的资源可能会导致明显的性能问题或者崩溃，这些问题相对容易追踪和修复。然而，也可能会导致过了很久之后才会出现的微妙问题，或者可能需要对底层代码进行重大修改的错误。

当涉及到线程安全时，一个优良的设计是最好的保护。避免共享资源和尽量减少线程之间的交互，使得这些线程不太可能相互干扰。然而，完全无干扰的设计并不总是可行的。在线程必须交互的情况下，需要使用同步工具来确保线程在交互时，它们能够安全地执行。

OS X和iOS提供了许多同步工具供我们使用，包括提供互斥访问的工具以及在应用程序中为事件正确安排顺序的工具。以下各节将介绍这些工具以及如何在代码中使用它们来影响对程序资源的安全访问。

## 同步工具

为防止不同的线程出乎意料地更改数据，可以设计应用程序以避免同步问题，也可以使用同步工具。虽然完全避免同步问题是更加可取的，但并非总是可行。以下各节介绍可供使用的同步工具的基本类别。

### 原子操作

原子操作是一种简单的同步形式，适用于简单的数据类型。原子操作的优点是它们不会阻塞竞争线程。对于简单的操作，例如递增一个计数器变量，相对于加锁，这样做可能会带来更好的性能。

OS X和iOS包含大量的操作来对32位和64位值执行基本的数学和逻辑运算。这些操作中包括`compare-and-swap`、`test-and-set`和`test-and-clear`操作的原子版本。

### 内存屏障和Volatile变量

为了实现最佳性能，编译器通常会对汇编级指令重新排序来尽可能充分地维持处理器的指令流水线。作为这种优化的一部分，当编译器认为对访问主内存的指令重新排序不会产生错误的数据时，它可能会这样做。不幸的是，编译器并不总是能够检测到所有依赖于内存的操作。如果看似单独的变量实际上相互影响，编译器优化可能会以错误的顺序更新这些变量，从而产生潜在的错误结果。

[内存屏障](https://en.wikipedia.org/wiki/Memory_barrier)是一种非阻塞同步工具，用于确保内存操作以正确的顺序执行。内存屏障就像栅栏一样，强制处理器完成位于栅栏前面的任何加载和存储操作，然后才允许其执行位于栅栏后面的加载和存储操作。内存屏障通常用于确保一个线程（但对另一个线程可见）的内存操作始终按照预期的顺序进行。在缺少内存屏障的情况下，可能会让其他线程看到看似不可能的结果。要使用内存屏障，只需要在代码中国的适当位置调用`OSMemoryBarrier`函数即可。

[Volatile变量](https://zh.wikipedia.org/wiki/Volatile%E5%8F%98%E9%87%8F)将另一种类型的内存约束应用与各个变量。编译器通常通过将变量的值加载到寄存器中来优化代码。对于局部变量，这通常不是问题。但是如果变量在另一个线程是可见的，这样的优化可能会阻止其他线程注意到该变量的任何更改。将`volatile`关键字应用于变量会强制编译器在每次使用变量时从内存加载该变量。如果可以随时通过编译器可能无法检测到的外部源更改变量的值，则可以将该变量声明为`volatile`。

因为内存屏障和volatile变量都会减少编译器可以执行的优化次数，所以应该谨慎使用它们，并且仅在需要确保正确性时才使用它们。

### 锁

锁是最常用的同步工具之一。可以使用锁来保护代码的关键部分，这段关键代码一次只允许一个线程访问。例如，关键部分可能会操作特定的数据结构或者使用一次最多支持一个客户端的资源。通过在该部分放置一个锁，可以拒绝其他线程执行可能影响代码正确性的更改。

下表列出了一些我们常用的锁。OS X和iOS为这些锁类型的大多数提供了实现，但不是全部。对于不受支持的锁类型，描述列解释了为什么这些锁没有直接在平台上实现的原因。

| Lock | Description |
|-------|---------------|
| Mutex | 互斥锁充当资源周围的保护屏障。互斥锁是一种信号量，一次只允许一个线程访问。如果一个互斥锁正在被使用，而另一个线程试图获取它，则该线程将阻塞，直到互斥锁被其原始持有者释放。如果多个线程竞争相同的互斥锁，则一次只允许一个线程访问它。 |
| Recursive lock | 递归锁是互斥锁的一种变体。递归锁允许单个线程在释放它之前多次获取锁。其他线程会一直处于阻塞状态，直到锁的拥有者释放该锁的次数与获取它的次数相同时。递归锁主要在递归迭代期间使用，但是也可能在多个方法需要分别获取锁的情况下使用。 |
| Read-write lock | 读写锁也被称为共享互斥锁。这种类型的锁通常被用于较大规模的操作，如果受保护的数据结构被频繁读取并且仅偶尔被修改，则使用读写锁能够显著提高性能。在正常操作期间，当一个线程想要写入结构时，它会阻塞，直到所有正在读取结构的线程释放锁，在此时写入线程获取锁并可以更新结构。当写入线程正在使用锁时，新的读取线程将阻塞，直到写入线程完成操作并释放锁。系统仅支持使用POSIX线程的读写锁。 |
| Distributed lock | 分布式锁提供进程级别的互斥访问。与真正的互斥锁不同，分布式锁不会阻塞线程或者阻止进程运行。它只是在锁忙碌时报告，并让进程决定如何继续进行。 |
| Spin lock | 自旋锁反复轮询其锁条件，直到该条件成立。自旋锁最常用于预期等待锁的时间较短的多处理系统。在这些情况下，轮询通常比阻塞线程更有效，后者涉及上下文切换和线程数据结构的更新。由于自旋锁的轮询性质，系统不提供自旋锁的任何实现，但是可以在特定情况下轻松实现它们。有关在内核中实现自旋锁的信息，请参看[Kernel Programming Guide](https://developer.apple.com/library/content/documentation/Darwin/Conceptual/KernelProgramming/About/About.html#//apple_ref/doc/uid/TP30000905)。 |
| Double-checked lock | 双重检查锁是一种通过在加锁之前检验锁标准来降低加锁的开销的尝试。由于双重检查锁可能是不安全的，系统不提供对它们的明确支持，因此不鼓励使用它们。 |

> **注意**：大多数类型的锁和内存屏障用来确保在进入临界区之前，任何之前的加载和存储指令已被完成。

### 条件

条件是另一种类型的信号量，它允许线程在特定条件为真时互相发送信号。条件通常用于指示资源的可用性或者确保任务按照特定顺序执行。当线程验证一个条件时，它会阻塞，除非该条件已成立。它会一直阻塞，直到其他线程明确更改条件并向条件发出信号。条件和互斥锁之间的区别在于多个线程可以同时访问条件。条件更像是看门人，其依靠一些特定的标准来允许不同的线程通过门。

可以使用条件来管理待定事件池。当事件队列中有事件时，事件队列将使用条件变量来发送信号给正在等待的线程。如果有事件到达，队列会相应地发送信号给条件。如果线程已经处于等待状态，它会被唤醒，然后它会从队列中取出事件并处理该事件。如果两个事件大致同时进入队列，则队列将两次发送信号给条件以唤醒两个线程。

系统为使用几种不同技术的条件提供了支持。但是，正确的条件的实现需要仔细的编写代码，在代码中使用条件之前，请参看[使用条件](turn)。

### 执行选择器例程

Cocoa应用程序有一种方便的将消息以同步方式传递给单个线程的方式。`NSObject`类声明了在应用程序的活跃线程上执行选择器的方法，这些方法允许线程异步传递消息，并保证它们被目标线程同步执行。例如，可以使用执行选择器消息来将分布式计算的结果传递到应用程序的主线程或指定的协调器线程。执行选择器的每个请求都会在目标线程的run loop中排队，然后按照请求被接收的顺序来处理它们。

## 开销与性能

同步有助于确保代码的正确性，但这样做会牺牲性能。同步工具的使用会带来延迟，即使在无竞争的情况下也是如此。锁和原子操作通常涉及内存屏障和内核级同步的使用来确保代码得到适当的保护。并且如果存在锁争用，线程可能会阻塞并经受更大的延迟。

下表列出了在无竞争的情况下与互斥锁和原子操作有关的一些近似成本。这些测量值代表了几千个样本的平均时间。与线程创建时间一样，互斥锁采集事件（即使在无竞争的情况下）也会因为处理器负载、 计算机速度以及可用系统和程序内存的数量而有很大的差异。

| Item | Approximate cost | Notes |
|-------|---------------------|---------|
| Mutex acquisition time | 大约0.2微秒 | 这是在无竞争的情况下的锁获取时间。如果锁由另一个线程保存，则获取时间可能会更长。这些数据是通过分析在基于intel的使用2 GHz Core Duo处理器和运行OS X v10.5 的RAM为1 GB的iMac上锁获取期间生成的平均值和中位值确定的。 |
| Atomic compare-and-swap | 大约0.05微秒 | 这是在无竞争的情况下的`compare-and-swap`时间。这些数据是通过分析在基于intel的使用2 GHz Core Duo处理器和运行OS X v10.5 的RAM为1 GB的iMac上锁获取期间生成的平均值和中位值确定的。 |

在设计并发任务时，正确性始终是最重要的因素，但也要考虑性能因素。如果在多线程下正确执行的代码与在单个线程上运行的相同代码相比，运行速度要更慢，那么并发执行就没有任何益处。

如果正在改进现有的单线程应用程序，则应该始终对关键任务的性能进行一系列基础测量。在添加额外的线程后，应该对这些相同的人物进行新的测量，并将多线程案例的性能与单线程案例进行比较。如果在调整代码之后，线程并不能提高性能，则可能需要重新考虑我们的特定实现或者线程的使用。

## 线程安全和信号

当涉及到多线程的应用程序时，没有什么比处理信号更能引起恐惧和困惑。信号是一种低级的BSD机制，可用于向进程传递信息或者以某种方式操作进程。一些程序使用信号来检测某些事件，例如子进程的死亡。系统使用信号来终止失控的进程并传达其他类型的信息。

信号的问题不是它们做了什么，而是当应用程序具有多个线程时它们的行为。在单线程应用程序中，所有信号处理程序都在主线程上运行。在多线程应用程序中，与特定硬件错误（例如非法指令）无关的信号将被传递到当前正在运行的任何线程上。如果多个线程同时运行，则信号会被传递到系统碰巧挑选的任何一个线程。

在应用程序中实现信号处理程序的首要规则是避免假设哪个线程正在处理信号。如果某个特定的线程想要处理给定的信号，则需要在信号到达时通过某种方式通知该线程。不能仅仅假设在某个线程安装信号处理程序后信号就会被传递到该线程。

## 线程安全设计提示

同步工具是使代码线程安全的有用方法，但它们不是万能的。使用太多的锁和其他类型的同步原函数实际上会降低应用程序的线程性能，找到安全和性能之间的正确平衡是一门需要经验的艺术。以下部分提供的提示可以帮助我们为应用程序选择合适的同步级别。

### 避免完全同步

对于任何新的项目，甚至是现有的项目，设计代码和数据结构来避免同步的需求是最好的解决方案。虽然锁和其他同步工具非常有用，但它们的确会影响任何应用程序的性能。如果整体设计造成特定资源的频繁争用，则线程可能会等待更长时间。

实现并发的最好方式是减少并发任务之间的交互和相互依赖。如果每个任务都操作自己的专用数据结构，则不需要使用锁保护该数据。即使在两个任务共享一个通用数据集的情况下，也可以通过注意数据集分区的方式或者为每个任务提供自己的副本来保护数据。当然，复制数据集也会带来成本，因此必须在做出决定之前将这些成本与同步成本进行权衡。

### 了解同步的限制

同步工具只有在应用程序中的所有线程都使用它们时才有效。如果创建一个互斥锁来限制对特定资源的访问，则所有线程都必须尝试在操作资源之前获取相同的互斥锁。如果不这样做，会破坏互斥锁提供的保护，这是一个程序员错误。

### 注意代码正确性的威胁

在使用锁和内存屏障时，应该始终仔细考虑它们在代码中的位置。即使看起来放置的很好的锁也能让我们陷入虚假的安全感。以下一系列示例试图通过指出看起来无害的代码缺陷来说明这个问题。基本前提是我们有一个包含一组不可变对象的可变数组，假设我们我们想调用数组中第一个对象的方法，则可能使用下面的代码：
```
NSLock* arrayLock = GetArrayLock();
NSMutableArray* myArray = GetSharedArray();
id anObject;

[arrayLock lock];
anObject = [myArray objectAtIndex:0];
[arrayLock unlock];

[anObject doSomething];
```
因为数组是可变的，所以数组周围的锁可以防止其他线程修改数组，直到获得所需的对象。由于我们检索的对象本身是不可变的，因此在调用doSomething方法时不需要加锁。

不过，上面的例子存在问题。如果我们释放锁，并且另一个线程在执行doSomething方法之前删除数组中的所有对象，会发生什么？在没有垃圾回收的应用程序中，代码所持有的对象可能会被释放，从而导致anObject指向无效的内存地址。要解决这个问题，我们可能决定只是重新安排现有代码，并在调用doSomething方法后才释放锁，如下所示：
```
NSLock* arrayLock = GetArrayLock();
NSMutableArray* myArray = GetSharedArray();
id anObject;

[arrayLock lock];
anObject = [myArray objectAtIndex:0];
[anObject doSomething];
[arrayLock unlock];
```
通过移动锁内的doSomething调用，我们的代码可以确保在调用方法时对象仍然有效。不幸的是，如果doSomething方法需要很长时间才能执行，这可能会导致我们的代码长时间处于锁定状态，这可能会导致性能瓶颈。

代码的问题并不在于关键区域定义不明确，而是实际问题没有得到理解。真正的问题是只能由存在的其他线程触发的内存管理问题。因为它可以被另一个线程释放，所以更好的解决方案是在释放锁之前保留anObject。这个解决方案解决了被释放对象的实际问题，并且不会带来潜在的性能损失。
```
NSLock* arrayLock = GetArrayLock();
NSMutableArray* myArray = GetSharedArray();
id anObject;

[arrayLock lock];
anObject = [myArray objectAtIndex:0];
[anObject retain];
[arrayLock unlock];

[anObject doSomething];
[anObject release];
```
虽然上面的例子非常简单，但它们确实说明了一个非常重要的问题。当谈到正确性时，必须考虑这些不那么显而易见的问题。内存管理和设计的其他方面也可能会受到多线程的影响，所以必须事先考虑这些问题。另外，我们应该总是假设编译器会在安全方面做出最糟糕的事情。这种意识和警惕性可以帮助我们避免潜在的问题，并确保我们的代码正确运行。

### 注意死锁和活锁

任何一个线程试图同时使用多个锁，就有可能发生死锁。当两个不同的线程持有另一个线程需要的锁并尝试获取另一个线程持有的锁时，会发生死锁。结果是每个线程永久阻塞，因为它永远无法获取其他锁。

活锁类似于死锁，并且发生在两个线程竞争同一组资源时。在活锁情况下，一个线程在试图获取第二个锁时放弃它的第一个锁。一旦它获得第二个锁，它就会返回并尝试再次获取第一个锁。由于该线程花费所有时间释放一个锁并试图获得另一个锁而不是做任何真正的工作，它就被锁定了。

避免死锁和活锁情况的最好方式是一次只取一个锁。如果一次必须获得一个以上的锁，则应该确保其他线程不会尝试做类似的事情。

### 正确使用Volatile变量

如果已经在使用互斥锁来保护一段代码，则不要自动假设需要使用`volatile`关键字来保护该段代码中的重要变量。互斥锁包含一个内存屏障来确保加载和存储操作的正确顺序。使用`volatile`关键字修饰临界区域内的变量会强制每次访问时从内存加载该变量的值。两种同步技术的组合在特定情况下可能是必要的，但是也会导致显著的性能损失。如果只使用互斥锁就能过保护变量了，则不再使用`volatile`关键字。

不要尝试通过使用volatile变量来避免互斥锁的使用也是非常重要的。通常情况下，相对于volatile变量，互斥锁和其他同步机制是保护数据结构完整性的一种更好的方式。`volatile`关键字只是确保变量从内存中加载，它不能确保代码正确访问该变量。

## 使用原子操作

非阻塞同步是执行某些类型的操作并避免锁的开销的一种方式。虽然锁是同步两个线程的有效方式，但即使在无竞争的情况下，获取锁也是一项相对昂贵的操作。相比之下，许多原子操作只需要一小部分时间来完成，并且可以像锁一样有效。

原子操作允许我们对32位或者64位值执行简单的数学和逻辑运算。这些操作依赖于特俗的硬件指令（以及可选的内存屏障）来确保在受影响的内存被再次访问之前完成给定的操作。在多线程的情况下，应该始终使用包含内存平展的原子操作来确保内存在多个线程之间正确同步。

下表列出了可用的原子数学和逻辑运算以及相应的函数名称。这些函数都在/usr/include/libkern/OSAtomic.h头文件中声明，还可以在其中找到完整的语法。这些函数的64位版本仅在64位进程中可用。

| Operation | Function | Description |
|-------------|-----------|---------------|
| Add | OSAtomicAdd32<br>OSAtomicAdd32Barrier<br>OSAtomicAdd64<br>OSAtomicAdd64Barrier | 将两个整数值相加并将结果存储在指定变量中。 |
| Increment | OSAtomicIncrement32<br>OSAtomicIncrement32Barrier<br>OSAtomicIncrement64<br>OSAtomicIncrement64Barrier | 将指定的整数值递增1。 |
| Decrement | OSAtomicDecrement32<br>OSAtomicDecrement32Barrier<br>OSAtomicDecrement64<br>OSAtomicDecrement64Barrier | 将指定的整数值递减1。 |
| Logical OR | OSAtomicOr32<br>OSAtomicOr32Barrier | 在指定的32位值和32位掩码之间执行逻辑或。 |
| Logical AND | OSAtomicAnd32<br>OSAtomicAnd32Barrier | 在指定的32位值和32位掩码之间执行逻辑于。 |
| Logical XOR | OSAtomicXor32<br>OSAtomicXor32Barrier | 在指定的32位值和32位掩码之间执行逻辑异或。 |
| Compare and swap | OSAtomicCompareAndSwap32<br>OSAtomicCompareAndSwap32Barrier<br>OSAtomicCompareAndSwap64<br>OSAtomicCompareAndSwap64Barrier<br>OSAtomicCompareAndSwapPtr<br>OSAtomicCompareAndSwapPtrBarrier<br>OSAtomicCompareAndSwapInt<br>OSAtomicCompareAndSwapIntBarrier<br>OSAtomicCompareAndSwapLong<br>OSAtomicCompareAndSwapLongBarrier | 将变量与指定的旧值进行比较。如果两个值相等，则该函数将指定的新值赋给变量；否则，它什么都不做。比较和赋值是作为一个原子操作完成的，并且该函数返回一个布尔值来指示交换实际是否发生。 |
| Test and set | OSAtomicTestAndSet<br>OSAtomicTestAndSetBarrier | 测试指定变量中的一个位（bit），将该位设置为1，并将旧位的值作为布尔值返回。根据字节（（char*）地址 + （n >> 3））的公式（0x80 >> （n&7））对位进行测试，其中n是位编号，地址是指向变量的指针。该公式有效地将变量分解为8位大小的块，并将每个块中的位反向排序。例如，要测试一个32位整数的最低位（位0），实际上应该指定位编号为7；类似地，为了测试最高位（位32），应该指定位编号为24。 |
| Test and clear | OSAtomicTestAndClear<br>OSAtomicTestAndClearBarrier | 测试指定变量中的一个位（bit），将该位设置为0，并将旧位的值作为布尔值返回。根据字节（（char*）地址 + （n >> 3））的公式（0x80 >> （n&7））对位进行测试，其中n是位编号，地址是指向变量的指针。该公式有效地将变量分解为8位大小的块，并将每个块中的位反向排序。例如，要测试一个32位整数的最低位（位0），实际上应该指定位编号为7；类似地，为了测试最高位（位32），应该指定位编号为24。 |

大多数原子函数的行为相对简单直接，但是上表中显示的原子`test-and-set`和`compare-and-swap`操作的行为稍微复杂一点。前三个`OSAtomicTestAndSet`函数调用演示了如何在整数值上使用位操作公式，其结果可能与我们所期望的不同。最后两个调用显示了`OSAtomicCompareAndSwap32`函数的行为。在所有情况下，当没有其他线程正在操作这些值时，这些函数在无竞争的情况下被调用。
```
int32_t  theValue = 0;
OSAtomicTestAndSet(0, &theValue);
// theValue is now 128.

theValue = 0;
OSAtomicTestAndSet(7, &theValue);
// theValue is now 1.

theValue = 0;
OSAtomicTestAndSet(15, &theValue)
// theValue is now 256.

OSAtomicCompareAndSwap32(256, 512, &theValue);
// theValue is now 512.

OSAtomicCompareAndSwap32(256, 1024, &theValue);
// theValue is still 512.
```

## 使用锁

锁是线程编程的基本同步工具。锁可让我们轻松保护大量代码，以确保代码的正确性。OS X和iOS为所有应用程序类型提供了基本的互斥锁，Foundation框架为特殊情况定义了一些另外的互斥锁的变体。以下部分展示如何使用其中几种锁类型。

### 使用POSIX互斥锁

POSIX互斥锁非常易于在任何应用程序中使用。要创建互斥锁，可以声明并初始化一个`pthread_mutex_t`结构。要锁定和解锁互斥锁，可以使用`pthread_mutex_lock`和`pthread_mutex_unlock`函数。当不需要再使用锁时，只需要调用`pthread_mutex_destroy`函数释放锁数据结构即可。如下所示：
```
pthread_mutex_t mutex;
void MyInitFunction()
{
    pthread_mutex_init(&mutex, NULL);
}

void MyLockingFunction()
{
    pthread_mutex_lock(&mutex);
    // Do work.
    pthread_mutex_unlock(&mutex);
}
```
> **注意**：上面的代码只是一个用来显示POSIX线程互斥锁函数的基本用法的简单例子，在实际使用时应该检查这些函数返回的错误码并适当地处理它们。

### 使用NSLock类

`NSLock`对象为Cocoa应用程序实现了一个基本的互斥锁。所有锁的接口（包括`NSLock`）实际上都由`NSLocking`协议定义，该协议定义了`lock`和`unlock`方法。可以像使用互斥锁一样使用这些方法来获取和释放锁。

除了标准的锁定行为，`NSLock`类还添加了`tryLock`和`lockBeforeDate:`方法。`tryLock`方法试图获取锁时，如果锁不可用，它不会阻塞当前线程。相反，该方法只是返回`NO`。`lockBeforeDate:`方法试图获取锁时，如果在指定时间限制内未获取到锁，则会取消阻塞线程（并返回`NO`）。

以下示例显示了如何使用`NSLock`对象来协调可视化显示的更新，需要显示的数据由多个线程计算。如果线程无法立即获取锁，则只需要继续计算，直到它可以获取锁并更新显示。
```
BOOL moreToDo = YES;
NSLock *theLock = [[NSLock alloc] init];
...
while (moreToDo) 
{
    /* Do another increment of calculation */
    /* until there’s no more to do. */
    if ([theLock tryLock]) 
    {
        /* Update display used by all threads. */
        [theLock unlock];
    }
}
```

### 使用@synchronized指令

`@synchronized`指令是在Objective-C代码中快速创建互斥锁的一种便捷方式。`@synchronized`指令执行任何其他互斥锁都会执行的操作，它能防止不同线程同时获取同一个锁。在这种情况下，不必直接创建互斥锁或者锁对象。
```
- (void)myMethod:(id)anObj
{
    @synchronized(anObj)
    {
        // Everything between the braces is protected by the @synchronized directive.
    }
}
```
传递给`@synchronized`指令的对象是用于区别受保护块的唯一标识符。如果在两个不同的线程执行`myMethod:`方法并在每个线程上为anObj参数传递不同的对象，则每个线程都会加锁并继续处理而不被另一个线程阻塞。但是，如果同样情况下传递的是相同的对象，其中一个线程将首先获取锁，另一个线程会被阻塞，直到第一个线程退出临界区。

作为预防措施，`@synchronized`块隐式地将一个异常处理程序添加到受保护的代码中。如果抛出异常，该处理程序会自动释放互斥锁。这意味着为了使用`@synchronized`指令，还必须在代码中启用Objective-C异常处理。如果不想要由隐式异常处理程序引起的额外开销，则应该考虑使用锁类。

### 使用其他Cocoa锁

#### 使用NSRecursiveLock对象

`NSRecursiveLock`类定义了一个锁，它可以被同一个线程多次获取而不会导致线程死锁。递归锁会记录锁被成功获取的次数，每次成功获取锁后之必须通过相应的解锁锁来保持平衡。只有当所有的锁定和解锁调用平衡时，锁才会被释放，以便其他线程可以获取它。

这种类型的锁常用于递归函数中，以防止递归阻塞线程。也可以类似地在非递归的情况下使用它来调用需要锁定的函数。这是一个简单递归函数的例子，其通过递归来获取锁。如果不是使用`NSRecursiveLock`对象为此函数加锁，则当再次调用该函数时，该线程将死锁。
```
NSRecursiveLock *theLock = [[NSRecursiveLock alloc] init];

void MyRecursiveFunction(int value)
{
    [theLock lock];
    if (value != 0)
    {
        --value;
        MyRecursiveFunction(value);
    }
    [theLock unlock];
}

MyRecursiveFunction(5);
```
> **注意**：因为在所有的锁定和解锁调用保持平衡之前递归锁不会被释放，所以应该仔细衡量使用性能锁来应对潜在性能影响的决定。长时间保持锁定会导致其他线程阻塞直到递归完成。如果可以重写代码以消除递归或消除使用递归锁的需要，则可能会获得更好的性能。

#### 使用NSConditionLock对象

`NSConditionLock`对象定义了一个可以使用特定值来锁定和解锁的互斥锁。**不应该将这种类型的锁与条件混淆。** 其行为与条件有些类似，但它们的实现有很大差异。

通常情况下，当线程需要按照特定顺序执行任务时（例如，当一个线程生产另一个线程消费的数据时），可以使用`NSConditionLock`对象。当生产者正在执行时，消费者使用特定于应用程序的条件来获取锁。（条件本身只是我们定义的整数值。）当生产者完成时，它解锁锁并将锁条件设置为适当的整数值以唤醒消费者线程，然后消费者线程继续处理数据。

`NSConditionLock`对象响应的锁定和解锁方法可以被任意组合使用。例如，可以将锁定消息与`unlockWithCondition:`配对使用，或者将`lockWhenCondition:`消息与解锁配对使用。当然，后一种组合解锁了锁，但可能不会释放等待特定条件值的任何线程。

一些示例显示了如何使用条件锁来处理生产者-消费者问题。想象一下，应用程序包含一个数据队列。生产者线程将数据添加到队列中，消费者线程从队列中提取数据。生产者不需要等待特定条件，但它必须等待锁可用，以便它可以安全地将数据添加到队列中。
```
id condLock = [[NSConditionLock alloc] initWithCondition:NO_DATA];

while(true)
{
    [condLock lock];
    /* Add data to the queue. */
    [condLock unlockWithCondition:HAS_DATA];
}
```
因为锁的初始条件设置为`NO_DATA`，所以生产者线程在最初获取锁时应该没有问题。它将数据填充到队列中并将条件设置为`HAS_DATA`。在随后的迭代过程中，生产者线程可以在新数据到达时添加该数据而不管队列是空的还是仍然有一些数据。生产者线程会阻塞的唯一时刻是消费者线程正在从队列中提取数据。

因为消费者线程必须有数据处理，所以它使用特定的条件在队列上等待。当生产者将数据添加到队列中时，消费者线程被唤醒并获取锁。然后它可以从队列中提取数据并更新队列状态。以下示例显示了消费者线程的处理循环的基本结构。
```
while (true)
{
    [condLock lockWhenCondition:HAS_DATA];
    /* Remove data from the queue. */
    [condLock unlockWithCondition:(isEmpty ? NO_DATA : HAS_DATA)];

    // Process the data locally.
}
```

#### 使用NSDistributedLock对象

`NSDistributedLock`类可以被多个主机上的多个应用程序使用，以限制对某些共享资源（如文件）的访问。锁本身实际上是一个使用文件系统项目（例如文件或目录）实现的互斥锁。要使`NSDistributedLock`对象可用，锁必须可供所有使用它的应用程序执行写入操作。这通常意味着要将其放置于所有运行该应用程序的计算机都可访问的文件系统中。

与其他类型的锁不同，`NSDistributedLock`不遵循`NSLocking`协议，因此没有`lock`方法。`lock`方法会阻塞线程的执行并要求系统以预定速率轮询锁。`NSDistributedLock`提供了一个`tryLock`方法，并且由使用者自己决定是否轮询。

由于它是使用文件系统实现的，因此只有当`NSDistributedLock`对象的持有者明确释放它时，其才会被释放。**如果应用程序在持有分布式锁时崩溃，其他客户端将无法访问受保护资源。在这种情况下，可以使用`breakLock`方法来打破现有的锁，以便能够获取该锁。但是，通常应该避免打破锁，除非进程已经死亡并且无法释放锁。**

与其他类型的锁一样，当`NSDistributedLock`对象使用完毕时，通过调用其`unlock`方法来释放它。

## 使用条件

条件是一种特殊类型的锁，可以使用它来同步操作的执行顺序。等待条件的线程将一直处于阻塞状态，直到另一个线程显式地发送信号给该条件。

由于涉及到实现操作系统的微妙之处，即使我们的代码没有发送信号到条件锁，条件锁也被允许返回虚假的成功。为了避免由这些虚假信号引起的问题，应该始终将谓词和条件锁结合起来使用。谓词是确定线程继续执行是否安全的更具体的方法。条件使线程保持休眠状态，直到谓词可以由信号线程设置。

### 使用NSCondition类

`NSCondition`类提供与POSIX条件相同的语义，但将所需的锁和条件数据结构封装在单个对象中。以下代码显示了在`NSCondition`对象上等待的事件序列。`cocoaCondition`变量包含了一个`NSCondition`对象，`timeToDoWork`变量是一个整数，从另一个线程发送信号给条件之前，其会递增。
```
[cocoaCondition lock];
while (timeToDoWork <= 0)
[cocoaCondition wait];

timeToDoWork--;

// Do real work here.

[cocoaCondition unlock];
```
```
[cocoaCondition lock];
timeToDoWork++;
[cocoaCondition signal];
[cocoaCondition unlock];
```

### 使用POSIX条件

POSIX线程条件锁需要同时使用条件数据结构和互斥锁。虽然两个锁结果是分开的，但互斥锁在运行时与条件结构紧密相连。等待信号的线程应始终使用相同的互斥锁和条件结构。更改配对可能会导致错误。

以下代码显示了条件和谓词的基本初始化和用法。初始化条件和互斥锁后，等待线程使用`ready_to_go`变量作为谓词进入while循环。只有当谓词被设置并且条件随后发出信号时，等待线程才会醒来并开始工作。
```
pthread_mutex_t mutex;
pthread_cond_t condition;
Boolean     ready_to_go = true;

void MyCondInitFunction()
{
    pthread_mutex_init(&mutex);
    pthread_cond_init(&condition, NULL);
}

void MyWaitOnConditionFunction()
{
    // Lock the mutex.
    pthread_mutex_lock(&mutex);

    // If the predicate is already set, then the while loop is bypassed;
    // otherwise, the thread sleeps until the predicate is set.
    while(ready_to_go == false)
    {
        pthread_cond_wait(&condition, &mutex);
    }

    // Do work. (The mutex should stay locked.)

    // Reset the predicate and release the mutex.
    ready_to_go = false;
    pthread_mutex_unlock(&mutex);
}
```
信号线程负责设置谓词并将信号发送到条件锁。以下代码中，该条件在互斥锁内部发出信号，以防止发生在条件竞争。
```
void SignalThreadUsingCondition()
{
    // At this point, there should be work for the other thread to do.
    pthread_mutex_lock(&mutex);
    ready_to_go = true;

    // Signal the other thread to begin work.
    pthread_cond_signal(&condition);

    pthread_mutex_unlock(&mutex);
}
```

