@echo off
echo Building Flutter web app...
flutter build web --release

echo Copying files to Firebase public directory...
cd build\web
copy /Y *.html public\
copy /Y *.js public\
copy /Y *.json public\
copy /Y favicon.png public\
xcopy /E /Y assets public\assets\
xcopy /E /Y canvaskit public\canvaskit\
xcopy /E /Y icons public\icons\

echo Deploying to Firebase...
firebase deploy

echo Deploy complete!
pause