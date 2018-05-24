mb_recipe :user do
  during :provision, %w(add install_public_key add_to_sudoers)
end

namespace :mb do
  namespace :user do
    desc "Create the UNIX user if it doesn't already exist"
    task :add do
      privileged_on roles(:all) do |host, user|
        unless test("sudo grep -q #{user}: /etc/passwd")
          execute :sudo, "adduser", "--disabled-password", user, "</dev/null"
        end
      end
    end

    desc "Copy root's authorized_keys to the user account if it doesn't "\
         "already have its own keys"
    task :install_public_key do
      root = fetch(:mb_privileged_user)

      privileged_on roles(:all) do |host, user|
        unless test("sudo [ -f /home/#{user}/.ssh/authorized_keys ]")
          execute :sudo, "mkdir", "-p", "/home/#{user}/.ssh"
          execute :sudo, "cp", "~#{root}/.ssh/authorized_keys",
                               "/home/#{user}/.ssh"
          execute :sudo, "chown", "-R", "#{user}:#{user}", "/home/#{user}/.ssh"
          execute :sudo, "chmod", "600", "/home/#{user}/.ssh/authorized_keys"
        end
      end
    end

    desc "Add the user to sudoers without password"
    task :add_to_sudoers do
      privileged_on roles(:all) do |host, user|
        execute :sudo "echo '#{user} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/#{application_basename}"
      end
    end
  end
end
