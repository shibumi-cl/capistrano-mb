mb_recipe :rvm do
  during :provision, %w(install write_vars)
end

namespace :mb do
  namespace :rvm do
    desc "Install rvm and compile ruby"
    task :install do
      invoke "mb:rvm:run_installer"
      # invoke "mb:rvm:add_plugins"
      # invoke "mb:rvm:modify_bashrc"
      # invoke "mb:rvm:compile_ruby"
    end

    desc "Install the latest version of Ruby"
    task :upgrade do
      # invoke "mb:rvm:add_plugins"
      invoke "mb:rvm:update_rvm"
      # invoke "mb:rvm:compile_ruby"
    end

    desc "Install ruby according to .ruby-version"
    task install_ruby: do
      on release_roles(:all) do
        ruby_version = fetch(:mb_rvm_ruby_version)
        execute "rvm install #{ruby_version}"
      end
    end

    task :write_vars do
      # on release_roles(:all) do
      #   execute :mkdir, "-p ~/.rvm"
      #   execute :touch, "~/.rvm/vars"
      #   execute :chmod, "0600 ~/.rvm/vars"
      #
      #   vars = ""
      #
      #   fetch(:mb_rvm_vars).each do |name, value|
      #     execute :sed, "--in-place '/^#{name}=/d' ~/.rvm/vars"
      #     vars << "#{name}=#{value}\n"
      #   end
      #
      #   tmp_file = "/tmp/rvm_vars"
      #   put vars, tmp_file
      #   execute :cat, tmp_file, ">> ~/.rvm/vars"
      #   execute :rm, tmp_file
      # end
    end

    task :run_installer do

      installer_url = "https://get.rvm.io"

      on release_roles(:all) do
        with :path => "$HOME/.rvm/bin:$HOME/.rvm/shims:$PATH" do
          execute "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
          execute :curl, "-sSL", installer_url, "| bash"
        end
      end
    end


    # task :add_plugins do
    #   plugins = %w(
    #     sstephenson/rvm-vars
    #     sstephenson/ruby-build
    #     rkh/rvm-update
    #   )
    #   plugins.each do |plugin|
    #     git_repo = "https://github.com/#{plugin}.git"
    #     plugin_dir = "$HOME/.rvm/plugins/#{plugin.split('/').last}"
    #
    #     on release_roles(:all) do
    #       unless test("[ -d #{plugin_dir} ]")
    #         execute :git, "clone", git_repo, plugin_dir
    #       end
    #     end
    #   end
    # end

    # task :modify_bashrc do
    #   on release_roles(:all) do
    #     unless test("grep -qs 'rvm init' ~/.bashrc")
    #       template("rvm_bashrc", "/tmp/rvmrc")
    #       execute :cat, "/tmp/rvmrc ~/.bashrc > /tmp/bashrc"
    #       execute :mv, "/tmp/bashrc ~/.bashrc"
    #       execute %q{export PATH="$HOME/.rvm/bin:$PATH"}
    #       execute %q{eval "$(rvm init -)"}
    #     end
    #   end
    # end

    # task :compile_ruby do
    #   ruby_version = fetch(:mb_rvm_ruby_version)
    #   on release_roles(:all) do
    #     force = ENV["RVM_FORCE_INSTALL"] || begin
    #       ! test("rvm list known | grep -q '#{ruby_version}'")
    #     end
    #
    #     if force
    #       execute "CFLAGS=-O3 rvm install --force #{ruby_version}"
    #       execute "rvm global #{ruby_version}"
    #       execute "gem install bundler --no-document"
    #     end
    #   end
    # end

    task :update_rvm do
      on release_roles(:all) do
        execute "rvm update"
      end
    end
  end
end
