#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Macro do

	before do
		Glyph.macro :test do
			"Test: #{@value}"
		end
		Glyph.macro :validated_test do
			validate {	@node.parent[:macro] == :test }
			"Validated Test: #{@value}"
		end
		create_tree = lambda {|text| }
		create_doc = lambda {|tree| }
		@text = "test[section[header[Test!|test]]]"
		@tree = create_tree @text 
		@doc = create_doc @tree
		@node = {:macro => :test, :value => "Testing...", :source => "--", :document => @doc}.to_node
		@macro = Glyph::Macro.new @node
	end

	it "should raise macro errors" do
		lambda { @macro.macro_error "Error!" }.should raise_error(MacroError)
		
	end

	it "should interpret strings" do
		@macro.interpret("test[--]").should == "Test: --"
	end

	it "should store and check bookmarks" do
		h = { :id => "test2", :title => "Test 2" }
		@macro.bookmark h
		@doc.bookmark?(:test2).should == h
		@macro.bookmark?(:test2).should == h
	end

	it "should store and check headers" do
		h = { :level => 2, :id => "test3", :title => "Test 3" }
		@macro.header h
		@doc.header?("test3").should == h
		@macro.header?("test3").should == h
	end

	it "should store placeholders" do
		@macro.placeholder { |document| }
		@doc.placeholders.length.should == 1
	end

	it "should execute" do
		@macro.execute.should == "Test: Testing..."
	end

	it "should detect mutual inclusion" do
		delete_project
		create_project
		Glyph.run! 'load:macros'
		Glyph::SNIPPETS[:inc] = "Test &[inc]"
		@macro.interpret("&[inc] test").should == "Test [SNIPPET 'inc' NOT PROCESSED] test" 
	end

	it "should be validated" do
		lambda { interpret("test[section[validated_test[invalid]]]").document.output }.should raise_error
		interpret("test[validated_test[valid]]").document.output.should == "Test: Validated Test: valid" 
	end

end

