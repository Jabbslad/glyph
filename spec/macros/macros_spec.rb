#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		create_project
		Glyph.run! 'load:macros'
		Glyph.run! 'load:snippets'
	end

	after do
		delete_project
	end

	it "anchor" do
		interpret "this is a #[test|test]."
		doc = @p.document
		doc.output.should == "this is a <a id=\"test\">test</a>."
		doc.bookmarks.has_key?(:test).should == true 
		lambda { interpret "this is a #[test|test]. #[test|This won't work!]"; @p.document }.should raise_error(MacroError)
	end

	it "snippet" do
		define_em_macro
		interpret "Testing a snippet: &[test]."
		@p.document.output.should == "Testing a snippet: This is a \nTest snippet."
		interpret("Testing &[wrong].")
		@p.document.output.should == "Testing [SNIPPET 'wrong' NOT PROCESSED]." 
		Glyph::SNIPPETS[:a] = "this is a em[test] &[b]"
		Glyph::SNIPPETS[:b] = "and another em[test]"
		text = "TEST: &[a]"
		interpret text
		@p.document.output.should == "TEST: this is a <em>test</em> and another <em>test</em>"
		# Check snippets with links
		Glyph::SNIPPETS[:c] = "This is a link to something afterwards: =>[#other]"
		text = "Test. &[c]. #[other|Test]."
		interpret text
		@p.document.output.should == %{Test. This is a link to something afterwards: <a href="#other">Test</a>. <a id="other">Test</a>.}
	end

	it "snippet:" do
		interpret("&[t1] - &:[t1|Test #1] - &[t1]")
		@p.document.output.should == "[SNIPPET 't1' NOT PROCESSED] -  - Test #1"
		Glyph::SNIPPETS[:t1].should == "Test #1"
		Glyph::SNIPPETS.delete :t1
	end

	it "condition" do
		define_em_macro
		interpret("?[$[document.invalid]|em[test]]")
		@p.document.output.should == ""
		interpret("?[$[document.output]|em[test]]")
		@p.document.output.should == "<em>test</em>"
		interpret("?[not[eq[$[document.output]|]]|em[test]]")
		@p.document.output.should == "<em>test</em>"
		interpret %{?[
				or[
					eq[$[document.target]|htmls]|
					not[eq[$[document.author]|x]]
				]|em[test]]}
		@p.document.output.should == "<em>test</em>"
		interpret("?[not[match[$[document.source]|/^docu/]]|em[test]]")
		@p.document.output.should == ""
		# Invalid regexp
		lambda { interpret("?[match[$[document.source]|document]em[test]]").document.output }.should raise_error
		# Outside condition
		lambda { interpret("em[and[a|b]]").document.output }.should raise_error

	end

	it "section, chapter, header" do
		text = "chapter[header[Chapter X] ... section[header[Section Y|sec-y] ... section[header[Another section] ...]]]"
		interpret text
		doc = @p.document
		doc.output.gsub(/\n|\t/, '').should == %{<div class="chapter">
					<h2 id="h_1">Chapter X</h2> ... 
					<div class="section">
					<h3 id="sec-y">Section Y</h3> ... 
						<div class="section">
						<h4 id="h_3">Another section</h4> ...
						</div>
					</div>
				</div>
		}.gsub(/\n|\t/, '')
		doc.bookmark?(:"sec-y").should == {:id => :"sec-y", :title => "Section Y"} 
	end

	it "include" do
		Glyph.config_override "filters.by_extension", true
		text = file_load(Glyph::PROJECT/'text/container.textile')
		interpret text
		@p.document.output.gsub(/\n|\t|_\d{1,3}/, '').should == %{
			<div class="section">
			<h2 id="h_1">Container section</h2>
			This is a test.
				<div class="section">
				<h3 id="h_2">Test Section</h3>	
				<p>&#8230;</p>
				</div>
			</div>
		}.gsub(/\n|\t|_\d{1,3}/, '')
	end


	it "style" do
		interpret "style[test.sass]"
		@p.document.output.gsub(/\n|\t/, '').should == "<style type=\"text/css\">#main {  background-color: #0000ff; }</style>"
	end	

	it "escape" do
		define_em_macro
		text = %{This is a test em[This can .[=contain test[macros em[test]]=]]}		
		interpret text
		@p.document.output.should == %{This is a test <em>This can contain test[macros em[test]]</em>}
	end

	it "ruby" do
		interpret "2 + 2 = %[2+2]"
		@p.document.output.should == %{2 + 2 = 4}
	end

	it "config" do
		Glyph.config_override "test.setting", "TEST"
		interpret "test.setting = $[test.setting]"
		@p.document.output.should == %{test.setting = TEST}
	end
	
	it "config:" do
		Glyph.config_override "test.setting", "TEST"
		interpret "test.setting = $[test.setting]"
		@p.document.output.should == %{test.setting = TEST}
		interpret "test.setting = $:[test.setting|TEST2]$[test.setting]"
		@p.document.output.should == %{test.setting = TEST2}
	end

	it "toc" do
		file_copy Glyph::PROJECT/'../files/document_with_toc.glyph', Glyph::PROJECT/'document.glyph'
		interpret file_load(Glyph::PROJECT/'document.glyph')
		doc = @p.document
		doc.output.gsub!(/\n|\t/, '')
		doc.output.slice(/(.+?<\/div>)/, 1).should == %{
			<div class="contents">
			<h2 class="toc-header" id="h_toc">Table of Contents</h2>
			<ol class="toc">
				<li class=" section"><a href="#h_1">Container section</a></li>
				<li><ol>
					<li class=" section"><a href="#h_2">Test Section</a></li>
				</ol></li>
				<li class=" section"><a href="#md">Markdown</a></li>
			</ol>
			</div>
		}.gsub(/\n|\t/, '')
	end

	it "link" do
		text = %{
			link[#test_id]
			link[#test_id2]
			#[test_id|Test #1]
			#[test_id2|Test #2]
		}
		interpret text
		@p.document.output.gsub(/\n|\t/, '').should == %{
			<a href="#test_id">Test #1</a>
			<a href="#test_id2">Test #2</a>
			<a id="test_id">Test #1</a>
			<a id="test_id2">Test #2</a>
		}.gsub(/\n|\t/, '')
	end

	it "fmi" do
		interpret "fmi[this topic|#test] #[test|Test]"
		@p.document.output.should == %{<span class="fmi">
			for more information on this topic, 
			see <a href="#test">Test</a></span> <a id="test">Test</a>}.gsub(/\n|\t/, '')
	end	

	it "img" do
		interpret "img[ligature.jpg|90%|90%]"
		@p.document.output.gsub(/\t|\n/, '').should == %{
			<img src="images/ligature.jpg" 
			width="90%" height="90%" alt="-"/>
		}.gsub(/\n|\t/, '')
	end

	it "fig" do
		interpret "fig[ligature.jpg|Ligature]"
		@p.document.output.gsub(/\t|\n/, '').should == %{
			<div class="figure">
			<img src="images/ligature.jpg" alt="-"/>
			<div class="caption">Ligature</div>
			</div>
		}.gsub(/\n|\t/, '')
	end

end	
