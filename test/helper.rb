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
    fixtures_dir = fixture_stub_dir
    object_dir = "#{fixtures_dir}/#{object.class.to_s.sub('::', '__')}"
    method_dir = "#{object_dir}/#{method.to_s}"

    check_directory(fixtures_dir)
    check_directory(object_dir)
    check_directory(method_dir)

    args_string = Digest::SHA1.hexdigest(YAML::dump(args))
    timestamp_file = "#{fixtures_dir}/timestamp"
    fixture_file = "#{method_dir}/#{args_string}"
    current = fixtures_current
    # load stub if recent enough
    if File.exist?(fixture_file) and current
      marshal_data = nil
      File.open(fixture_file) {|file| marshal_data = Marshal.load(file) }
      stub(object).__send__(method, *args)  { marshal_data }
    else
      marshal_data = object.send(method, *args)
      File.open(fixture_file, 'w') {|file| Marshal.dump(marshal_data, file) }
      stub(object).__send__(method, *args)  { marshal_data }
    end
  end

  def fixture_stub_dir
    "test/fixtures/fixture_stubs"
  end

  def fixture_stub_timestamp
    fixture_stub_dir + "/timestamp"
  end

  def tracker_setup(tracker)
    fixtures_directory = "test/fixtures/tracker"
    check_directory(fixtures_directory)
    current_stories_yml = "#{fixtures_directory}/current_stories.yml"
    files = Dir["#{fixtures_directory}/*"]
    files -= [ current_stories_yml ]
    files.unshift(current_stories_yml)
    files.each do |f|
      fixture = YAML.load_file(f)
      fixture.each do |fixture_name, story_hash|
        tracker.create_story(Story.new(story_hash))
      end
    end
  end

  def tracker_teardown(tracker)
    tracker.stories.each do |story|
      tracker.delete_story(story)
    end
  end

  def fixtures_current
    check_directory(fixture_stub_dir)

    # 10 day count
    if File.exist?(fixture_stub_timestamp) and Time.now - File.ctime(fixture_stub_timestamp) < 60 * 60 * 24 * 10
      true
    else
      FileUtils.touch(fixture_stub_timestamp)

      false
    end
  end

  private
  def check_directory(directory)
    unless File.directory?(directory)
      FileUtils.mkdir(directory)
    end
  end
end
