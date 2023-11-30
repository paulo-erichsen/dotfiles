# script to setup windows after clean install

## pre-setup steps

Prior to configuring windows, make sure that these are configured

1. update BIOS firmware
2. install MOBO drivers
3. install GPU drivers
4. update Windows
5. (optional) enable XMP or EXPO in the BIOS

## steps

1. download this folder
2. open an admin terminal or powershell
3. cd to this folder
4. run `Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process`
5. run `./setup_windows.ps1`

## post-setup steps

- startup: disable useless programs
- set the refresh rate for the monitors according to the max that they support
- windows settings > notifications > disabled
- gpu settings: limit global fps
- discord:
  - windows settings: start minimized
  - game overlay: disabled
- firefox:
  - login to sync extensions and settings
  - configure [cookie exceptions](https://github.com/paulo-erichsen/user.js/blob/master/cookie_exceptions.md)
