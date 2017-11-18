# install razercfg, then
# may need to start `sudo razerd`

razercfg -s # displays the mouse name
# razercfg -d "$(razercfg -s)" -r 1:3
razercfg -d "Mouse:DeathAdder Black Edition:USB-002:1532-0029-0" -R # displays the resolutions available
razercfg -d "Mouse:DeathAdder Black Edition:USB-002:1532-0029-0" -r 1:3 # sets to 1800 DPI
