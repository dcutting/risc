# This file is part of Risc, a lightweight discrete-event simulator for Ruby.
# Risc is based on SSim, a simple discrete-event simulator used
# with the Siena project. See <http://www.cs.colorado.edu/serl/siena>
#
# Author: Dan Cutting <dcutting@soyabean.com.au>
# Based on SSim/JSSim by: Antonio Carzaniga <carzanig@cs.colorado.edu> and
# Matthew J. Rutherford <rutherfo@cs.colorado.edu>
# See the file AUTHORS for full details.
#
# Copyright (C) 2005 Soyabean Software Pty Ltd <http://www.soyabean.com.au>
#
# Risc is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Risc is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Risc; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# $Id$

module Risc
	# Utility Process class providing a utility interface with the simulator.
	# This is a sligtly more advanced Process class that provides
	# automatic management of the process identifier.
	class ProcessWithPid
		include Process
		
		attr_reader :pid	# Process id of this process.

		def initialize
			@pid = NULL_PROCESSID
		end
		
		# Activates this process within the simulator.
		# Creates a simulator process with this process object. The
		# same ProcessWithPId can be activated only once.
		# Returns the ProcessId of the created simulator process or
		# NULL_PROCESSID if this process object is already associated
		# with a simulation process.
		# See Sim#create_process and Sim#create_process.
		def activate(mode = 0)
			if (@pid == NULL_PROCESSID) then
				return @pid = Sim::create_process(self,mode)
			else
				return NULL_PROCESSID
			end
		end
	end
end
