#!/usr/bin/ruby
require 'io/console'
require 'colorize'

GIT_BRANCH = `git branch`.split("\n")
exit 0 if GIT_BRANCH.size == 0

def read_char
  STDIN.echo = false
  STDIN.raw!

  input = STDIN.getc.chr
  if input == "\e" then
    input << STDIN.read_nonblock(3) rescue nil
    input << STDIN.read_nonblock(2) rescue nil
  end
ensure
  STDIN.echo = true
  STDIN.cooked!

  return input
end

def draw_branches(selected)
  puts 'Pick a Branch:'
  GIT_BRANCH.each_with_index.map do |branch, i|
    branch_name = branch.gsub('  ', '')
    if branch_name.include?('* ')
      branch_name = branch_name.gsub('* ', '')
      puts "#{ i == selected ? '> ' : '  ' } #{branch_name}".green
    else
      puts "#{ i == selected ? '> '.green : '  ' } #{branch_name}"
    end

    branch_name
  end
end

system 'clear'
selected = 0
branches = draw_branches(selected)

loop do
  c = read_char

  case c
  when "\r"
    `git checkout #{branches[selected]}`
    exit 0
  when "\e[A", 'k'
    selected -= 1 unless selected == 0
  when "\e[B", 'j'
    selected += 1 unless selected == branches.size - 1
  when "\e", "\u0003", 'q'
    puts 'Okay never mind.'
    exit 0
  else
    puts c.inspect
  end

  system 'clear'
  draw_branches(selected)
end
