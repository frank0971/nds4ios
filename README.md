nds4ios
=======

nds4ios is a port of nds4droid to iOS, based on Desmume.

[Desmume](http://desmume.org/) 

[nds4droid](http://jeffq.com/blog/nds4droid/) 


Build Instructions
------------------------

1.  Open Terminal and go to your working directory;

2.  Print
<code>git clone https://github.com/angelXwind/nds4ios.git</code>

3. 
    <code>cd nds4ios</code>

4. 
    <code>git submodule update --init</code>

5. Open "nds4ios.xcodeproj", connect your device, select it on Xcode and click the "Run" button (or Command + R). Don't build it for the iOS Simulator.


To-do
------------------------
* Clean up and refactor code, remove the "ugly hack" (see nds4ios-Prefix and android/log.h)
* JIT/Dynarec (very hard to achieve this using the clang compiler)
* OpenGL ES rendering
* Sound
* Save states
* Proper iPhone 5 and iPad UI
* Better on-screen controls
* Use of cmake to generate Xcode project
* Much more.

Contributors
------------------------
* [rock88](http://rock88dev.blogspot.com/)
* [angelXwind](http://angelxwind.net/)
* WMS

Notes
------------------------
* r32 appears to have brought a severe speed decrease. I will be updating aXw-Repo with the previous build, while moving this to a new branch, net.angelxwind.nds4ios-testing