This is plugin for SynLint plugin.
It adds support for Java lexer.

It uses Javac compiler.
You need to create file "javac.bat" in subfolder "PyTools" of SynWrite folder.
Write into "javac.bat" one line pointing to your real "javac.exe":

"C:\Program Files (x86)\Java\jdk1.7.0_51\bin\javac.exe" %1 %2 %3 %4 %5 %6 %7
