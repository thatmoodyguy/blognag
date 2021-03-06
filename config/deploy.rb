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
set :rails_env,     'production'


role :app, "blognag.mentalvelocity.com"
role :web, "blognag.mentalvelocity.com"
role :db,  "blognag.mentalvelocity.com", :primary => true

before "deploy", "delayed_job:stop" 
after "deploy", "delayed_job:start"
before "deploy", "tweet_sweeper:stop"
after "deploy", "tweet_sweeper:start"

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

namespace :delayed_job do


  desc "Start delayed_job process" 
  task :start, :roles => :app do
    run "cd #{current_path} && ruby script/delayed_job start #{rails_env}" 
  end

  desc "Stop delayed_job process" 
  task :stop, :roles => :app do
    run "cd #{current_path} && ruby script/delayed_job stop #{rails_env}" 
    #run "sudo killall -q ruby"
  end
end

namespace :tweet_sweeper do

  desc "Start tweet_sweeper process" 
  task :start, :roles => :app do
    run "cd #{current_path} && ruby script/tweet_sweeper start #{rails_env}" 
  end

  desc "Stop tweet_sweeper process" 
  task :stop, :roles => :app do
    run "cd #{current_path} && ruby script/tweet_sweeper stop #{rails_env}" 
  end

end


