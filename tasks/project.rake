#!/usr/bin/env ruby

namespace :project do

	desc "Create a new Glyph project"
	task :create, [:dir] do |t, args|
		dir = Pathname.new args[:dir]
		raise ArgumentError, "Directory #{dir} does not exist." unless dir.exist?
		raise ArgumentError, "Directory #{dir} is not empty." unless dir.children.blank?
		# Create subdirectories
		subdirs = ['lib/tasks', 'lib', 'text', 'output', 'assets', 'layouts', 'styles']
		subdirs.each {|d| (dir/d).mkpath }
		file_copy Glyph::LIB_DIR/'macros_html.rb', Glyph::PROJECT/'lib/macros_html.rb'
		# Create snippets
		yaml_dump Glyph::PROJECT/'snippets.yml', {:test => "This is a \nTest snippet"}
		# Create files
		# TODO
		info "Project '#{dir.basename}' created successfully."
	end

	desc "Add a new text file to the project"
	task :add, [:file] do |t, args|
		Glyph.enable 'project:add'
		file = Glyph::PROJECT/"text/#{args[:file]}" 
		file.parent.mkpath
		raise ArgumentError, "File '#{args[:file]}' already exists." if file.exist?
		File.new(file.to_s, "w").close
	end

end