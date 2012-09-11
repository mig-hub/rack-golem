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
  def test_throw
    throw :response, [200,{'Content-Type'=>'text/html'},['Growl']]
    'Grrr'
  end
  def best_restaurants_rss; '<xml>test</xml>'; end
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

# ==================
# = Simply indexed =
# ==================

class SimplyIndexed
  include Rack::Golem
  def index; 'index'; end
  def will_fail; please_fail; end
  private
  def please_fail(num); 'ArgumentError baby'; end
end
SimplyIndexedR = ::Rack::MockRequest.new(::Rack::Lint.new(SimplyIndexed.new))
SimplyIndexedUsedR = ::Rack::MockRequest.new(::Rack::Lint.new(SimplyIndexed.new(lambda{|env| [200,{},"#{3+nil}"]})))

# =============
# = Sessioned =
# =============

class Sessioned
  include Rack::Golem
  def set_val(val); @session[:val] = val; end
  def get_val; @session[:val]; end
end
SessionedR = ::Rack::MockRequest.new(::Rack::Session::Cookie.new(::Rack::Lint.new(Sessioned.new)))

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
    r.body.should=='NOT FOUND: /no_way'
    r = BasicR.get('/no')
    r.status.should==404
    r.body.should=='NOT FOUND: /no'
  end
  
  it "Should dispatch to appropriate underscored action when name contains '-' or '.'" do
    BasicR.get('/best-restaurants.rss').body.should=='<xml>test</xml>'
  end
  
  it "Should only apply '-' and '.' substitution on action names" do
    IndexedR.get('/best-restaurants.rss').body.should=='best-restaurants.rss'
  end
  
  it "Should follow the rack stack if response is 404 and there are middlewares below" do
    r = BasicLobsterR.get("/no_way")
    r.status.should==200
  end
  
  it "Should provide filters" do
    FilterR.get('/wrapped').body.should=="before+wrapped+after"
  end
  
  it "Should provide arguments in filter when page is not_found" do
    FilterR.get('/a/b/c/d').body.should=="a+b+c+dNOT FOUND: /a/b/c/d+after"
  end
  
  it "Should send everything to :index if it exists and there is no matching method for first arg" do
    IndexedR.get('/exist/a/b/c/d').body.should=='a+b+c+d'
    IndexedR.get('/a/b/c/d').body.should=='a+b+c+d'
    IndexedR.get('/').body.should==''
  end
  
  it "Should send not_found if there is an argument error on handlers" do
    SimplyIndexedR.get('/').status.should==200
    SimplyIndexedR.get('/unknown').status.should==404
    SimplyIndexedR.get('/will_fail/useless').status.should==404
    lambda{ SimplyIndexedR.get('/will_fail') }.should.raise(ArgumentError)
  end
  
  it "Should handle errors without raising an exception unless in dev mode" do
    lambda{ SimplyIndexedR.get('/will_fail') }.should.raise(ArgumentError)
    ENV['RACK_ENV'] = 'development'
    lambda{ SimplyIndexedR.get('/will_fail') }.should.raise(ArgumentError)
    ENV['RACK_ENV'] = 'production'
    @old_stdout = $stdout
    $stdout = StringIO.new
    res = SimplyIndexedR.get('/will_fail')
    logged = $stdout.dup
    $stdout = @old_stdout
    res.status.should==500
    logged.string.should.match(/ArgumentError/)
    ENV['RACK_ENV'] = nil
  end
  
  it "Should not use the error handler if the error occur further down the rack stack" do
    ENV['RACK_ENV'] = 'production'
    lambda{ SimplyIndexedUsedR.get('/not_found') }.should.raise(TypeError)
    ENV['RACK_ENV'] = nil
  end
  
  it "Should set dispatch-specific variables correctly when defaulting to :index" do
    IndexedR.get('/a/b/c/d?switch=true').body.should=="action=index args=a,b,c,d a+b+c+d"
  end
  
  it "Should have a shortcut for session hash" do
    res = SessionedR.get('/set_val/ichigo')
    res_2 = SessionedR.get('/get_val', 'HTTP_COOKIE'=>res["Set-Cookie"])
    res_2.body.should=='ichigo'
  end
  
  it "Should catch :response if needed" do
    BasicR.get('/test_throw').body.should=='Growl'
  end
  
end