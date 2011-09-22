require 'rubygems'
require 'bacon'
require 'rack'
require 'rack/lobster'
require 'fileutils' # fix Rack missing

Bacon.summary_on_exit

# Helpers
F = ::File
D = ::Dir
ROOT = F.dirname(__FILE__)+'/..'
$:.unshift ROOT+'/lib'
require 'rack/golem'

# =========
# = Basic =
# =========

class Basic
  include Rack::Golem
  def no_arg; 'nothing'; end  
  def with_args(a,b); '%s+%s' % [a,b]; end 
  def splat_arg(*a); a.join('+'); end
  private
  def no_way; 'This is private'; end
end
BasicR = ::Rack::MockRequest.new(::Rack::Lint.new(Basic.new))
BasicLobsterR = ::Rack::MockRequest.new(::Rack::Lint.new(Basic.new(::Rack::Lobster.new)))

# ==========
# = Filter =
# ==========

class Filter
  include Rack::Golem
  before{@res.write @action=='not_found' ? @action_arguments.join('+') : 'before+'}
  after{@res.write '+after'}
  def wrapped; 'wrapped'; end
end
FilterR = ::Rack::MockRequest.new(::Rack::Lint.new(Filter.new))

# ===========
# = Indexed =
# ===========

class Indexed
  include Rack::Golem
  before{ @res.write("action=#{@action} args=#{@action_arguments.join(',')} ") if @r['switch']=='true' }
  def index(*a); a.join('+'); end
  def exist(*a); a.join('+'); end
end
IndexedR = ::Rack::MockRequest.new(::Rack::Lint.new(Indexed.new))

# =========
# = Specs =
# =========

describe "Golem" do
  it "Should dispatch on a method with no arguments" do
    BasicR.get('/no_arg').body.should=='nothing'
  end
  it "Should dispatch on a method with arguments" do
    BasicR.get('/with_args/a/b').body.should=='a+b'
  end
  it "Should dispatch on a method with splat argument" do
    BasicR.get('/splat_arg/a/b/c/d').body.should=='a+b+c+d'
  end
  it "Should not dispatch if the method is private or does not exist" do
    r = BasicR.get('/no_way')
    r.status.should==404
    r.body.should=='Not Found: /no_way'
    r = BasicR.get('/no')
    r.status.should==404
    r.body.should=='Not Found: /no'
  end
  it "Should follow the rack stack if response is 404 and there are middlewares below" do
    r = BasicLobsterR.get("/no_way")
    r.status.should==200
  end
  it "Should provide filters" do
    FilterR.get('/wrapped').body.should=="before+wrapped+after"
  end
  it "Should provide arguments in filter when page is not_found" do
    FilterR.get('/a/b/c/d').body.should=="a+b+c+dNot Found: /a/b/c/d+after"
  end
  it "Should send everything to :index if it exists and there is no matching method for first arg" do
    IndexedR.get('/exist/a/b/c/d').body.should=='a+b+c+d'
    Indexed.new.public_methods.include?(:index)
    IndexedR.get('/a/b/c/d').body.should=='a+b+c+d'
  end
  it "Should set dispatch-specific variables correctly when defaulting to :index" do
    IndexedR.get('/a/b/c/d?switch=true').body.should=="action=index args=a,b,c,d a+b+c+d"
  end
end