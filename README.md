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

5. Open "nds4ios.xcodeproj", connect your device, select it on Xcode and click the "Run" button (or Command + R). Don't build it for the iOS Simulator. IMPORTANT: Make sure you change your running scheme to Release first. Otherwise you will get errors on compile!

6. Alternatively, run
    <code>xcodebuild -configuration Release</code>
   from Terminal and then copy the resulting *.app bundle to your /Applications directory on your device.

7. 3rd option: click the button below from your device or desktop:

<!-- MacBuildServer Install Button -->
<div class="macbuildserver-block">
    <a class="macbuildserver-button" href="http://macbuildserver.com/project/github/build/?xcode_project=nds4ios.xcodeproj&amp;target=nds4ios&amp;repo_url=https%3A%2F%2Fgithub.com%2FangelXwind%2Fnds4ios.git&amp;build_conf=Release" target="_blank"><img src="http://com.macbuildserver.github.s3-website-us-east-1.amazonaws.com/button_up.png"/></a><br/><sup><a href="http://macbuildserver.com/github/opensource/" target="_blank">by MacBuildServer</a></sup>
</div>
<!-- MacBuildServer Install Button -->




To-do
------------------------
* Clean up and refactor code, remove the ugly hacks used (see nds4ios-Prefix and android/log.h)
* JIT/Dynarec (very hard to achieve this using the clang compiler)
* OpenGL ES rendering
* Sound
* Save states
* Native iPad UI
* Properly fix 768h scaling bug (in progress)
* UI overhaul (in progress)
* New file chooser (in progress)
* Addition of L and R buttons(Done!)
* Option to hide the onscreen controls entirely (in progress)
* Correct button positions (in progress)
* New gesture based D-Pad (not current button based) (in progress)
* Use of cmake to generate Xcode project
* Examine reports of input lag
* Much more.

Contributors
------------------------
* [rock88](http://rock88dev.blogspot.com/)
* [angelXwind](http://angelxwind.net/)
* [inb4ohnoes](http://brian.weareflame.co/)
* maczydeco
* [W.MS](http://github.com/peter82315/)
