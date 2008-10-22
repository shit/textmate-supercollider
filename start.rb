#!/usr/bin/env ruby

# Adapted from scvim by Alex Norman

#SCvim pipe
#this is a script to pass things from scvim to sclang
#
#Copyright 2007 Alex Norman
#
#This file is part of SCVIM.
#
#SCVIM is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#SCVIM is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with SCVIM.  If not, see <http://www.gnu.org/licenses/>.

require 'fileutils'
require 'open3'

# edit to suit
pipe_loc = "~/sclang/scpipe" unless (pipe_loc = ENV["SCVIM_PIPE_LOC"])
rundir = "~/sclang" unless (rundir = ENV["SCLANG_RUNDIR"])
pid_loc = "/tmp/sclangpipe_app-pid" unless (pid_loc = ENV["SCVIM_PIPE_PID_LOC"])
app = `which sclang`.chomp

sclangargs = ""

File.open(pid_loc, "w"){ |f|
  f.puts Process.pid
}

#remove the pipe if it exists
if File.exists?(pipe_loc)
  FileUtils.rm(pipe_loc)
end
#make a new pipe
system("mkfifo", pipe_loc)

pipeproc = Proc.new {
  trap("INT") do
    Process.exit
  end
  IO.popen("#{app} -d #{rundir.chomp} #{sclangargs}", "w") do |sclang|
    loop {
      x = `cat #{pipe_loc}`
      sclang.print x if x
    }
  end
}

$p = Process.fork { pipeproc.call }

#if we get a hup then we kill the pipe process and
#restart it
trap("HUP") do
  Process.kill("INT", $p)
  $p = Process.fork { pipeproc.call }
end

#clean up after us
trap("INT") do
  FileUtils.rm(pipe_loc)
  FileUtils.rm(pid_loc)
  exit
end

#we sleep until a signal comes
sleep(1) until false
