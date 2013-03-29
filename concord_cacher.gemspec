# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{concord_cacher}
  s.version = "0.1.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '~> 1.8.7'
  s.authors = ["Aaron Unger"]
  s.date = %q{2013-03-28}
  s.description = %q{concord_cacher provides support for locally caching a resource and all referenced resources in multiple different ways. It is intended for using with other Concord Consortium projects and not necessarily for outside projects.}
  s.email = %q{aunger @nospam@ concord.org}
  s.extra_rdoc_files = ["README.textile", "lib/concord/cacher.rb", "lib/concord/diy_local_cacher.rb", "lib/concord/filename_generators.rb", "lib/concord/filename_generators/default_generator.rb", "lib/concord/filename_generators/diy_generator.rb", "lib/concord/filename_generators/java_proxy_generator.rb", "lib/concord/helper.rb", "lib/concord/java_proxy_cacher.rb", "lib/concord/resource.rb", "lib/concord_cacher.rb"]
  s.files = ["Manifest", "README.textile", "Rakefile", "concord_cacher.gemspec", "lib/concord/cacher.rb", "lib/concord/diy_local_cacher.rb", "lib/concord/filename_generators.rb", "lib/concord/filename_generators/default_generator.rb", "lib/concord/filename_generators/diy_generator.rb", "lib/concord/filename_generators/java_proxy_generator.rb", "lib/concord/helper.rb", "lib/concord/java_proxy_cacher.rb", "lib/concord/resource.rb", "lib/concord_cacher.rb", "spec/data/always_skip.otml", "spec/data/bad_url.otml", "spec/data/codebase.otml", "spec/data/element_reference.otml", "spec/data/empty.otml", "spec/data/empty_url.otml", "spec/data/mw_model_absolute.otml", "spec/data/mw_model_relative.otml", "spec/data/nlogo_absolute.otml", "spec/data/nlogo_relative.otml", "spec/data/recursion.otml", "spec/data/recursive_loop.otml", "spec/data/resources/chart_line.png", "spec/data/resources/delete.png", "spec/data/resources/loop1.otml", "spec/data/resources/loop2.otml", "spec/data/resources/nlogo/SpaceRescue.Practice1.nlogo", "spec/data/resources/recurse1.otml", "spec/data/resources/recurse2.otml", "spec/data/resources/statesofmatter/bench.gif", "spec/data/resources/statesofmatter/downHighlightMol1.gif", "spec/data/resources/statesofmatter/downHighlightMol2.gif", "spec/data/resources/statesofmatter/eightBall.gif", "spec/data/resources/statesofmatter/eightBall.html", "spec/data/resources/statesofmatter/eightBall.mml", "spec/data/resources/statesofmatter/eightBallZoom.gif", "spec/data/resources/statesofmatter/gold.gif", "spec/data/resources/statesofmatter/gold.html", "spec/data/resources/statesofmatter/gold.mml", "spec/data/resources/statesofmatter/goldZoom.gif", "spec/data/resources/statesofmatter/helium.gif", "spec/data/resources/statesofmatter/helium.html", "spec/data/resources/statesofmatter/helium.mml", "spec/data/resources/statesofmatter/heliumZoom.gif", "spec/data/resources/statesofmatter/hydrogen.gif", "spec/data/resources/statesofmatter/hydrogen.html", "spec/data/resources/statesofmatter/hydrogen.mml", "spec/data/resources/statesofmatter/hydrogenZoom.gif", "spec/data/resources/statesofmatter/rootBeer.gif", "spec/data/resources/statesofmatter/rootBeer.html", "spec/data/resources/statesofmatter/rootBeer.mml", "spec/data/resources/statesofmatter/rootBeerZoom.gif", "spec/data/resources/statesofmatter/statesOfMatter$0.mml", "spec/data/resources/statesofmatter/statesOfMatter.cml", "spec/data/resources/statesofmatter/statesOfMatterPage1$0.mml", "spec/data/resources/statesofmatter/statesOfMatterPage1.cml", "spec/data/resources/statesofmatter/unknown.gif", "spec/data/resources/statesofmatter/unknown.html", "spec/data/resources/statesofmatter/unknown.mml", "spec/data/resources/statesofmatter/unknownZoom.gif", "spec/data/resources/statesofmatter/upHighlightMol1.gif", "spec/data/resources/statesofmatter/upHighlightMol2.gif", "spec/data/resources/statesofmatter/water.gif", "spec/data/resources/statesofmatter/water.html", "spec/data/resources/statesofmatter/water.mml", "spec/data/resources/statesofmatter/waterZoom.gif", "spec/data/resources/text.txt", "spec/data/standard_uri.otml", "spec/data/url_with_space.otml", "spec/data/xml_entities.otml", "spec/diy_local_cacher_spec.rb", "spec/helpers/cache_helper.rb", "spec/java_proxy_cacher_spec.rb", "xml_entities.otml", "spec/data/urls_in_resourcelist.otml"]
  s.homepage = %q{http://github.com/concord-consortium/concord_cacher}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Concord_cacher", "--main", "README.textile"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{concord_cacher}
  s.rubygems_version = %q{1.3.6}
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
