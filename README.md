nds4ios
=======

nds4ios is a port of nds4droid to iOS, which is based on DeSmuME.

http://nds4ios.angelxwind.net/

[DeSmuME](http://desmume.org/) 

[nds4droid](http://jeffq.com/blog/nds4droid/) 


Build Instructions
------------------------

IMPORTANT: Make sure your working directory is devoid of spaces. Otherwise, bad things will happen.

1.  Open Terminal and go to your working directory;

2.  Do
<code>git clone https://github.com/angelXwind/nds4ios.git</code>

3.  then
    <code>cd nds4ios</code>

4.  then
    <code>git submodule update --init</code>

5. Open "nds4ios.xcodeproj", connect your device, select it on Xcode and click the "Run" button (or Command + R). Don't build it for the iOS Simulator.

6. Alternatively, run
    <code>xcodebuild -configuration Release</code>
   from Terminal and then copy the resulting *.app bundle to your /Applications directory on your device.


To-do
------------------------
* Clean up and refactor code, remove the ugly hacks used (see nds4ios-Prefix and android/log.h)
* JIT/Dynarec (very hard to achieve this using the clang compiler)
* OpenGL ES rendering
* Sound
* Save states
* Native iPad UI
* Properly fix 768h scaling bug
* UI overhaul
* New file chooser (hopefully)
* Addition of L and R buttons
* Option to hide the onscreen controls entirely
* Correct button positions
* Use of cmake to generate Xcode project
* Examine reports of input lag
* Much more.

Contributors
------------------------
* [rock88](http://rock88dev.blogspot.com/)
* [angelXwind](http://angelxwind.net/)
* inb4ohnoes
* WMS
