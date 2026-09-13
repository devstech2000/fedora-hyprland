if status is-interactive
# Commands to run in interactive sessions can go here
end

if status is-login
    if test (tty) = /dev/tty1
        exec uwsm start hyprland.desktop
    end
end

fish_add_path ~/.local/bin
