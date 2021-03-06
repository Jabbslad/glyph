#!/usr/bin/env ruby

namespace :project do

	desc "Create a new Glyph project"
	task :create, [:dir] do |t, args|
		dir = Pathname.new args[:dir]
		raise ArgumentError, "Directory #{dir} does not exist." unless dir.exist?
		raise ArgumentError, "Directory #{dir} is not empty." unless dir.children.blank?
		# Create subdirectories
		subdirs = ['lib/tasks', 'lib/macros', 'lib/macros/html', 'lib', 'text', 'output', 'images', 'styles']
		subdirs.each {|d| (dir/d).mkpath }
		# Create snippets
		yaml_dump Glyph::PROJECT/'snippets.yml', {:test => "This is a \nTest snippet"}
		# Create files
		file_copy Glyph::HOME/'document.glyph', Glyph::PROJECT/'document.glyph'
		file_copy Dir.glob(Glyph::HOME/'styles/*.css'), Glyph::PROJECT/'styles'
		config = yaml_load Glyph::HOME/'config.yml'
	 	config[:document][:filename] = dir.basename.to_s
		config[:document][:author] = ENV['USER'] || ENV['USERNAME'] 	
		yaml_dump Glyph::PROJECT/'config.yml', config
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
