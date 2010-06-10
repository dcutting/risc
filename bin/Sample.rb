#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__),"../lib")

require 'Risc'

class Counter < Risc::Event
	attr_accessor :counter,:sender
	
	def initialize(counter,sender)
		@counter = counter
		@sender = sender
	end
end

class Node
	# Mixin the Process interface so we can handle events and timeouts.
	include Risc::Process
	
	def init
		# If we're the first node, create a new Counter and send it to the other node.
		if (Risc::Sim::this_process == 0) then
			event = Counter.new(0,Risc::Sim::this_process)
			puts "Process #{Risc::Sim::this_process} creating the counter and sending it to process 1."
			Risc::Sim::signal_event(event,1,1000)
		end
		
		# Also set a timeout to fire some time in the future.
		Risc::Sim::set_timeout((Kernel.rand*10000).ceil)
	end
	
	def stop
		puts "#{Risc::Sim::clock}: process #{Risc::Sim::this_process} stopping."
	end
	
	def process_event(event)
		puts "#{Risc::Sim::clock}: process #{Risc::Sim::this_process} caught the counter: value is #{event.counter}."
		sender = event.sender
		event.counter += 1
		event.sender = Risc::Sim::this_process
		if (event.counter < 10) then
			puts "#{Risc::Sim::clock}: process #{Risc::Sim::this_process} incrementing and bouncing the counter back..."
			Risc::Sim::signal_event(event,sender,1000)
		end
	end
	
	def process_timeout
		puts "#{Risc::Sim::clock}: process #{Risc::Sim::this_process} caught a timeout - killing myself."
		Risc::Sim::stop_process
	end
end

puts "Starting sample simulation..."

# Create the processes for the sample. These will bounce a message
# back and forth until the counter within reaches 10.
Risc::Sim::create_process(Node.new)
Risc::Sim::create_process(Node.new)

# Enter the simulation loop - this will only terminate once the event queue has emptied.
Risc::Sim::run_simulation

puts "Complete."
