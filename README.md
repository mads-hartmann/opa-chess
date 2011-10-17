Opachess
========

Description
-----------

Opachess is a multiplayer (no AI) chess game implemented using the Opa Programming 
Language. This is my (Mads Hartmann Jensen) entry to the Opa Developer Competition. 

**NOTE**: For some reason moving the chess pieces doesn't work in Firefox but it 
works in Safari/Chrome. My guess is that this is due to a bug in Opa. 

Compilation Instructions
------------------------

I used **Opa compiler (c) MLstate -- version S3.5 -- build 683** to build this. 
Simply 'cd' into the project root and run 

    make
    make run 
    
Now point your browser to 'localhost:8080/signup' to create your account. You'll 
need two different browsers if you're going to play on the same machine.  

Once you've created your account you can see your profile at localhost:8080/user/{username}