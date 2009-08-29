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
    SUB_COMMANDS = %w{current work display start finish}
    
    def initialize(args)
      @argv = args

      # configuration stuff
      configuration = YAML.load_file("git_pivot.yml")

      @git_pivot = GitPivot.new(configuration["project_id"], configuration["token"], configuration["owner"])
    end

    def run
      global_opts = Trollop::options do
        banner <<-BANNER
A command-line interface for Pivotal Tracker.

Subcommands:
  current - Lists the stories that are part of the current iteration.
  work    - Lists the stories that you own.
  display - Displays information about a specific story.
  start   - Marks a story as started.
  finish  - Marks a story as finished.
  
BANNER
        stop_on SUB_COMMANDS
      end
      
      cmd = @argv.shift
      cmd_opts = case cmd
        when "current"
          command = :current_sprint
        
          Trollop::options do
            banner "Lists the stories that are part of the current iteration."
          end
        when "work"
          command = :my_work
        
          # FIXME: This help message doesn't appear with a 'git_pivot work -h', but the 'git_pivot current -h' message does.
          Trollop::options do
            banner "Lists the stories that you own."
          end
        when "display"
          command = :display_story
        
          Trollop::options do
            banner "Display information about a specific story."
        
            opt :id, "The id of the story to display.", :required => true, :type => Integer
          end
        when "start"
          command = :start_story
        
          Trollop::options do
            banner "Marks a specific story as started."
        
            opt :id, "The id of the story to start.", :required => true, :type => Integer
          end
        when "finish"
          command = :finish_story
        
          Trollop::options do
            banner "Marks a specific story as finished."
        
            opt :id, "The id of the story to finish.", :required => true, :type => Integer
          end
        else
          Trollop::die "unknown subcommand #{cmd.inspect}"
        end
      
      args = cmd_opts[:id] ? [command, cmd_opts[:id]] : [command]
      @git_pivot.send(*args)
    end
  end
end
