function runcpp
    if not test -f main.cpp
        echo "Keine main.cpp im aktuellen Verzeichnis."
        return 1
    end

    g++ -std=c++23 -Wall -Wextra -pedantic main.cpp -o main

    if test $status -eq 0
        ./main
    end
end
