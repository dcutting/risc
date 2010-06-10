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
	# Mixin representing processes running within the simulator.
	# A simulated process should override this interface as necessary.
	module Process
		NULL_PROCESSID = 0
		
		# Action when the process is created. This execution step is scheduled
		# when the process is created through Sim#create_process. This action
		# is executed before any event or timeout.
		def init
		end
		
		# Action executed in response to an event signaled to this process.
		# Notice that the signaled event should not be used outside this
		# method, other than by signaling it to a process through
		# Sim#signal_event. The implementation of this method may specify
		# the duration of the actions associated with this response using
		# the Sim#advance_delay method. By default, the duration of an
		# action is 0.
		def process_event(event)
		end
		
		# Action executed in response to a timeout.
		# This method defines the actions explicitly scheduled for this
		# process by the process itself.  These actions are scheduled by
		# calling Sim#set_timeout. The implementation of this method may
		# specify the duration of the actions associated with this
		# response using the Sim#advance_delay method. By default,
		# the duration of an action is 0.
		def process_timeout
		end

		# Executed when the process is explicitly stopped. A process is
		# stopped by a call to Sim#stop_process. This method is executed
		# immediately after the process has processed all the events or
		# timeouts scheduled before the call to Sim#stop_process.
		def stop
		end
	end
end
