require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'leftright'
require 'rr'

# StaleFish style libs required
require 'sha1'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'git_pivot'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  def fixture_stub(object, method, *args)
    # setup directories if they don't exist
    fixtures_dir = "test/fixtures/fixture_stubs"
    object_dir = "#{fixtures_dir}/#{object.class.to_s.sub('::', '__')}"
    method_dir = "#{object_dir}/#{method.to_s}"

    check_directory(fixtures_dir)
    check_directory(object_dir)
    check_directory(method_dir)

    args_string = Digest::SHA1.hexdigest(YAML::dump(args))
    fixture_file = "#{method_dir}/#{args_string}"
    # load stub if recent enough
    if File.exist?(fixture_file) and fixture_current(fixture_file)
      marshal_data = nil
      File.open(fixture_file) {|file| marshal_data = Marshal.load(file) }
      stub(object).__send__(method, *args)  { marshal_data }
    else
      marshal_data = object.send(method, *args)
      File.open(fixture_file, 'w') {|file| Marshal.dump(marshal_data, file) }
      stub(object).__send__(method, *args)  { marshal_data }
    end
  end

  private
  def check_directory(directory)
    unless File.directory?(directory)
      FileUtils.mkdir(directory)
    end
  end

  def fixture_current(fixture_file)
    fixture_time = nil
    File.open(fixture_file) do |file|
      fixture_time = file.mtime
    end

    # 10 day count
    Time.now - fixture_time < 60 * 60 * 24 * 10
  end
end
