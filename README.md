# Giovanni Bassi's PowerShell files

These are my personal poshfiles.

Installation instructions:

````powershell
git clone --recursive https://github.com/giggio/poshfiles.git $env:userprofile\Documents\WindowsPowerShell
````

I have several [aliases](https://github.com/giggio/poshfiles/blob/master/Microsoft.PowerShell_profile.ps1) configured
as well as several [modules](https://github.com/giggio/poshfiles/tree/master/Modules).
Check them out and see if you want to keep them all.

## Notes on fonts
You need a powerline enabled font to get everything to display properly. The only one I have found
that works as expected so far is the
[Deja Vu](https://github.com/powerline/fonts/blob/master/DejaVuSansMono/DejaVu%20Sans%20Mono%20for%20Powerline.ttf)
font from the powerline repo. It has the glyphs and symbols necessary to show everything as expected.

You don't need ConEmu to have a nice display if you are on Windows 10. Simply download the font
and set it as default on the PowerShell properties window and everything should work.

If you decide to use Conemu, you have more options for fonts, but remember to set the main console font
and the alternative font to the same font with the symbols.
