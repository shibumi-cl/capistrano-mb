mb_recipe :delayed_job do
  during :provision, "systemd"
  during "deploy:start", "start"
  during "deploy:stop", "stop"
  during "deploy:restart", "restart"
  during "deploy:publishing", "restart"
end

namespace :mb do
  namespace :delayed_job do
    desc "Install delayed_job systemd config"
    task :systemd do
      privileged_on roles(fetch(:mb_delayed_job_role)) do |host, user|
        # sidekiq_user = fetch(:mb_sidekiq_user) || user

        template "delayed_job.service.erb",
                 "/etc/systemd/system/delayed_job_#{application_basename}.service",
                 :mode => "a+rx",
                 :binding => binding,
                 :sudo => true

        execute :sudo, "systemctl daemon-reload"
        execute :sudo, "systemctl enable delayed_job_#{application_basename}.service"

        # unless test(:sudo, "grep -qs delayed_job_#{application_basename}.service /etc/sudoers.d/#{user}")
        #   execute :sudo, "touch -f /etc/sudoers.d/#{user}"
        #   execute :sudo, "chmod u+w /etc/sudoers.d/#{user}"
        #   execute :sudo, "echo '#{user} ALL=NOPASSWD: /bin/systemctl start delayed_job_#{application_basename}.service' >> /etc/sudoers.d/#{user}"
        #   execute :sudo, "echo '#{user} ALL=NOPASSWD: /bin/systemctl stop delayed_job_#{application_basename}.service' >> /etc/sudoers.d/#{user}"
        #   execute :sudo, "echo '#{user} ALL=NOPASSWD: /bin/systemctl restart delayed_job_#{application_basename}.service' >> /etc/sudoers.d/#{user}"
        #   execute :sudo, "chmod 440 /etc/sudoers.d/#{user}"
        # end
      end
    end

    %w[start stop restart].each do |command|
      desc "#{command} delayed_job"
      task command do
        on roles(fetch(:mb_delayed_job_role)) do
          execute :sudo, "systemctl #{command} delayed_job_#{application_basename}.service"
        end
      end
    end
  end
end
