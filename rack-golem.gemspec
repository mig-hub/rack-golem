Gem::Specification.new do |s| 
  s.name = 'rack-golem'
  s.version = "0.0.4"
  s.platform = Gem::Platform::RUBY
  s.summary = "A Controller middleware that is euh... basic"
  s.description = "A Controller middleware that is euh... basic. I would say it is a sort of Ramaze for kids"
  s.files = `git ls-files`.split("\n").sort
  s.require_path = './lib'
  s.author = "Mickael Riga"
  s.email = "mig@campbellhay.com"
  s.homepage = "http://www.campbellhay.com"
  s.add_dependency(%q<tilt>, [">= 1.2.2"])
  s.add_development_dependency(%q<bacon>, "~> 1.1.0")
end