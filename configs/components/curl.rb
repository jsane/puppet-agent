component 'curl' do |pkg, settings, platform|
  pkg.version '7.56.1'
  pkg.md5sum '48ba7bd7b363b40cd446d1e7b4be9920'
  pkg.url "https://curl.haxx.se/download/curl-#{pkg.get_version}.tar.gz"

  if settings[:vendor_openssl] == "no"
    pkg.build_requires 'openssl-devel'
  else
    pkg.build_requires 'openssl'
  end

  pkg.build_requires "puppet-ca-bundle"

  if platform.is_cross_compiled_linux?
    pkg.build_requires 'runtime'
    pkg.environment "PATH" => "/opt/pl-build-tools/bin:$$PATH:#{settings[:bindir]}"
    pkg.environment "PKG_CONFIG_PATH" => "/opt/puppetlabs/puppet/lib/pkgconfig"
    pkg.environment "PATH" => "/opt/pl-build-tools/bin:$$PATH"
  end

  if platform.is_windows?
    pkg.build_requires "runtime"

    pkg.environment "PATH" => "$$(cygpath -u #{settings[:gcc_bindir]}):$$PATH"
    pkg.environment "CYGWIN" => settings[:cygwin]
  end

  pkg.configure do
    ["CPPFLAGS='#{settings[:cppflags]}' \
      LDFLAGS='#{settings[:ldflags]}' \
     ./configure --prefix=#{settings[:prefix]} \
        --with-ssl=#{settings[:prefix]} \
        --enable-threaded-resolver \
        --disable-ldap \
        --disable-ldaps \
        --with-ca-bundle=#{settings[:prefix]}/ssl/cert.pem \
        #{settings[:host]}"]
  end

  pkg.build do
    ["#{platform[:make]} -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"]
  end

  pkg.install do
    ["#{platform[:make]} -j$(shell expr $(shell #{platform[:num_cores]}) + 1) install"]
  end
end
