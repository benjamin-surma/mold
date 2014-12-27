function __mold_initial_setup
    if not set -q __mold_path
        echo "## mold: Initial setup"
        pushd (dirname (status -f))/../..
        set mold_path (pwd)
        popd
        __mold_install $mold_path
        set -U __mold_path $mold_path
    end
end

function __mold_get_repos_path
    echo $__mold_path/repos
end

function __mold_get_checkout_path_from_bundle_name
    echo (__mold_get_repos_path)/$argv[1]
end

function __mold_get_bundle_name_from_git_url
    echo $argv[1] | sed -E 's/^.*\/([^\/.]*)(\.git|())$/\1/'
end

function __mold_is_git_repo
    test -d $argv[1]/.git
end

function __mold_is_symlink_broken
    set symlink $argv[1]
    pushd (dirname $symlink)
    set broken (not test -e (readlink $symlink); echo $status)
    popd
    return $broken
end

function __mold_install
    # Install bundle functions
    set checkout_path $argv[1]
    for installable in $checkout_path/**/functions/* $checkout_path/**/completions/*
        set installation_path ~/.config/fish/(basename (dirname $installable))
        if not test -d $installation_path
            mkdir -p $installation_path
        end
        ln -fs $installable $installation_path/(basename $installable)
    end
end

function __mold_fixup
    for file in ~/.config/fish/functions/*
        if test -L $file
            if __mold_is_symlink_broken $file
                echo "#### Unlink: $file"
                rm $file
            end
        end
    end
end

function __mold_cleanup
    set obsolete_bundles
    for bundle_name in $__mold_installed_bundles
        if not contains $bundle_name $__mold_loaded_bundles
            set obsolete_bundles $bundle_name $obsolete_bundles
        end
    end
    if count $obsolete_bundles >/dev/null
        echo "The following bundles are obsolete and scheduled to be removed: $obsolete_bundles"
        echo "Continue? (y/n)"
        read -l input
        if test "$input" = "y"
            for obsolete_bundle in $obsolete_bundles
                __mold_uninstall $obsolete_bundle
            end
            __mold_fixup
            set -U __mold_installed_bundles $__mold_loaded_bundles
        end
    end
end

function __mold_list
    for bundle_name in $__mold_installed_bundles
        set checkout_path (__mold_get_checkout_path_from_bundle_name $bundle_name)
        set remote_url (pushd $checkout_path; and git remote show origin -n | grep 'Fetch URL' | sed 's/.*: //'; popd)
        echo "$bundle_name: $remote_url"
    end
end

function __mold_load
    # Inject autoload scripts
    set checkout_path $argv[1]
    for file in $checkout_path/**/autoload/*.fish
        source $file
    end
end

function __mold_uninstall
    # Uninstall a bundle
    set bundle_name $argv[1]
    set checkout_path (__mold_get_checkout_path_from_bundle_name $bundle_name)
    if __mold_is_git_repo $checkout_path
        echo "## $bundle_name: Uninstall"
        rm -rf $checkout_path
    end
end

function __mold_bundle
    # Checkout, install and load a bundle
    set git_url $argv[1]
    set bundle_name (__mold_get_bundle_name_from_git_url $git_url)
    set checkout_path (__mold_get_checkout_path_from_bundle_name $bundle_name)
    if not test -d $checkout_path
        echo "## $bundle_name: Checkout"
        git clone --recursive $git_url $checkout_path
    end
    if not contains $bundle_name $__mold_installed_bundles
        echo "## $bundle_name: First install"
        __mold_install $checkout_path
        set -U __mold_installed_bundles $bundle_name $__mold_installed_bundles
    end
    if not contains $bundle_name $__mold_loaded_bundles
        __mold_load $checkout_path
        set -g __mold_loaded_bundles $bundle_name $__mold_loaded_bundles
    end
end

function __mold_theme
    set bundle_name $argv[1]
    if echo $bundle_name | grep '.git' >/dev/null
        set git_url $bundle_name
        __mold_bundle $git_url
        set bundle_name (__mold_get_bundle_name_from_git_url $git_url)
    end
    set themes_path (__mold_get_checkout_path_from_bundle_name $bundle_name)/**/themes
    for file in $themes_path/*.fish
        ln -fs $file ~/.config/fish/functions/fish_prompt.fish
    end
end

function __mold_update_bundle
    set bundle_name $argv[1]
    set checkout_path (__mold_get_checkout_path_from_bundle_name $bundle_name)
    pushd $checkout_path
    git pull
    popd
    __mold_install $checkout_path
    __mold_load $checkout_path
end

function __mold_update
    for bundle_name in $__mold_installed_bundles
        echo "## $bundle_name: Update"
        __mold_update_bundle $bundle_name
    end
end

function __mold_help
    echo "
mold: manage fish shell configuration bundles.

USAGE: mold <command> [<args>]

Available commands:
  mold bundle <git url>  Install and load the mold bundle from the git url <git url>
  mold theme <git url>   Install and load the mold theme bundle from the git url <git url>
  mold update            Update installed bundles
  mold cleanup           Clean up unused installed bundles
  mold help              Display this message
  mold list              List installed bundles
"
end

function mold
    set sub_command $argv[1]
    if test -z "$sub_command"
        __mold_help
    else
        switch $sub_command
            case bundle
                __mold_bundle $argv[2]
            case theme
                __mold_theme $argv[2]
            case update
                __mold_update
            case cleanup
                __mold_cleanup
            case help
                __mold_help
            case list
                __mold_list
            case ls
                __mold_list
            case '*'
                __mold_help
        end
    end
end

__mold_initial_setup
