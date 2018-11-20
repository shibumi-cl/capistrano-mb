mb_recipe :postgresql do
  during :provision, %w(
    create_user
    create_database
    database_yml
    pgpass
    logrotate_backup
  )
end

namespace :mb do
  namespace :postgresql do
    desc "Create user if it doesn't already exist"
    task :create_user do
      privileged_on primary(:db) do
        user = fetch(:mb_postgresql_user)
        unless test("sudo -u postgres psql -c '\\du' | grep -q ' #{user} '")
          passwd = fetch(:mb_postgresql_password)
          md5 = Digest::MD5.hexdigest(passwd + user)
          execute "sudo service postgresql restart"
          execute "sudo -u postgres psql -c " +
                  %Q["CREATE USER #{user} PASSWORD 'md5#{md5}';"]
        end
      end
    end

    desc "Create database if it doesn't already exist"
    task :create_database do
      privileged_on primary(:db) do
        user = fetch(:mb_postgresql_user)
        db = fetch(:mb_postgresql_database)

        unless test("sudo -u postgres psql -l | grep -w -q #{db}")
          execute "sudo -u postgres createdb -O #{user} #{db}"
        end
      end
    end

    desc "Generate database.yml"
    task :database_yml do
      yaml = {
        fetch(:rails_env).to_s => {
          "adapter" => "postgresql",
          "encoding" => "unicode",
          "database" => fetch(:mb_postgresql_database).to_s,
          "pool" => fetch(:mb_postgresql_pool_size).to_i,
          "username" => fetch(:mb_postgresql_user).to_s,
          "password" => fetch(:mb_postgresql_password).to_s,
          "host" => fetch(:mb_postgresql_host).to_s
        }
      }
      fetch(:mb_postgresql_password)
      on release_roles(:all) do
        put YAML.dump(yaml),
            "#{shared_path}/config/database.yml",
            :mode => "600"
      end
    end

    desc "Generate pgpass file (needed by backup scripts)"
    task :pgpass do
      fetch(:mb_postgresql_password)
      on release_roles(:all) do
        template "pgpass.erb",
                 fetch(:mb_postgresql_pgpass_path),
                 :mode => "600"
      end
    end

    desc "Configure logrotate to back up the database daily"
    task :logrotate_backup do
      on roles(:backup) do
        backup_path = fetch(:mb_postgresql_backup_path)
        execute :mkdir, "-p", File.dirname(backup_path)
        execute :touch, backup_path
      end

      privileged_on roles(:backup) do |host, user|
        template\
          "postgresql-backup-logrotate.erb",
          "/etc/logrotate.d/postgresql-backup-#{application_basename}",
          :owner => "root:root",
          :mode => "644",
          :binding => binding,
          :sudo => true
      end
    end

    desc "Dump the database to FILE"
    task :dump do
      on primary(:db) do
        with_pgpassfile do
          execute :pg_dump,
            "-Fc -Z9 -O",
            "-x", fetch(:mb_postgresql_dump_options),
            "-f", remote_dump_file,
            connection_flags,
            fetch(:mb_postgresql_database)
        end

        download!(remote_dump_file, local_dump_file)

        info(
          "Exported #{fetch(:mb_postgresql_database)} "\
          "to #{local_dump_file}."
          )
      end
    end

    desc "Restore database from FILE"
    task :restore do
      on primary(:db) do
        exit 1 unless agree(
          "\nErase existing #{fetch(:rails_env)} database "\
          "and restore from local file: #{local_dump_file}? "
          )

        upload!(local_dump_file, remote_dump_file)

        with_pgpassfile do
          execute :pg_restore,
            "-O -c",
            connection_flags,
            "-d", fetch(:mb_postgresql_database),
            remote_dump_file
        end
      end
    end

    def local_dump_file
      ENV.fetch("FILE", "#{fetch(:mb_postgresql_database)}.dmp")
    end

    def remote_dump_file
      "/tmp/#{fetch(:mb_postgresql_database)}.dmp"
    end

    def connection_flags
      [
        "-U", fetch(:mb_postgresql_user),
        "-h", fetch(:mb_postgresql_host)
      ].join(" ")
    end

    def with_pgpassfile(&block)
      with(:pgpassfile => fetch(:mb_postgresql_pgpass_path), &block)
    end
  end
end
