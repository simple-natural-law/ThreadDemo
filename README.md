# 线程编程指南 -- 关于线程编程

多年来，计算机的最高性能在很大程度上受限于计算机内核中单个微处理器的运算速度。然而，随着单个处理器的运算速度开始达到其实际限制，芯片制造商切换到多核设计来使计算机有机会同时执行多个任务。虽然OS X无论何时都在利用这些内核执行与系统相关的任务，但我们自己的应用程序也可以通过线程来利用这些内核。


## 什么是线程？

线程是在应用程序内部实现多个执行路径的相对轻量级的方式。在系统层面，程序并排运行，系统根据程序的需求和其他程序的需求为每个程序分配执行时间。但是在每个程序中，存在一个或多个可用于同时或以几乎同时的方式执行不同的任务的执行线程。系统本身实际上管理着这些执行线程，并调度它们到可用内核上运行。同时，还能根据需要提前中断它们以允许其他线程运行。

从技术角度讲，线程是管理代码执行所需的内核级和应用级数据结构的组合。内核级数据结构协调调度事件到线程和在一个可用内核中抢先调度线程。应用级数据结构包含用于存储函数调用的调用堆栈和应用程序需要用于管理和操作线程的属性和状态的结构。

在非并发的应用程序中，只有一个执行线程。该线程以应用程序的主例程开始和结束，并逐个分支到不同的方法或函数中，以实现应用程序的整体行为。相比之下，支持并发的应用程序从一个线程开始，并根据需要添加更多线程来创建额外的执行路径。每个新路径都有自己的独立于应用程序主例程中的代码运行的自定义启动例程。在应用程序中有多个线程提供了两个非常重要的潜在优势：
- 多个线程可以提高应用程序的感知响应能力。
- 多个线程可以提高应用程序在多核系统上的实时性能。

如果应用程序只有一个线程，那么该线程必须做所有的事情。其必须响应事件，更新应用程序的窗口，并执行实现应用程序行为所需的所有计算。只有一个线程的问题是它一次只能做一件事情。如果一个计算需要很长时间才能完成，那么当我们的代码忙于计算它所需的值时，应用程序会停止响应用户事件和更新其窗口。如果这种行为持续时间足够长，用户可能会认为我们的应用程序被挂起了并试图强行退出它。但是，如果将自定义计算移至单独的线程，则应用程序的主线程可以更及时地自由响应用户交互。

随着多核计算机的普及，线程提供了一种提高某些类型应用程序性能的方法。执行不同任务的线程可以在不同的处理器内核上同时执行，从而使应用程序可以在给定的时间内执行更多的工作。

当然，线程并不是解决应用程序性能问题的万能药物。线程提供的益处也会带来潜在的问题。在应用程序中执行多个路径可能会增加代码的复杂度。每个线程必须与其他线程协调行动，以防止它破坏应用程序的状态信息。由于单个应用程序中的线程共享相同的内存空间，所有它们可以访问所有相同的数据结构。如果两个线程试图同时操作相同的数据结构，则其中一个线程可能会以破坏数据结构的方式覆盖另一个线程的更改。即使有适当的保护措施，我们仍然需要对编译器优化保持注意，因为编译器优化会在我们的代码中引入细微的错误。
