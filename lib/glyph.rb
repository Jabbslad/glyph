# Copyright (c) 2009-2010 Fabio Cevasco
# website: http://www.h3rald.com/glyph
# license: BSD

require 'rubygems'
require 'pathname'
require 'yaml'
require 'gli'
require 'extlib'
require 'treetop'
require 'rake'

# Glyph is a Rapid Document Authoring Framework able to produce structured documents 	effortlessly.
module Glyph

	LIB = Pathname(__FILE__).dirname.expand_path/'glyph'

	HOME = LIB/'../../'

	require LIB/'system_extensions'
	require LIB/'config'
	require LIB/'node'
	require LIB/'document'
	require LIB/'glyph_language'
	require LIB/'macro'
	require LIB/'interpreter'

	VERSION = file_load HOME/'VERSION'

	SPEC_DIR = Pathname(__FILE__).dirname.expand_path/'../spec'

	TASKS_DIR = Pathname(__FILE__).dirname.expand_path/'../tasks'

	APP = Rake.application

	SNIPPETS = {}

	MACROS = {}

	TODOS = []

	ERRORS = []

	# Returns true if Glyph is running in test mode
	def self.testing?
		const_defined? :TEST_MODE rescue false
	end

	PROJECT = (Glyph.testing?) ? Glyph::SPEC_DIR/"test_project" : Pathname.new(Dir.pwd)

	CONFIG = Glyph::Config.new :resettable => true, :mutable => false

	home_dir = Pathname.new(RUBY_PLATFORM.match(/win32|mingw/) ? ENV['HOMEPATH'] : ENV['HOME'])
	SYSTEM_CONFIG = Glyph::Config.new(:file => HOME/'config.yml')
	GLOBAL_CONFIG = Glyph.testing? ? Glyph::Config.new(:file => SPEC_DIR/'.glyphrc') : Glyph::Config.new(:file => home_dir/'.glyphrc')
	PROJECT_CONFIG = Glyph::Config.new(:file => PROJECT/'config.yml')

	# Loads all Rake tasks
	def self.setup
		FileList["#{TASKS_DIR}/**/*.rake"].each do |f|
			load f
		end	
	end

	# Overrides a configuration setting
	# @param setting [String, Symbol] the configuration setting to change
	# @param value the new value
	def self.config_override(setting, value)
		PROJECT_CONFIG.set setting, value
		reset_config
	end

	# Resets Glyph configuration
	def self.reset_config
		CONFIG.merge!(SYSTEM_CONFIG.merge(GLOBAL_CONFIG.merge(PROJECT_CONFIG)))
	end

	# Returns true if the PROJECT constant is set to a valid Glyph project directory
	def self.project?
		children = ["styles", "text", "output", "snippets.yml", "config.yml", "document.glyph"].sort
		actual_children = PROJECT.children.map{|c| c.basename.to_s}.sort 
		(actual_children & children) == children
	end

	# Enables a Rake task
	# @param task the task to enable
	def self.enable(task)
		Rake::Task[task].reenable
	end

	# Reenables and runs a Rake task
	# @param task the task to enable
	# @param *args the task arguments
	def self.run!(task, *args)
		Rake::Task[task].reenable
		self.run task, *args
	end

	# Runs a Rake task
	# @param task the task to enable
	# @param *args the task arguments
	def self.run(task, *args)
		Rake::Task[task].invoke *args
	end

	# Defines a new macro
	# @param name [Symbol, String] the name of the macro
	def self.macro(name, &block)
		MACROS[name.to_sym] = block
	end

	# Defines an alias for an existing macro
	# @param [Hash] pair the single-key hash defining the alias
	# @example
	# 	{:old_name => :new_name}
	def self.macro_alias(pair)
		name = pair.keys[0].to_sym
		found = MACROS[name]
		if found then
			warning "Invalid alias: macro '#{name}' already exists."
			return
		end
		MACROS[name] = MACROS[pair.values[0].to_sym]
	end
	
end

Glyph.setup
