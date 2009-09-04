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
    SUB_COMMANDS = %w{current work display start finish note stack}
    STATE_FILE = "git_pivot.state"
    
    def initialize(args)
      @cmd, @cmd_opts = process_args(args)

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
      args = [@cmd]
      if @cmd and @git_pivot.method(@cmd).arity > 0
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
      end

      if @cmd == :start_story
        if @states.nil?
          @states = [@cmd_opts[:id]]
        else
          @states.delete(@cmd_opts[:id])
          @states.unshift(@cmd_opts[:id])
        end

        File.open(STATE_FILE, 'w') {|file| Marshal.dump(@states, file) }
      end

      if @cmd
        @git_pivot.send(*args)
      else
        puts @states
      end
    end

    private
    def process_args(args)
      global_opts = Trollop::options do
        banner <<-BANNER
A command-line interface for Pivotal Tracker.

Subcommands:
  current - Lists the stories that are part of the current iteration.
  work    - Lists the stories that you own.
  display - Displays information about a specific story.
  start   - Marks a story as started.
  finish  - Marks a story as finished.
  note    - Add a new note to an existing story
  stack   - Current Stack of Story ids
  
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
        else
          Trollop::die "unknown subcommand #{cmd.inspect}"
        end

      [command, cmd_opts]
    end
  end
end
