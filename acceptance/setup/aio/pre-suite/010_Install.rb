require 'puppet/acceptance/common_utils'

test_name "Install Packages"

step "Install puppet-agent..." do
  opts = {
    :puppet_agent_version => ENV['SUITE_VERSION'] || ENV['SHA'],
    :default_action => 'gem_install'
  }
  agents.each do |agent|
    next if agent == master
    
    # Move the openssl libs package to a newer version on redhat platforms
    use_system_openssl = ENV['USE_SYSTEM_OPENSSL']

    if use_system_openssl && agent[:platform].match(/(?:el-7|redhat-7)/)
      rhel7_openssl_version = ENV['RHEL7_OPENSSL_VERSION']
      if rhel7_openssl_version.to_s.empty?
        # Fallback to some default is none is provided
        rhel7_openssl_version = "openssl-1.0.1e-51.el7_2.4.x86_64"
      end
      on(agent, "yum -y install " +  rhel7_openssl_version) 
    else
      step "Skipping upgrade of openssl package... (" + agent[:platform] + ")"
    end

    if ENV['TESTING_RELEASED_PACKAGES']
      # installs both release repo and agent package
      install_puppet_agent_on(agent, opts)
    else
      opts.merge!({
        :dev_builds_url => ENV['AGENT_DOWNLOAD_URL'],
        :puppet_agent_sha => ENV['SHA']
      })
      # installs both development repo and agent package
      install_puppet_agent_dev_repo_on(agent, opts)
    end
  end
end

# make sure install is sane, beaker has already added puppet and ruby
# to PATH in ~/.ssh/environment
agents.each do |agent|
  on agent, puppet('--version')
  ruby = Puppet::Acceptance::CommandUtils.ruby_command(agent)
  on agent, "#{ruby} --version"
end

# Get a rough estimate of clock skew among hosts
times = []
hosts.each do |host|
  ruby = Puppet::Acceptance::CommandUtils.ruby_command(host)
  on(host, "#{ruby} -e 'puts Time.now.strftime(\"%Y-%m-%d %T.%L %z\")'") do |result|
    times << result.stdout.chomp
  end
end
times.map! do |time|
  (Time.strptime(time, "%Y-%m-%d %T.%L %z").to_f * 1000.0).to_i
end
diff = times.max - times.min
if diff < 60000
  logger.info "Host times vary #{diff} ms"
else
  logger.warn "Host times vary #{diff} ms, tests may fail"
end
