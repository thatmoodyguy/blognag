set :application, "blognag"
set :repository,  "git@github.com:mentalvelocity/blognag.git"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:port] = 30022


# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git
set :deploy_via, :remote_cache
set :deploy_to, "/home/john/public_html/#{application}"
set :scm_passphrase, "maleldil"
set :git_enable_submodules, 1

role :app, "blognag.mentalvelocity.com"
role :web, "blognag.mentalvelocity.com"
role :db,  "blognag.mentalvelocity.com", :primary => true

namespace :deploy do
  
  desc "Restarting mod_rails with restart.txt" 
  task :restart, :roles => :app, :except => { :no_release => true } do 
    run "touch #{current_path}/tmp/restart.txt" 
  end 
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
end

