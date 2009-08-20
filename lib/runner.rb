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

require 'optparse'
require 'date'

module GitPivot
  class Runner
    def initialize(args)
      @argv = args
      process_args
      # configuration stuff
      configuration = YAML.load_file("git_pivot.yml")

      @git_pivot = GitPivot.new(configuration["project_id"], configuration["token"])
    end

    def run
      if @arg1
        @git_pivot.send(@command, @arg1)
      else
        @git_pivot.send(@command)
      end
    end

    private
    def process_args
      @command = @argv.shift
      @arg1 = @argv.shift
    end
  end
end
