#!/usr/bin/ruby
require 'io/console'
require 'colorize'
require 'curses'
include Curses

init_screen
start_color
init_pair(COLOR_GREEN,COLOR_GREEN,COLOR_BLACK)
init_pair(COLOR_BLUE,COLOR_BLUE,COLOR_BLACK)

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

def draw_cursor(draw)
  attron(color_pair(COLOR_BLUE)|A_BOLD) {
    addstr("#{ draw ? '> ' : '  ' }")
  }
end

def draw_branches(selected)
  setpos(0, 0)
  addstr("Pick a branch\n")

  branches = GIT_BRANCH.each_with_index.map do |branch, i|
    draw_cursor(i == selected)

    branch_name = branch.gsub('  ', '')
    if branch_name.include?('* ')
      branch_name = branch_name.gsub('* ', '')
      attron(color_pair(COLOR_GREEN)) {
        addstr("#{branch_name}\n")
      }
    else
      addstr("#{branch_name}\n")
    end

    branch_name
  end

  addstr("Use j/k and enter to select\n")
  refresh
  branches
end

selected = 0
branches = draw_branches(selected)

loop do
  c = read_char

  case c.downcase
  when "\r"
    close_screen
    `git checkout #{branches[selected]}`
    exit 0
  when "\e[A", 'k'
    selected -= 1 unless selected == 0
  when "\e[B", 'j'
    selected += 1 unless selected == branches.size - 1
  when "\e", "\u0003", 'q'
    close_screen
    exit 0
  else
    puts c.inspect
  end

  draw_branches(selected)
end
