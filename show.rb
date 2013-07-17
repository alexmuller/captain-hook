#!/usr/bin/env ruby

require 'octokit'
require 'colorize'

def pretty_print_hook_config(hook, config)
  case hook
  when "campfire"
    pretty = "#{config['subdomain']}##{config['room']}, #{config['token']}"
    if config['sound'].length > 0
      pretty += ", makes a sound (ugh?)"
    end
  when "docker"
    pretty = "no config"
  when "email"
    pretty = "To #{config['address']}, from author is #{config['send_from_author']}"
    if config['secret'].length > 0
      pretty += ", secret is set (shouldn't be?)"
    end
  when "gemnasium"
    pretty = "#{config['user']}, #{config['token']}"
  when "jenkins"
    pretty = config['jenkins_hook_url']
  when "pivotaltracker"
    pretty = config['token']
    if config['branch'].length > 0 or config['endpoint'].length > 0
      pretty += ", branch or endpoint are set (shouldn't be?)"
    end
  when "travis"
    pretty = "#{config['user']}, #{config['token']}"
    if config['domain'].length > 0
      pretty += ", domain set to #{config['domain']} (bad?)"
    end
  when "web"
    pretty = "#{config['url']}"
  else
    pretty = config
  end
  return pretty
end

username = File.open("username", "r").read.strip!
token = File.open("token", "r").read.strip!

client = Octokit::Client.new(:login => username, :oauth_token => token)

repos = IO.readlines("repos").map{ |repo| repo.strip! }

all_repos = {}

repos.each do |repo|
  hooks = client.hooks(repo)
  all_repos[repo] = hooks
end

hook_strings = all_repos.values.flatten(1).map{ |hook| hook['name'] }.uniq.sort

hook_strings.each do |hook|
  puts "Hook: #{hook}"
  all_repos.each do |repo_name, hooks|
    this_repo_hook = hooks.find{ |h| h['name'] == hook }
    if this_repo_hook
      if this_repo_hook['active'] == true
        status = "Yep".colorize(:green)
        config = "(#{pretty_print_hook_config(hook, this_repo_hook['config'])})"
      else
        status = "Inactive".colorize(:yellow)
        config = ""
      end
    else
      status = "Not setup".colorize(:red)
      config = ""
    end
    puts "#{repo_name.rjust(50)}: #{status} #{config}"
  end
  puts "\n"
end
