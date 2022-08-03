g++ -c main.cpp -ID:\Apps\SFML-2.5.1/include
g++ main.o -o mandelbrot -LD:\Apps\SFML-2.5.1/lib -lsfml-graphics -lsfml-window -lsfml-system -std=c++11
del main.o
pause
start mandelbrot.exe