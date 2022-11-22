# Giovanni Bassi's PowerShell files

These are my personal poshfiles.

## Installation instructions

Install Git and PowerShell Core first, then, from PowerShell Core itself, run:

```powershell
git clone --recursive https://github.com/giggio/poshfiles.git $(Split-Path $Profile)
```

### Installing PowerShell Core and Git

#### Windows

From cmd or Windows PowerShell run:

```cmd
winget install git.git
winget install Microsoft.PowerShell
```

#### Linux

Check your distro recommendations.

### Setting up

The first time you start PowerShell you will be prompted to run the setup, which will install modules and tools.
If you dismiss it, only part of the tools will work. It will remind you again next time you start it. If you
dismiss it for good, you can always run the [setup script file](./Setup/Setup.ps1) directly. On Windows you will need to run
it from an admin window (because of some extra work it does, like setting up Windows Defender exclusion rules)
and you need PowerShell Core installed
([get it](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows)).

### Platform specific instructions and considerations

#### Windows

Windows has Windows PowerShell and PowerShell Core. They each have their directory for configuration.
You can find the directory by running, in each one `Split-Path $Profile`.
You can run it on each of them, or a better idea is to have a single location and call it from each
profile, that is what I do.
For reference, usually the locations for the profile files are:

For PowerShell Core (the one that is new and better and the one you should be using): `<Documents Directory>\PowerShell\Microsoft.PowerShell_profile.ps1`
[Read more about it](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.2)

For Windows PowerShell (the one that comes with Windows): `<Documents Directory>\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`.
[Read more about it](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1)

**Be aware**: if you have OneDrive configured to backup your Documents directory, it's location will not be at the user Home directory,
but at `$HOME/OneDrive/Documents`.

So, all you need to do is add to the `$PROFILE` file:

```powershell
. <path to this repository>\Microsoft.PowerShell_profile.ps1
```

If you want to setup only in Windows PowerShell or PowerShell core, simply run (in the respective shell):

```powershell
git clone --recursive https://github.com/giggio/poshfiles.git $(Split-Path $Profile)
```

#### Linux

Linux only supports PowerShell Core, so the above command is all you need. The profile should be
at `$env:HOME/.config/powershell`, to clone it from bash, simply run:

```bash
git clone --recursive https://github.com/giggio/poshfiles.git $env:HOME/.config/powershell
```

#### Mac

I don't know, I don't have a Mac, if you do, please send a PR with instructions.
Also, this files have not been tested on a Mac, if they don't work, please, send a PR.

### Other considerations

I have several [aliases](./Profile/CreateAliases.ps1) configured
as well as several modules (see the [.gitmodules](./.gitmodules)
and the [InstallModules.ps1](./Setup/InstallModules.ps1)) files.
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
[Cascadia Code](https://github.com/microsoft/cascadia-code) (which comes with Windows Terminal) and
[Deja Vu](https://github.com/powerline/fonts/blob/master/DejaVuSansMono/DejaVu%20Sans%20Mono%20for%20Powerline.ttf)
(from the powerline repo). They have the glyphs and symbols necessary to show everything as expected.

The best terminal experience on Windows will be with
[Windows Terminal](https://github.com/microsoft/terminal), and you can also use
it with [Conemu](https://conemu.github.io/).
You don't need either to have a nice display if you are on Windows 10 or later. Simply download the font
and set it as default on the PowerShell properties window and everything should work.
If you decide to use Conemu remember to set the main console font and the alternative font to the same
font with the symbols.

## Notes on PowerShell Modules

You might not want some administrations modules I use, such as `AzureADPreview` and `ExchangeOnlineManagement`,
if that is the case you can simply remove their installation in the `InstallModules.ps1`. They will only
install in Windows PowerShell, so only in Windows.

## Contributing

Questions, comments, bug reports, and pull requests are all welcome.  Submit them at
[the project on GitHub](https://github.com/giggio/poshfiles).

Bug reports that include steps-to-reproduce (including code) are the
best. Even better, make them in the form of pull requests.

## Author

[Giovanni Bassi](https://twitter.com/giovannibassi).

## License

Licensed under the MIT License.
