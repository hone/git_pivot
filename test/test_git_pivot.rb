require 'helper'

class TestGitPivot < Test::Unit::TestCase
  TOKEN = 'ec28ee20681177c44a9edfa667fdb1b2'
  OWNER = 'Terence Lee'
  PROJECT_ID = '25792'
  
  def setup
    @git_pivot = GitPivot::GitPivot.new(PROJECT_ID, TOKEN, OWNER, false, true)
  end

  context "current_sprint" do
    setup do
      fixture_stub(@git_pivot, :current_sprint)
    end

    should "return the current iteration" do
      assert @git_pivot.current_sprint.is_a?(Iteration)
    end


    should "have the stories in the current iteration" do
      story_names = [
        "current sprint",
        "finish story"
      ]

      story_names.each do |story_name|
        assert @git_pivot.current_sprint.stories.find {|story| story.name == story_name }
      end
    end # should

  end # context

  context "my_work" do
    setup do
      fixture_stub(@git_pivot, :my_work)
    end

    should "return a list of stories" do
      @git_pivot.my_work.each do |story|
        assert story.is_a?(Story), "story: #{story.inspect} is not a story"
      end
    end

    should "have stories owned by the user" do
      @git_pivot.my_work.each do |story|
        assert_equal(story.owned_by, OWNER)
      end
    end

    should "have stories from the current sprint" do
    end

    should "have stories from the backlog" do
    end

    should "have stories from the icebox" do
    end

    should "only have done stories from the current sprint" do
    end
  end # context

end # class
