# Mold - an ill-named configuration manager for the fish shell

Mold allows you to manage your [fish shell](http://fishshell.com) configuration via "bundles" (aka "plugins"), much like [antigen](https://github.com/zsh-users/antigen) for zsh or [Vundle](https://github.com/gmarik/Vundle.vim) for Vim.

## Installation

Clone the repository to a safe place (I recommend `~/.config/fish/mold`) then run `source fish/functions/mold.fish` for the initial setup.

## Usage

Mold-compatible plugins can be injected into your configuration with the `mold bundle` subcommand.
Themes are handled by `mold theme`.

For instance, to launch ssh-agent at startup and load your identities if needed via the `ssh-agent_mold` plugin, add the below line to your `config.fish` file:

    mold bundle https://github.com/benjamin-surma/ssh-agent_mold.git

A list of currently installed bundles can be consulted with `mold list`.

Plugins can be updated in-place with `mold update`.

## Guidelines for plugins

Plugins should follow the below folder hierarchy:

    [root]
    |-- autoload
    |-- functions
    |-- completions

The `[root]` directory does not need to be the top folder of the checked out repository. Mold will attempt to infer the folder structure.

#### autoload
Files in the `autoload` folder are automatically sourced on shell startup.

#### functions
Files in the `functions` folder are symlinked to `~/.config/fish/functions/`

### completions
Files in the `completions` folder are symlinked to `~/.config/fish/completions/`
