# Giovanni Bassi's PowerShell files

These are my personal poshfiles.

Installation instructions:

Windows:

```powershell
git clone --recursive https://github.com/giggio/poshfiles.git $env:userprofile\Documents\WindowsPowerShell
```

Linux:

```powershell
git clone --recursive https://github.com/giggio/poshfiles.git $env:HOME\Documents\WindowsPowerShell
```

I have several [aliases](https://github.com/giggio/poshfiles/blob/master/CreateAliases.ps1) configured
as well as several [modules](https://github.com/giggio/poshfiles/tree/master/Modules).
Check them out and see if you want to keep them all.

## Notes on Vi mode

I use "vi mode" on my shells. If you don't know what this is or don't want it
you should disable it. Just delete the call to `SetViMode.ps1`.

Vim mode will enable **only** if you have `vim` available on your path. If you don't,
then you don't need to worry, it will not enable.

If you want to be super fast on the command line and also when typing in a text
editor, then you should learn vi, vim and vi mode. Just search for it and you
will find more info.

## Notes on fonts

You need a powerline enabled font to get everything to display properly. The only one I have found
that works as expected so far are
[Cascadia Code](https://github.com/microsoft/cascadia-code) and
[Deja Vu](https://github.com/powerline/fonts/blob/master/DejaVuSansMono/DejaVu%20Sans%20Mono%20for%20Powerline.ttf)
from the powerline repo. They have the glyphs and symbols necessary to show everything as expected.

The best terminal experience will be with
[Windows Terminal](https://github.com/microsoft/terminal), and you can also use
it with [Conemu](https://conemu.github.io/).
You don't need either to have a nice display if you are on Windows 10. Simply download the font
and set it as default on the PowerShell properties window and everything should work.
If you decide to use Conemu, you have more options for fonts, but remember to set the main console font
and the alternative font to the same font with the symbols.

## Notes on PowerShell Modules

You might not want some administrations modules I use, such as `AzureADPreview` and `ExchangeOnlineManagement`,
if that is the case you can simply remove their installation in the `InstallModules.ps1`. They will only
install in Windows PowerShell, so only in Windows.
