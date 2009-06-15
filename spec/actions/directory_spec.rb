require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'thor/actions'

describe Thor::Actions::Directory do
  before(:each) do
    ::FileUtils.rm_rf(destination_root)
  end

  def directory(source, destination=nil, options={})
    @base = begin
      base = Object.new
      base.extend Thor::Actions
      stub(base).file_name{ "rdoc" }
      stub(base).source_root{ source_root }
      stub(base).destination_root{ destination_root }
      stub(base).relative_to_absolute_root{ |p| p.gsub(destination_root, '.')[2..-1] }
      stub(base).options{ options }
      stub(base).shell{ @shell = Thor::Shell::Basic.new }
      base
    end

    @action = Thor::Actions::Directory.new(base, source, destination || source)
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def valid?(content, path)
    %w(config.rb README).each do |file|
      source      = File.join(@action.source, file)
      relative    = File.join(@action.relative_destination, file)
      destination = File.join(destination_root, path, file)

      content.must =~ /^    \[CREATE\] #{relative}$/

      File.exists?(destination).must be_true
      FileUtils.identical?(source, destination).must be_true
    end
  end

  describe "#invoke!" do
    it "copies the whole directory to the default destination" do
      directory "doc"
      valid? invoke!, "doc"
    end

    it "copies the whole directory to the specified destination" do
      directory "doc", "docs"
      valid? invoke!, "docs"
    end

    it "copies and evaluate templates" do
      directory "doc", "docs"
      invoke!

      file = File.join(destination_root, "docs", "rdoc.rb")
      File.exists?(file).must be_true
      File.read(file).must == "FOO = FOO\n"
    end

    it "copies directories" do
      directory "doc", "docs"
      invoke!

      file = File.join(destination_root, "docs", "components")
      File.exists?(file).must be_true
      File.directory?(file).must be_true
    end

    it "does not copy .empty_diretories files" do
      directory "doc", "docs"
      invoke!

      file = File.join(destination_root, "docs", "components", ".empty_directory")
      File.exists?(file).must be_false
    end
  end

  describe "#revoke!" do
    it "removes the destination directory" do
      directory "doc"
      invoke!
      revoke!
      File.exists?(@action.destination).must be_false
    end
  end
end
