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
	P_TERMINATED = 0x01	# Internal process status (within Sim).
	P_SEQUENTIAL = 0x02
	P_QUEUEING = 0x04
	INIT_TIME = 0

	# Internal Sim class used to describe a Process.
	class PDescr
		attr_accessor :process, :status, :total_action_time, :available_at

		def initialize(process = nil,status = P_TERMINATED)
			@process = process
			@status = status
			@total_action_time = INIT_TIME
			@available_at = INIT_TIME
		end
	end

	# Internal Sim class used to describe an action for a Process.
	class Action
		attr_accessor :type,:pid,:event

		def initialize(type,pid,event = nil)
			@type = type
			@pid = pid
			@event = event
		end

		def assign(action)
			@type = action.type;
			@pid = action.pid;
			@event = action.event;
		end
	end

	# A generic discrete-event sequential simulator.
	# This class implements a generic discrete-event sequential
	# simulator. Sim maintains and executes a time-ordered schedule of
	# actions (or discrete events).
	class Sim
		A_Event = 0
		A_Timeout = 1
		A_Init = 2
		A_Stop = 3

		@@m_current_time = INIT_TIME	# Virtual time in the simulated world.
		@@m_current_process = Process::NULL_PROCESSID	# Currently running process.
		@@m_current_delay = INIT_TIME	# Duration of the current action.
		@@m_running = false				# Is simulation running?
		@@m_actions = {}
		@@m_processes = {}
		@@m_lock = false
		
		# Creates a new process with the given Process object.
		# <code>mode</code> specifies the execution flags of the
		# process. If the <code>P_SEQUENTIAL</code> flag is set, then
		# the process will process one event at a time with respect to
		# the simulation virtual time, otherwise (default) the actions
		# of this process will be considered reentrant and may be
		# executed in parallel.  By default, the simulator discards the
		# events signalled to a <code>P_SEQUENTIAL</code> process while
		# that process is busy executing other actions.  The
		# <code>P_QUEUEING</code> flag can be set to instruct the
		# simulator to queue those events.  In this case, the simulator
		# will deliver signals to that process as the process is
		# available to respond to them.
		def Sim.create_process(process,mode = 0)
			newpid = @@m_processes.size
			@@m_processes[newpid] = PDescr.new(process,mode & (P_SEQUENTIAL | P_QUEUEING))
			schedule_now(Action.new(A_Init,newpid))
			newpid
		end
		
		# Stops the execution of a given process.
		def Sim.stop_process(pid = @@m_current_process)
			pd = @@m_processes[pid]
			return -1 if pd.status & P_TERMINATED > 0
			schedule_now(Action.new(A_Stop,pid))
			0
		end
		
		# Clears out internal data structures.
		# Resets the simulator making it available for a completely new
		# simulation.  All scheduled actions are deleted together with
		# the associated events.  All process identifiers returned by
		# previoius invocations of \link create_process(Process*,char)
		# create_process\endlink are invalidated by this operation.
		# Notice however that it is the responsibility of the simulation
		# programmer to delete process objects used in the simulation.
		def Sim.clear
			@@m_running = false
			@@m_current_time = INIT_TIME
			@@m_current_delay = INIT_TIME
			@@m_processes.clear
			@@m_actions.clear
		end
		
		# Signal an event to the given process.
		# Signal an event to the given process.  The response is
		# scheduled for the current time.
		# @see Process#process_event(Event) Process.process_event(Event)
		def Sim.signal_event(event,pid,delay = 0)
			pd = @@m_processes[pid]
			return -1 if pd.status & P_TERMINATED > 0
			schedule(Action.new(A_Event,pid,event),delay)
			0
		end
		
		# Sets a timeout for the current process.
		# Schedules the execution of process_timeout() on the current
		# process after the given amount of (virtual) time.
		def Sim.set_timeout(time)
			schedule(Action.new(A_Timeout,@@m_current_process),time)
		end

		# Advance the execution time of the current process.
		# This method can be used to specify the duration of certain
		# actions, or certain steps within the same action.
		def Sim.advance_delay(delay)
			return unless @@m_running
			pd = @@m_processes[@@m_current_process]
			pd.total_action_time += delay
			@@m_current_delay += delay
		end

		# Returns the current process.
		def Sim.this_process
			@@m_current_process
		end
		
		# Returns the current virtual time for the current process.
		def Sim.clock
			@@m_current_time + @@m_current_delay
		end
		
		# Starts execution of the simulation.
		def Sim.run_simulation
			# Prevents anyone from re-entering the main loop.  Note that this
			# isn't meant to be thread-safe, it works if some process calls
			# Sim::run_simulation() within their process_event() or
			# process_timeout() function.
			return if @@m_lock

			@@m_lock = true
			@@m_running = true

			# While there is at least a scheduled action...
			while (@@m_running && !@@m_actions.empty?) do
				# I'm purposely excluding any kind of checks in this version
				# of the simulator.
				# I should say something like this:
				# assert(current_time <= (*a).first);
				key = @@m_actions.keys.sort.first
				@@m_current_time = key
				actions = @@m_actions[key]
				action = actions.delete_at(0)
				@@m_actions.delete(key) if actions.empty?
				@@m_current_process = action.pid
				@@m_current_delay = 0

				# Right now I don't check if current_process is indeed a
				# valid process.  Keep in mind that this is the heart of the
				# simulator main loop, therefore efficiency is crucial.
				# Perhaps I should check.  This is somehow a design choice.
				pd = @@m_processes[@@m_current_process]
	    
				if ((pd.status & P_TERMINATED) > 0) then
					# ...work in progress...
					action.event = nil
				elsif ((pd.status & P_SEQUENTIAL) > 0 && @@m_current_time < pd.available_at) then
					# This process is sequential and is currently executing
					# another action (in virtual time of course), so we
					# reschedule this action to the time the process is
					# available.
					schedule(action,pd.available_at) if ((pd.status & P_QUEUEING) > 0)
					# If the process can not queue actions, this action is simply dropped.
				else
					case action.type
						when A_Event
							pd.process.process_event(action.event)
						when A_Timeout
							pd.process.process_timeout
						when A_Init
							pd.process.init
						when A_Stop
							pd.process.stop
							pd.status |= P_TERMINATED
						else
							# Add paranoia checks/logging here?
					end
					pd.available_at = clock if ((pd.status & P_SEQUENTIAL) > 0)
				end
			end
			@@m_lock = false
		end

		# Stops execution of the simulation.
		def Sim.stop_simulation
			@@m_running = false
		end

		def Sim.schedule(action,time)
			(@@m_actions[clock + time] ||= []) << action
		end

		def Sim.schedule_now(action)
			schedule(action,@@m_current_time)
		end
	end
end
