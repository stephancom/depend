#!/usr/bin/env ruby

class Depend
	COMMANDS = {
		'DEPEND' => :depend,
		'INSTALL' => :install,
		'REMOVE' => :remove,
		'LIST' => :list,
		'END' => :end
	}

	# cute idea, didn't work out
	# COMMAND_REGEX = /\A(((?<command>INSTALL)\s+(?<parameters>\S+)\s*)|((?<command>REMOVE)\s+(?<parameters>\S+)\s*)|((?<command>LIST)(?<parameters>\s*))|((?<command>DEPEND)(?<parameters>(\s*\S+)+)\s*))\z/
	COMMAND_REGEX = /\A\s?(?<command>(DEPEND|INSTALL|REMOVE|LIST|END))\s?(?<parameters>.*)\s?\z/
	def initialize
		@installed = []				# ALL installed packages
		@explicitly_installed = []	# EXPLICITLY installed packages
		@dependencies = {}			# hash whose keys are packages and values are an array containing the packages depended on by that package
	end
	
	def depend(dependencies)
		packages = dependencies.strip.split
		parent = packages.shift
		puts "DEPEND #{parent} #{packages.join(' ')}"
		@dependencies[parent] = packages
	end

	def install(package, as_dependency=false)
		puts "INSTALL #{package}" unless as_dependency
		if @installed.include? package
			puts "  #{package} is already installed." unless as_dependency
		else
			@dependencies[package].each { |p| install(p, true) } if @dependencies.has_key? package
			puts "  Installing #{package}"
			@installed << package 
			@explicitly_installed << package unless as_dependency
		end
	end

	def remove(package, dependency = false)
		return if dependency and @explicitly_installed.include? package
		puts "REMOVE #{package}" unless dependency
		unless @installed.include? package
			puts "  #{package} is not installed."
			return
		end
		# collect all the packages that have dependencies, excluding the current package's dependencies
		depended_on = @dependencies.select{ |dp| dp != package }.values.flatten.uniq
		if depended_on.include? package
			puts "  #{package} is still needed." unless dependency
		else
			puts "  Removing #{package}"
			did_depend_on = @dependencies[package]
			@dependencies.delete package
			did_depend_on.each { |dp| remove(dp, true) } if did_depend_on
			@installed.delete package
		end
	end

	def list(ignored = '')
		puts 'LIST'
		@installed.sort.each do |package|
			puts '  ' + package
		end
	end

	def end(ignored = '')
		puts 'END'
	end

	def parse(commands)
		commands.each_line do |line|
			next unless parsed = COMMAND_REGEX.match(line)
			self.send(COMMANDS[parsed[:command]], parsed[:parameters])
			return if parsed[:command] == :end
		end
	end
end

test_input = <<eos
DEPEND   ALFA BRAVO CHARLIE
DEPEND BRAVO CHARLIE
DEPEND DELTA BRAVO CHARLIE
DEPEND  ECHO   BRAVO  FOXTROT
INSTALL CHARLIE
INSTALL ALFA
INSTALL GOLF
REMOVE CHARLIE
INSTALL ECHO
INSTALL DELTA
LIST
REMOVE ALFA
REMOVE CHARLIE
REMOVE DELTA
REMOVE CHARLIE
INSTALL CHARLIE
REMOVE BRAVO
REMOVE ECHO
REMOVE BRAVO
LIST
END
eos

d = Depend.new

d.parse(test_input)
