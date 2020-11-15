#!ruby
# frozen_string_literal: true

require 'optparse'
require 'logger'

$LOAD_PATH.unshift 'lib'
require 'fs/rmk2/node'

LOGGER = Logger.new(STDERR, datetime_format: '')

@script = File.basename($0)
@rcfile = ".#{@script}"

@mnt_point = File.join(ENV['HOME'], 'mnt', 'remarkable')

begin
  binding.eval(File.read(@rcfile), @rcfile)
rescue Errno::ENOENT => e
end

OptParse.new do |opts|
  opts.banner = <<EOF
Usage: #{@script} [options] <cmd> [args]

Basic file utils for Remarkable 2

EOF

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end

  opts.on('-m', '--mountpoint STRING', 'Remarkable2 rootfs mount point') do |m|
    @mnt_point = m
  end
end.parse!

action = ARGV.shift || 'ls'

def mnt_point
  @mnt_point
end

FS::Rmk2::Node.init(mnt_point, logger: LOGGER)

public

def ls_r
  FS::Rmk2::Node.all.reject(&:trash?)
end

def ls(fld = '/')
  path = fld.split('/').reject(&:empty?)
  res = ls_r.select(&:top?)
  while(!path.empty?)
    cur = path.shift
    rr = res.to_a
    return [] unless i = rr.index{|x| x.name == cur}
    res = rr[i]
  end
  [*res]
end

public_send(action, *ARGV).each {|x| puts x}

