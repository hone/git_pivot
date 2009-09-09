=begin
  Copyright (c) 2009 Terence Lee.

  This file is part of GitPivot

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'trollop'
require 'date'

module GitPivot
  class Runner
    SUB_COMMANDS = %w{current work display start finish note stack push tasks task complete}
    STATE_FILE = "git_pivot.state"
    
    def initialize(args)
      @method, @cmd, @cmd_opts = process_args(args)

      # configuration stuff
      configuration = YAML.load_file("git_pivot.yml")
      if File.exist?(STATE_FILE)
        File.open(STATE_FILE) do |file|
          @states = Marshal.load(file)
          if @states.is_a?(Array)
            @states.uniq!
          else
            @states = nil
          end
        end
      end

      @git_pivot = GitPivot.new(configuration["project_id"], configuration["token"], configuration["owner"])
    end

    def run
      args = [@method]
      if @method and @git_pivot.method(@method).arity > 0
        if @cmd_opts[:id]
          args << @cmd_opts[:id]
        elsif @states.any?
          args << @states.first
        else
          Trollop::die "Need to specify a story id"
        end

        if @cmd_opts[:text]
          args << @cmd_opts[:text].join(' ')
        end
        if @cmd_opts[:"task-id"]
          args << @cmd_opts[:"task-id"]
        end
      end

      if @method == :start_story
        add_story_to_states(@cmd_opts[:id])
      end

      if @method
        @git_pivot.send(*args)
      end

      # must do this after, in case finish fails, don't want to pop
      if @method == :finish_story
        if @states and @states.first == args[1]
          @states.shift

          save_state
        end
      end

      case @cmd
      when "stack"
        puts @states
      when "push"
        add_story_to_states(@cmd_opts[:id])
        puts @states
      end
    end

    private
    def save_state
      File.open(STATE_FILE, 'w') {|file| Marshal.dump(@states, file) }
    end

    def add_story_to_states(story_id)
      if @states.nil?
        @states = [story_id]
      else
        @states.delete(story_id)
        @states.unshift(story_id)
      end

      save_state
    end

    def process_args(args)
      global_opts = Trollop::options do
        banner <<-BANNER
A command-line interface for Pivotal Tracker.

Subcommands:
  current  - Lists the stories that are part of the current iteration.
  work     - Lists the stories that you own.
  display  - Displays information about a specific story.
  start    - Marks a story as started.
  finish   - Marks a story as finished.
  note     - Add a new note to an existing story
  stack    - Current Stack of Story ids
  push     - Push a story to the top of the Story Stack
  tasks    - Display tasks associated to a story
  task     - Add a task to the given story
  complete - Mark a task as completed
  
BANNER
        stop_on SUB_COMMANDS
      end

      command = nil
      cmd = args.shift
      cmd_opts = case cmd
        when "current"
          command = :current_sprint
        
          Trollop::options(args) do
            banner "Lists the stories that are part of the current iteration."
          end
        when "work"
          command = :my_work
        
          # FIXME: This help message doesn't appear with a 'git_pivot work -h', but the 'git_pivot current -h' message does.
          Trollop::options(args) do
            banner "Lists the stories that you own."
          end
        when "display"
          command = :display_story
        
          Trollop::options(args) do
            banner "Display information about a specific story."
        
            opt :id, "The id of the story to display.", :type => Integer
          end
        when "start"
          command = :start_story
        
          Trollop::options(args) do
            banner "Marks a specific story as started."
        
            opt :id, "The id of the story to start.", :required => true, :type => Integer
          end
        when "finish"
          command = :finish_story
        
          Trollop::options(args) do
            banner "Marks a specific story as finished."
        
            opt :id, "The id of the story to finish.", :type => Integer
          end
        when "note"
          command = :add_note

          Trollop::options(args) do
            banner "Adds a note to the story."

            opt :id, "The id of the story to finish.", :type => Integer
            opt :text, "The text of the note.", :required => true, :type => :strings
          end
        when "stack"
          command = nil

          Trollop::options(args) do
            banner "Displays the stack of story ids."
          end
        when "push"
          command = nil

          Trollop::options(args) do
            banner "Push story to the top of the story stack."
            
            opt :id, "The id of the story.", :type => Integer
          end
        when "tasks"
          command = :tasks

          Trollop::options(args) do
            banner "Tasks for a given story."

            opt :id, "The id of the story.", :type => Integer
          end
        when "task"
          command = :add_task

          Trollop::options(args) do
            banner "Add a task to the story."

            opt :id, "The id of the story.", :type => Integer
            opt :text, "The text of the task.", :required => true, :type => :strings
          end
        when "complete"
          command = :complete_task

          Trollop::options(args) do
            banner "Complete a task"

            opt :id, "The id of the story.", :type => Integer
            opt :"task-id", "The id of the task.", :required => true, :type => Integer
          end
        else
          Trollop::die "unknown subcommand #{cmd.inspect}"
        end

      [command, cmd, cmd_opts]
    end
  end
end
