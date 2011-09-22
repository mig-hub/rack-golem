>Made of consonants and vowels,  
>there is a terrible Name,  
>that in its essence encodes God’s all,  
>power, guarded in letters, in hidden syllables.  -- Jorge Luis Borges

GOLEM
=====

I would describe Golem as a Ramaze for kids.  
Golem is not a framework though, just a controller, but you know... the kind of controller that leaves you in the train even if you
did not by a ticket. It leaves you on the rails if you will (incredibly good pun intended).

Install with:

  sudo gem install rack-golem

Config.ru is one of his names, so say it in a Rackup file.

  require 'db' # Loads ORM models and all
  require 'go' # Our controller (I don not like that word really)
  use Rack::ContentLength
  use Rack::Session::Cookies
  run Go

And the winner is:

  require 'rack/golem'

  class Go
    include Rack::Golem # To hell with sub-classes !!!

    before do
      # Here you can do many things
      # In order to help you here are some variables you can read and override:
      # @r => the Rack::Request object
      # @res => the Rack::Response object
      # @action => Name of the public method that will handle the request
      # @action_arguments => Arguments for the action (really?)
    end

    def index(*args)
      # When no public method is found
      # Of course you don't have to declare one and it is gonna use Controller#not_found instead
      # But if it is declared, keep in mind it's a catch-all so make it deal with args
      @articles = Post.all
      erb :index
    end

    def post(id=nil)
      @post = Post[id]
      if @post.nil?
        not_found
      else
        erb :post
      end
    end

    def say(listener='me', *words)
      "Hey #{listener} I don't need ERB to tell you that #{words.join(' ')}"
    end

    def not_found(*args)
      # This one is defined by Golem but here we decided to override it
      # Like `:index` this method receives the arguments in order to make something with it
      Email.alert('Too many people are looking for porn here') if args.includes?("porn")
      super(args)
    end

    after do
      Spy.analyse.send_info_to([:government, :facebook, :google, :james_bond])
    end

  end

Hopefully no headache.

WHAT GOLEM DOES NOT
===================

- Support templates other than ERB (I plan to use Tilt more cleverly though in order to achieve that without selling my soul)
- Session/Cookies administration (Like for many things, use a middleware instead ex: Rack::Session::Cookies)
- Prepare the coffee (Emacs does but Ed is the standard text editor)
- So many things, why bother...