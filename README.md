# puconfig

puconfig (portable user configs), is a program that assists in deploying user
configs (ie. bashrc, ssh config, vimrc etc.) to many hosts.  It reads a config
file, and then, depending on various settings, copies or symlinks the configs
in place.

It can also generate a redistributable shell script, that you can copy onto
other machines and run to install your configs. Additionally it can automate
this, and do the copying and running itself.

## Dependencies

puconfig is written in perl, and requires perl to be installed along with the
following modules that are not bundled with perl:
YAML::XS, String::ShellQuote, File::Temp, Moo, File::Basename

The scripts that it outputs, however, have no dependencies except for a working
unix-environment with a shell.

## Configuration

See [manpage.pod](manpage.pod) for config instructions
