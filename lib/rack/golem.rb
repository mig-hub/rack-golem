require 'tilt'

module Rack::Golem
  
  def self.included(klass)
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
    end
  end
  
  module ClassMethods
    attr_reader :before_block, :after_block
    def before(&block); @before_block = block; end
    def after(&block); @after_block = block; end
    def dispatcher(&block); @dispatcher_block = block; end
    def dispatcher_block
      @dispatcher_block || proc{
        @path_atoms = @r.path_info.split('/').find_all{|s| s!=''}
        @action, *@action_arguments = @path_atoms
        unless public_methods.include?(@action)||public_methods.include?((@action||'').to_sym)
          if public_methods.include?('index')||public_methods.include?(:index)
            @action, @action_arguments = 'index', @path_atoms
          else
            @action, @action_arguments = 'not_found', @path_atoms
          end
        end
        
        instance_eval(&self.class.before_block) unless self.class.before_block.nil?
        
        @res.write(self.__send__(@action,*@action_arguments))
        
        instance_eval(&self.class.after_block) unless self.class.after_block.nil?
      }
    end
  end
  
  module InstanceMethods
    def initialize(app=nil); @app = app; end
    def call(env); dup.call!(env); end
    def call!(env)
      @r = ::Rack::Request.new(env)
      @res = ::Rack::Response.new
      instance_eval(&self.class.dispatcher_block)
      @res.status==404&&!@app.nil? ? @app.call(env) : @res.finish
    end
    def not_found(*args)
      @res.status = 404
      @res.headers['X-Cascade']='pass'
      "Not Found: #{@r.path_info}"
    end
    def erb(template)
      @@tilt_cache ||= {}
      if @@tilt_cache.has_key?(template)
        template_obj = @@tilt_cache[template]
      else
        erb_extention = @r.env['erb.extention'] || ".erb"
        views_location = @r.env['erb.location'] || ::Dir.pwd+'/views/'
        views_location << '/' unless views_location[-1]==?/
        template_obj = Tilt.new("#{views_location}#{template}#{erb_extention}")
        @@tilt_cache.store(template,template_obj) if ENV['RACK_ENV']=='production'
      end
      template_obj.render(self)
    end
  end
  
end