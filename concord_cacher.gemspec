# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{concord_cacher}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Unger"]
  s.cert_chain = ["/Users/aunger/gem-public_cert.pem"]
  s.date = %q{2010-04-05}
  s.description = %q{concord_cacher provides support for locally caching a resource and all referenced resources in multiple different ways. It is intended for using with other Concord Consortium projects and not necessarily for outside projects.}
  s.email = %q{aunger @nospam@ concord.org}
  s.extra_rdoc_files = ["README.textile", "lib/concord_cacher.rb", "lib/concord/cacher.rb", "lib/concord/diy_local_cacher.rb", "lib/concord/java_proxy_cacher.rb"]
  s.files = ["README.textile", "Rakefile", "lib/concord_cacher.rb", "lib/concord/cacher.rb", "lib/concord/diy_local_cacher.rb", "lib/concord/java_proxy_cacher.rb", "spec/data/element_reference.otml", "spec/data/empty.otml", "spec/data/recursion.otml", "spec/data/resources/chart_line.png", "spec/data/resources/delete.png", "spec/data/resources/recurse1.otml", "spec/data/resources/recurse2.otml", "spec/data/resources/text.txt", "spec/data/standard_uri.otml", "spec/diy_local_cacher_spec.rb", "spec/helpers/cache_helper.rb", "spec/java_proxy_cacher_spec.rb", "Manifest", "concord_cacher.gemspec"]
  s.homepage = %q{http://github.com/psndcsrv/concord_cacher}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Concord_cacher", "--main", "README.textile"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{concord_cacher}
  s.rubygems_version = %q{1.3.6}
  s.signing_key = %q{/Users/aunger/gem-private_key.pem}
  s.summary = %q{Support for locally caching a resource and all referenced resources in multiple different ways}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
